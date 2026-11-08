<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Models\DetailPesanan;
use App\Models\Pesanan;
use App\Models\Produk;
use App\Support\ResponsApi;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class PesananController extends Controller
{
    private const TRANSISI = [
        'menunggu_pembayaran' => ['menunggu_konfirmasi', 'dibatalkan'],
        'menunggu_konfirmasi' => ['dibayar', 'dibatalkan'],
        'dibayar' => ['diproses'],
        'diproses' => ['dikirim'],
        'dikirim' => ['selesai'],
        'selesai' => [],
        'dibatalkan' => [],
    ];

    public function index(Request $request): JsonResponse
    {
        $pesanan = Pesanan::query()
            ->with(['kurir', 'metodePembayaran'])
            ->where('pelanggan_id', $this->pelangganId($request))
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->get()
            ->map(fn (Pesanan $item): array => $this->representasi($item));

        return ResponsApi::sukses($pesanan, 'Riwayat pesanan berhasil diambil');
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $pesanan = Pesanan::query()
            ->with(['kurir', 'metodePembayaran', 'detail'])
            ->where('pelanggan_id', $this->pelangganId($request))
            ->whereKey($id)
            ->first();

        if ($pesanan === null) {
            return ResponsApi::gagal('Pesanan tidak ditemukan.', 404);
        }

        return ResponsApi::sukses($this->representasi($pesanan, true), 'Rincian pesanan berhasil diambil');
    }

    public function ubahStatus(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'status' => ['required', 'string', Rule::in(array_keys(self::TRANSISI))],
        ]);

        $pesanan = DB::transaction(function () use ($request, $id, $data): Pesanan {
            $pesanan = Pesanan::query()
                ->where('pelanggan_id', $this->pelangganId($request))
                ->whereKey($id)
                ->lockForUpdate()
                ->first();

            if ($pesanan === null) {
                throw new ApiException('Pesanan tidak ditemukan.', 404);
            }

            if (! in_array($data['status'], self::TRANSISI[$pesanan->status] ?? [], true)) {
                throw new ApiException('Perubahan status pesanan tidak diizinkan.', 409, [
                    'status_sekarang' => $pesanan->status,
                    'status_diminta' => $data['status'],
                ]);
            }

            if ($data['status'] === 'dibatalkan') {
                $detail = DetailPesanan::query()
                    ->where('pesanan_id', $pesanan->id)
                    ->orderBy('produk_id')
                    ->lockForUpdate()
                    ->get();

                foreach ($detail->groupBy('produk_id') as $produkId => $items) {
                    $produk = Produk::query()
                        ->whereKey($produkId)
                        ->lockForUpdate()
                        ->first();

                    if ($produk !== null) {
                        $produk->increment('stok', (int) $items->sum('jumlah'));
                    }
                }
            }

            $pesanan->update(['status' => $data['status']]);

            return $pesanan->load(['kurir', 'metodePembayaran', 'detail']);
        });

        return ResponsApi::sukses($this->representasi($pesanan, true), 'Status pesanan berhasil diperbarui');
    }

    /**
     * @return array<string, mixed>
     */
    private function representasi(Pesanan $pesanan, bool $denganDetail = false): array
    {
        $data = [
            'id' => $pesanan->id,
            'nomor_pesanan' => $pesanan->nomor_pesanan,
            'pelanggan_id' => $pesanan->pelanggan_id,
            'kurir_id' => $pesanan->kurir_id,
            'metode_pembayaran_id' => $pesanan->metode_pembayaran_id,
            'nama_penerima' => $pesanan->nama_penerima,
            'alamat_penerima' => $pesanan->alamat_penerima,
            'subtotal' => $pesanan->subtotal,
            'ongkos_kirim' => $pesanan->ongkos_kirim,
            'total' => $pesanan->total,
            'status' => $pesanan->status,
            'metode_pembayaran' => [
                'kode' => $pesanan->metodePembayaran?->kode,
                'nama' => $pesanan->metodePembayaran?->nama,
            ],
            'kurir' => [
                'id' => $pesanan->kurir?->id,
                'nama' => $pesanan->kurir?->nama,
                'wilayah' => $pesanan->kurir?->wilayah,
            ],
            'created_at' => $pesanan->created_at?->toIso8601String(),
        ];

        if ($denganDetail) {
            $data['items'] = $pesanan->detail->map(fn (DetailPesanan $item): array => [
                'id' => $item->id,
                'produk_id' => $item->produk_id,
                'nama_produk' => $item->nama_produk,
                'varian_nama' => $item->varian_nama,
                'harga_dasar' => $item->harga_dasar,
                'tambahan_harga' => $item->tambahan_harga,
                'harga_satuan' => $item->harga_satuan,
                'jumlah' => $item->jumlah,
                'subtotal' => $item->subtotal,
                'tingkat_pedas' => $item->tingkat_pedas,
                'catatan' => $item->catatan,
            ])->values();
        }

        return $data;
    }
}
