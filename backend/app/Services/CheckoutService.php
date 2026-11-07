<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Keranjang;
use App\Models\Kurir;
use App\Models\MetodePembayaran;
use App\Models\Pelanggan;
use App\Models\Pesanan;
use App\Models\Produk;
use App\Models\VarianProduk;
use App\Support\JamOperasiToko;
use App\Support\NomorPesanan;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class CheckoutService
{
    public function __construct(
        private readonly JamOperasiToko $jamOperasiToko,
    ) {}

    /**
     * @param  array{nama_penerima: string, alamat_penerima: string, kurir_id: int, metode_pembayaran: string}  $data
     * @return array<string, mixed>
     */
    public function buat(int $pelangganId, array $data, string $kunciIdempoten): array
    {
        // D-10: jalur cepat idempotensi sebelum menyentuh transaksi.
        $pesananLama = $this->cariPesananIdempoten($pelangganId, $kunciIdempoten);

        if ($pesananLama !== null) {
            return $this->payloadPesanan($pesananLama);
        }

        $statusToko = $this->jamOperasiToko->status();

        if (! $statusToko['buka']) {
            throw new ApiException(
                $statusToko['pesan'],
                409,
                [
                    'alasan' => 'toko_tutup',
                    'jam_buka' => $statusToko['jam_buka'],
                    'jam_tutup' => $statusToko['jam_tutup'],
                ],
            );
        }

        // A2-07: ulangi transaksi hingga 3 kali bila terjadi deadlock.
        $pesanan = DB::transaction(function () use ($pelangganId, $data, $kunciIdempoten): Pesanan {
            // D-10: serialisasi checkout per pelanggan.
            Pelanggan::query()
                ->whereKey($pelangganId)
                ->lockForUpdate()
                ->first();

            $pesananLama = $this->cariPesananIdempoten($pelangganId, $kunciIdempoten);

            if ($pesananLama !== null) {
                return $pesananLama;
            }

            $items = Keranjang::query()
                ->where('pelanggan_id', $pelangganId)
                ->orderBy('id')
                ->lockForUpdate()
                ->get();

            if ($items->isEmpty()) {
                throw new ApiException('Keranjang masih kosong.', 409, [
                    'alasan' => 'keranjang_kosong',
                ]);
            }

            $produk = $this->kunciProduk($items);
            $varian = $this->ambilVarian($items);

            $this->pastikanStokCukup($items, $produk);
            $this->pastikanVarianValid($items, $produk, $varian);

            $kurir = Kurir::query()
                ->whereKey($data['kurir_id'])
                ->where('aktif', true)
                ->lockForUpdate()
                ->first();

            if ($kurir === null) {
                throw new ApiException('Kurir tidak ditemukan atau sedang tidak aktif.', 422, null, [
                    'kurir_id' => ['Kurir tidak ditemukan atau sedang tidak aktif.'],
                ]);
            }

            $metode = MetodePembayaran::query()
                ->where('kode', $data['metode_pembayaran'])
                ->where('aktif', true)
                ->lockForUpdate()
                ->first();

            if ($metode === null) {
                throw new ApiException('Metode pembayaran tidak ditemukan atau sedang tidak aktif.', 422, null, [
                    'metode_pembayaran' => ['Metode pembayaran tidak ditemukan atau sedang tidak aktif.'],
                ]);
            }

            $detail = [];
            $subtotal = 0;

            foreach ($items as $item) {
                $produkItem = $produk->get($item->produk_id);
                $varianItem = $item->varian_id === null ? null : $varian->get($item->varian_id);

                $hargaDasar = $produkItem->harga;
                $tambahanHarga = $varianItem?->tambahan_harga ?? 0;
                $hargaSatuan = $hargaDasar + $tambahanHarga;
                $subtotalItem = $hargaSatuan * $item->jumlah;
                $subtotal += $subtotalItem;

                // D-08: salin harga dan nama ke detail agar riwayat tidak berubah.
                $detail[] = [
                    'produk_id' => $produkItem->id,
                    'nama_produk' => $produkItem->nama,
                    'varian_nama' => $varianItem?->nama,
                    'harga_dasar' => $hargaDasar,
                    'tambahan_harga' => $tambahanHarga,
                    'harga_satuan' => $hargaSatuan,
                    'jumlah' => $item->jumlah,
                    'subtotal' => $subtotalItem,
                    'tingkat_pedas' => $item->tingkat_pedas,
                    'catatan' => $item->catatan,
                ];
            }

            $ongkosKirim = $kurir->tarif;

            $pesanan = Pesanan::query()->create([
                'nomor_pesanan' => NomorPesanan::berikutnya(),
                'pelanggan_id' => $pelangganId,
                'kurir_id' => $kurir->id,
                'metode_pembayaran_id' => $metode->id,
                'nama_penerima' => $data['nama_penerima'],
                'alamat_penerima' => $data['alamat_penerima'],
                'subtotal' => $subtotal,
                'ongkos_kirim' => $ongkosKirim,
                'total' => $subtotal + $ongkosKirim,
                'status' => 'menunggu_pembayaran',
                'kunci_idempoten' => $kunciIdempoten,
            ]);

            $pesanan->detail()->createMany($detail);

            foreach ($items->groupBy('produk_id') as $produkId => $itemsProduk) {
                $produkItem = $produk->get((int) $produkId);
                $produkItem->decrement('stok', (int) $itemsProduk->sum('jumlah'));
            }

            Keranjang::query()
                ->where('pelanggan_id', $pelangganId)
                ->delete();

            return $pesanan->load(['kurir', 'metodePembayaran']);
        }, 3);

        return $this->payloadPesanan($pesanan);
    }

    private function cariPesananIdempoten(int $pelangganId, string $kunciIdempoten): ?Pesanan
    {
        return Pesanan::query()
            ->with(['kurir', 'metodePembayaran'])
            ->where('pelanggan_id', $pelangganId)
            ->where('kunci_idempoten', $kunciIdempoten)
            ->first();
    }

    /**
     * @param  Collection<int, Keranjang>  $items
     * @return Collection<int, Produk>
     */
    private function kunciProduk(Collection $items): Collection
    {
        $ids = $items->pluck('produk_id')->unique()->sort()->values()->all();

        $produk = Produk::query()
            ->withTrashed()
            ->whereIn('id', $ids)
            ->orderBy('id')
            ->lockForUpdate()
            ->get()
            ->keyBy('id');

        foreach ($ids as $id) {
            $item = $produk->get($id);

            if ($item === null || $item->trashed() || ! $item->tersedia) {
                throw new ApiException('Produk pada keranjang sudah tidak tersedia.', 409, [
                    'alasan' => 'produk_tidak_tersedia',
                    'produk_id' => $id,
                    'nama' => $item?->nama,
                ]);
            }
        }

        return $produk;
    }

    /**
     * @param  Collection<int, Keranjang>  $items
     * @return Collection<int, VarianProduk>
     */
    private function ambilVarian(Collection $items): Collection
    {
        $ids = $items->pluck('varian_id')->filter()->unique()->values()->all();

        if ($ids === []) {
            return collect();
        }

        return VarianProduk::query()
            ->whereIn('id', $ids)
            ->lockForUpdate()
            ->get()
            ->keyBy('id');
    }

    /**
     * @param  Collection<int, Keranjang>  $items
     * @param  Collection<int, Produk>  $produk
     */
    private function pastikanStokCukup(Collection $items, Collection $produk): void
    {
        $kurang = [];

        foreach ($items->groupBy('produk_id') as $produkId => $itemsProduk) {
            $produkItem = $produk->get((int) $produkId);
            $diminta = (int) $itemsProduk->sum('jumlah');

            if ($diminta > $produkItem->stok) {
                $kurang[] = [
                    'produk_id' => $produkItem->id,
                    'nama' => $produkItem->nama,
                    'diminta' => $diminta,
                    'tersedia' => $produkItem->stok,
                ];
            }
        }

        if ($kurang !== []) {
            throw new ApiException(
                sprintf('Stok tidak mencukupi untuk %d item', count($kurang)),
                409,
                [
                    'alasan' => 'stok_kurang',
                    'item_kurang' => $kurang,
                ],
            );
        }
    }

    /**
     * @param  Collection<int, Keranjang>  $items
     * @param  Collection<int, Produk>  $produk
     * @param  Collection<int, VarianProduk>  $varian
     */
    private function pastikanVarianValid(Collection $items, Collection $produk, Collection $varian): void
    {
        foreach ($items as $item) {
            if ($item->varian_id === null) {
                continue;
            }

            $varianItem = $varian->get($item->varian_id);
            $produkItem = $produk->get($item->produk_id);

            if (
                $varianItem === null
                || ! $varianItem->aktif
                || (int) $varianItem->produk_id !== (int) $produkItem->id
            ) {
                throw new ApiException('Varian pada keranjang sudah tidak tersedia.', 409, [
                    'alasan' => 'varian_tidak_tersedia',
                    'varian_id' => $item->varian_id,
                ]);
            }
        }
    }

    /**
     * @return array<string, mixed>
     */
    private function payloadPesanan(Pesanan $pesanan): array
    {
        return [
            'id' => $pesanan->id,
            'nomor_pesanan' => $pesanan->nomor_pesanan,
            'status' => $pesanan->status,
            'subtotal' => $pesanan->subtotal,
            'ongkos_kirim' => $pesanan->ongkos_kirim,
            'total' => $pesanan->total,
            'metode_pembayaran' => $pesanan->metodePembayaran?->kode,
        ];
    }
}
