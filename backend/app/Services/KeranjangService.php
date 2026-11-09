<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Keranjang;
use App\Models\Kurir;
use App\Models\Produk;
use Illuminate\Support\Collection;

class KeranjangService
{
    /**
     * @return array{items: array<int, array<string, mixed>>, jumlah_item: int, ringkasan: array{subtotal: int, ongkos_kirim: int|null, total: int|null}}
     */
    public function ambil(int $pelangganId, ?int $kurirId = null): array
    {
        $items = $this->itemKeranjang($pelangganId);
        $subtotal = (int) $items->sum('subtotal');
        $ongkosKirim = null;
        $total = null;

        if ($kurirId !== null) {
            $kurir = Kurir::query()
                ->whereKey($kurirId)
                ->where('aktif', true)
                ->first();

            if ($kurir === null) {
                throw new ApiException('Kurir tidak ditemukan atau sedang tidak aktif.', 422, null, [
                    'kurir_id' => ['Kurir tidak ditemukan atau sedang tidak aktif.'],
                ]);
            }

            $ongkosKirim = $kurir->tarif;
            $total = $subtotal + $ongkosKirim;
        }

        return [
            'items' => $items->values()->all(),
            'jumlah_item' => (int) $items->sum('jumlah'),
            'ringkasan' => [
                'subtotal' => $subtotal,
                'ongkos_kirim' => $ongkosKirim,
                'total' => $total,
            ],
        ];
    }

    /**
     * @param  array{produk_id: int, jumlah: int, varian_id?: int|null, tingkat_pedas?: string|null, catatan?: string|null}  $data
     * @return array<string, mixed>
     */
    public function tambah(int $pelangganId, array $data): array
    {
        $produk = Produk::query()->find((int) $data['produk_id']);

        if ($produk === null) {
            throw new ApiException('Produk tidak ditemukan.', 422, null, [
                'produk_id' => ['Produk tidak ditemukan.'],
            ]);
        }

        $this->pastikanProdukTersedia($produk);

        $varianId = $data['varian_id'] ?? null;
        $tingkatPedas = $data['tingkat_pedas'] ?? null;
        $catatan = $data['catatan'] ?? null;

        $jumlahDiKeranjang = (int) Keranjang::query()
            ->where('pelanggan_id', $pelangganId)
            ->where('produk_id', $produk->id)
            ->sum('jumlah');

        $diminta = $jumlahDiKeranjang + (int) $data['jumlah'];

        if ($diminta > $produk->stok) {
            $this->lemparStokKurang($produk, $diminta);
        }

        // D-07: gabung baris bila kombinasi produk, varian, tingkat pedas, dan catatan identik.
        $item = Keranjang::query()
            ->where('pelanggan_id', $pelangganId)
            ->where('produk_id', $produk->id)
            ->where('varian_id', $varianId)
            ->where('tingkat_pedas', $tingkatPedas)
            ->where('catatan', $catatan)
            ->first();

        $jumlahBaru = ($item?->jumlah ?? 0) + (int) $data['jumlah'];

        if ($jumlahBaru > 65535) {
            throw new ApiException('Jumlah item pada satu baris keranjang melebihi batas.', 409, [
                'alasan' => 'batas_jumlah_item',
                'maksimum' => 65535,
            ]);
        }

        if ($item === null) {
            $item = Keranjang::query()->create([
                'pelanggan_id' => $pelangganId,
                'produk_id' => $produk->id,
                'varian_id' => $varianId,
                'jumlah' => (int) $data['jumlah'],
                'tingkat_pedas' => $tingkatPedas,
                'catatan' => $catatan,
            ]);
        } else {
            $item->update(['jumlah' => $jumlahBaru]);
        }

        $item->load(['produk', 'varian']);

        return $this->payloadItem($item);
    }

    /**
     * @return array<string, mixed>
     */
    public function ubah(int $pelangganId, int $id, int $jumlah): array
    {
        $item = Keranjang::query()
            ->with(['produk', 'varian'])
            ->where('pelanggan_id', $pelangganId)
            ->whereKey($id)
            ->first();

        if ($item === null) {
            throw new ApiException('Item keranjang tidak ditemukan.', 404);
        }

        $produk = $item->produk;

        if ($produk === null) {
            throw new ApiException('Produk pada keranjang sudah tidak tersedia.', 409, [
                'alasan' => 'produk_tidak_tersedia',
                'produk_id' => $item->produk_id,
            ]);
        }

        $this->pastikanProdukTersedia($produk);

        $jumlahLain = (int) Keranjang::query()
            ->where('pelanggan_id', $pelangganId)
            ->where('produk_id', $produk->id)
            ->whereKeyNot($id)
            ->sum('jumlah');

        $diminta = $jumlahLain + $jumlah;

        if ($diminta > $produk->stok) {
            $this->lemparStokKurang($produk, $diminta);
        }

        $item->update(['jumlah' => $jumlah]);
        $item->load(['produk', 'varian']);

        return $this->payloadItem($item);
    }

    public function hapus(int $pelangganId, int $id): void
    {
        $item = Keranjang::query()
            ->where('pelanggan_id', $pelangganId)
            ->whereKey($id)
            ->first();

        if ($item === null) {
            throw new ApiException('Item keranjang tidak ditemukan.', 404);
        }

        $item->delete();
    }

    /**
     * @return Collection<int, array<string, mixed>>
     */
    private function itemKeranjang(int $pelangganId): Collection
    {
        return Keranjang::query()
            ->with(['produk', 'varian'])
            ->where('pelanggan_id', $pelangganId)
            ->orderBy('id')
            ->get()
            ->map(fn (Keranjang $item): array => $this->payloadItem($item));
    }

    /**
     * @return array<string, mixed>
     */
    private function payloadItem(Keranjang $item): array
    {
        $produk = $item->produk;
        $varian = $item->varian;
        $hargaDasar = $produk?->harga ?? 0;
        $tambahanHarga = $varian?->tambahan_harga ?? 0;
        $hargaSatuan = $hargaDasar + $tambahanHarga;

        return [
            'id' => $item->id,
            'produk_id' => $item->produk_id,
            'nama' => $produk?->nama ?? 'Produk tidak tersedia',
            'varian' => $varian === null ? null : [
                'id' => $varian->id,
                'nama' => $varian->nama,
                'tambahan_harga' => $varian->tambahan_harga,
            ],
            'tingkat_pedas' => $item->tingkat_pedas,
            'catatan' => $item->catatan,
            'harga_satuan' => $hargaSatuan,
            'jumlah' => $item->jumlah,
            'subtotal' => $hargaSatuan * $item->jumlah,
        ];
    }

    private function pastikanProdukTersedia(Produk $produk): void
    {
        if (! $produk->tersedia) {
            throw new ApiException(
                "Produk {$produk->nama} sedang tidak tersedia.",
                409,
                [
                    'alasan' => 'produk_tidak_tersedia',
                    'produk_id' => $produk->id,
                    'nama' => $produk->nama,
                ],
            );
        }
    }

    private function lemparStokKurang(Produk $produk, int $diminta): never
    {
        throw new ApiException(
            'Stok tidak mencukupi untuk 1 item',
            409,
            [
                'alasan' => 'stok_kurang',
                'item_kurang' => [[
                    'produk_id' => $produk->id,
                    'nama' => $produk->nama,
                    'diminta' => $diminta,
                    'tersedia' => $produk->stok,
                ]],
            ],
        );
    }
}
