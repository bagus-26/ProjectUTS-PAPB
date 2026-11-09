<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\DetailPesanan;
use App\Models\Pesanan;
use App\Models\Produk;
use App\Support\StatusPesanan;
use Illuminate\Support\Facades\DB;

class PesananService
{
    /**
     * Mengubah status pesanan dengan state machine yang sama untuk API dan admin.
     *
     * @throws ApiException
     */
    public function ubahStatus(int $pesananId, string $statusBaru, ?int $pelangganId = null): Pesanan
    {
        return DB::transaction(function () use ($pesananId, $statusBaru, $pelangganId): Pesanan {
            $query = Pesanan::query()->whereKey($pesananId);

            if ($pelangganId !== null) {
                $query->where('pelanggan_id', $pelangganId);
            }

            $pesanan = $query->lockForUpdate()->first();

            if ($pesanan === null) {
                throw new ApiException('Pesanan tidak ditemukan.', 404);
            }

            if (! StatusPesanan::boleh($pesanan->status, $statusBaru)) {
                throw new ApiException('Perubahan status pesanan tidak diizinkan.', 409, [
                    'status_sekarang' => $pesanan->status,
                    'status_diminta' => $statusBaru,
                ]);
            }

            if ($statusBaru === StatusPesanan::DIBATALKAN) {
                $this->kembalikanStok($pesanan);
            }

            $pesanan->update(['status' => $statusBaru]);

            return $pesanan->load(['pelanggan', 'kurir', 'metodePembayaran', 'detail']);
        });
    }

    private function kembalikanStok(Pesanan $pesanan): void
    {
        $detail = DetailPesanan::query()
            ->where('pesanan_id', $pesanan->id)
            ->orderBy('produk_id')
            ->lockForUpdate()
            ->get();

        foreach ($detail->groupBy('produk_id') as $produkId => $items) {
            $produk = Produk::query()
                ->withTrashed()
                ->whereKey($produkId)
                ->lockForUpdate()
                ->first();

            if ($produk !== null) {
                $produk->increment('stok', (int) $items->sum('jumlah'));
            }
        }
    }
}
