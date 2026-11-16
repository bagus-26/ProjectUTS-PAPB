<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\DetailPesanan;
use App\Models\Notifikasi;
use App\Models\Pelanggan;
use App\Models\Pesanan;
use App\Models\Produk;
use App\Models\UserVoucher;
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
        $pesanan = DB::transaction(function () use ($pesananId, $statusBaru, $pelangganId): Pesanan {
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

            if ($statusBaru === StatusPesanan::SELESAI) {
                $this->selesaikanReward($pesanan);
            }

            return $pesanan->load(['pelanggan', 'kurir', 'metodePembayaran', 'detail', 'voucher.promo']);
        });

        if ($pesanan->status === StatusPesanan::DIBATALKAN) {
            // Diselesaikan lewat container karena PembayaranService membutuhkan
            // PesananService; injeksi konstruktor akan membuat dependensi melingkar.
            app(PembayaranService::class)->batalkanInvoice($pesanan);
        }

        return $pesanan;
    }

    /**
     * Memberikan poin reward dan menandai voucher pesanan sebagai terpakai.
     * Dijalankan sekali saat status berubah menjadi selesai.
     */
    private function selesaikanReward(Pesanan $pesanan): void
    {
        if ($pesanan->poin_diberikan > 0) {
            return;
        }

        $poin = intdiv((int) $pesanan->total, 10000) * 100;

        if ($poin > 0) {
            $pelanggan = Pelanggan::query()
                ->whereKey($pesanan->pelanggan_id)
                ->lockForUpdate()
                ->first();

            if ($pelanggan !== null) {
                $pelanggan->increment('poin', $poin);

                Notifikasi::query()->create([
                    'user_id' => $pelanggan->id,
                    'judul' => 'Poin reward bertambah',
                    'pesan' => sprintf(
                        'Pesanan %s selesai. Kamu mendapat %d poin reward.',
                        $pesanan->nomor_pesanan,
                        $poin,
                    ),
                    'tipe' => 'poin',
                ]);
            }

            $pesanan->forceFill(['poin_diberikan' => $poin])->save();
        }

        if ($pesanan->user_voucher_id !== null) {
            UserVoucher::query()
                ->whereKey($pesanan->user_voucher_id)
                ->where('status', 'active')
                ->update(['status' => 'used']);
        }
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
