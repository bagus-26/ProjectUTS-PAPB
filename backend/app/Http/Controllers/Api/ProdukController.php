<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Produk;
use App\Models\VarianProduk;
use App\Services\ProdukService;
use App\Support\AturanProduk;
use App\Support\ResponsApi;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProdukController extends Controller
{
    public function __construct(
        private readonly ProdukService $produkService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $produk = $this->produkService
            ->queryDaftar($request->query('kategori'), $request->query('cari'))
            ->get()
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
        $data = $request->validate(AturanProduk::rules());
        $produk = $this->produkService->buat($data);

        return ResponsApi::sukses($this->representasi($produk), 'Produk berhasil ditambahkan', 201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $produk = Produk::query()->find($id);

        if ($produk === null) {
            return ResponsApi::gagal('Produk tidak ditemukan.', 404);
        }

        $produk = $this->produkService->ubah($produk, $request->validate(AturanProduk::rules()));

        return ResponsApi::sukses($this->representasi($produk), 'Produk berhasil diperbarui');
    }

    public function destroy(string $id): JsonResponse
    {
        $produk = Produk::query()->find($id);

        if ($produk === null) {
            return ResponsApi::gagal('Produk tidak ditemukan.', 404);
        }

        $this->produkService->hapus($produk);

        return ResponsApi::sukses(['id' => $produk->id], 'Produk berhasil dihapus');
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
