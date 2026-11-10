<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Keranjang;
use App\Models\Pesanan;
use App\Models\Produk;
use App\Support\StatusPesanan;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;

class ProdukService
{
    /**
     * @return Builder<Produk>
     */
    public function queryDaftar(?string $kategori = null, ?string $cari = null): Builder
    {
        return Produk::query()
            ->with(['varian' => fn ($query) => $query->where('aktif', true)->orderBy('id')])
            ->when($kategori !== null && $kategori !== '', fn ($query) => $query->where('kategori', $kategori))
            ->when($cari !== null && $cari !== '', fn ($query) => $query->where('nama', 'like', '%'.$cari.'%'))
            ->orderBy('id');
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function buat(array $data): Produk
    {
        return Produk::query()->create($data)->load([
            'varian' => fn ($query) => $query->where('aktif', true)->orderBy('id'),
        ]);
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function ubah(Produk $produk, array $data): Produk
    {
        $produk->update($data);

        return $produk->load([
            'varian' => fn ($query) => $query->where('aktif', true)->orderBy('id'),
        ]);
    }

    /**
     * @throws ApiException
     */
    public function hapus(Produk $produk): void
    {
        DB::transaction(function () use ($produk): void {
            $pesananAktif = Pesanan::query()
                ->whereIn('status', StatusPesanan::aktif())
                ->whereHas('detail', fn ($query) => $query->where('produk_id', $produk->id))
                ->exists();

            if ($pesananAktif) {
                throw new ApiException('Produk masih digunakan dalam pesanan aktif.', 409, [
                    'alasan' => 'produk_dipakai_pesanan_aktif',
                    'produk_id' => $produk->id,
                ]);
            }

            Keranjang::query()->where('produk_id', $produk->id)->delete();
            $produk->delete();
        }, 3);
    }
}
