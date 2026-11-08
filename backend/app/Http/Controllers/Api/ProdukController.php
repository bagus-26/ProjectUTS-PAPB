<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use App\Models\Produk;
use App\Models\VarianProduk;
use App\Support\ResponsApi;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProdukController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Produk::query()->with([
            'varian' => fn ($query) => $query->where('aktif', true)->orderBy('id'),
        ]);

        if ($kategori = $request->query('kategori')) {
            $query->where('kategori', $kategori);
        }

        if ($cari = $request->query('cari')) {
            $query->where('nama', 'like', '%'.$cari.'%');
        }

        $produk = $query->orderBy('id')->get()
            ->map(fn (Produk $item): array => $this->representasi($item));

        return ResponsApi::sukses($produk, 'Daftar produk berhasil diambil');
    }

    public function show(string $id): JsonResponse
    {
        $produk = Produk::query()
            ->with(['varian' => fn ($query) => $query->where('aktif', true)->orderBy('id')])
            ->find($id);

        if ($produk === null) {
            return ResponsApi::gagal('Produk tidak ditemukan.', 404);
        }

        return ResponsApi::sukses($this->representasi($produk), 'Rincian produk berhasil diambil');
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate($this->aturanProduk());
        $produk = Produk::query()->create($data);
        $produk->load(['varian' => fn ($query) => $query->where('aktif', true)->orderBy('id')]);

        return ResponsApi::sukses($this->representasi($produk), 'Produk berhasil ditambahkan', 201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $produk = Produk::query()->find($id);

        if ($produk === null) {
            return ResponsApi::gagal('Produk tidak ditemukan.', 404);
        }

        $produk->update($request->validate($this->aturanProduk()));
        $produk->load(['varian' => fn ($query) => $query->where('aktif', true)->orderBy('id')]);

        return ResponsApi::sukses($this->representasi($produk), 'Produk berhasil diperbarui');
    }

    public function destroy(string $id): JsonResponse
    {
        $produk = Produk::query()->find($id);

        if ($produk === null) {
            return ResponsApi::gagal('Produk tidak ditemukan.', 404);
        }

        $pesananAktif = Pesanan::query()
            ->whereIn('status', ['menunggu_pembayaran', 'menunggu_konfirmasi', 'dibayar', 'diproses', 'dikirim'])
            ->whereHas('detail', fn ($query) => $query->where('produk_id', $produk->id))
            ->exists();

        if ($pesananAktif) {
            return ResponsApi::gagal('Produk masih digunakan dalam pesanan aktif.', 409, [
                'alasan' => 'produk_dipakai_pesanan_aktif',
                'produk_id' => $produk->id,
            ]);
        }

        $produk->delete();

        return ResponsApi::sukses(['id' => $produk->id], 'Produk berhasil dihapus');
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    private function aturanProduk(): array
    {
        return [
            'nama' => ['required', 'string', 'max:150'],
            'harga' => ['required', 'integer', 'min:1', 'max:4294967295'],
            'kategori' => ['required', 'string', 'max:50'],
            'stok' => ['required', 'integer', 'min:0', 'max:4294967295'],
            'tersedia' => ['required', 'boolean'],
            'deskripsi' => ['nullable', 'string'],
            'bisa_pedas' => ['required', 'boolean'],
            'waktu_persiapan_menit' => ['required', 'integer', 'min:0', 'max:65535'],
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function representasi(Produk $produk): array
    {
        return [
            'id' => $produk->id,
            'nama' => $produk->nama,
            'harga' => $produk->harga,
            'kategori' => $produk->kategori,
            'stok' => $produk->stok,
            'tersedia' => $produk->tersedia,
            'deskripsi' => $produk->deskripsi,
            'bisa_pedas' => $produk->bisa_pedas,
            'waktu_persiapan_menit' => $produk->waktu_persiapan_menit,
            'varian' => $produk->varian->map(fn (VarianProduk $varian): array => [
                'id' => $varian->id,
                'nama' => $varian->nama,
                'tambahan_harga' => $varian->tambahan_harga,
            ])->values(),
        ];
    }
}
