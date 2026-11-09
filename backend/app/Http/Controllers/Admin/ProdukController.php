<?php

namespace App\Http\Controllers\Admin;

use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Models\Produk;
use App\Services\ProdukService;
use App\Support\AturanProduk;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class ProdukController extends Controller
{
    public function index(Request $request, ProdukService $produkService): View
    {
        $kategori = (string) $request->query('kategori', '');
        $cari = trim((string) $request->query('cari', ''));

        $daftar = $produkService
            ->queryDaftar($kategori, $cari)
            ->paginate(12)
            ->withQueryString();

        $kategoriTersedia = Produk::query()
            ->select('kategori')
            ->distinct()
            ->orderBy('kategori')
            ->pluck('kategori')
            ->merge(AturanProduk::kategori())
            ->unique()
            ->values();

        return view('admin.produk.index', [
            'daftar' => $daftar,
            'kategori' => $kategori,
            'cari' => $cari,
            'kategoriTersedia' => $kategoriTersedia,
        ]);
    }

    public function create(): View
    {
        return view('admin.produk.form', [
            'produk' => new Produk,
            'kategoriTersedia' => AturanProduk::kategori(),
        ]);
    }

    public function store(Request $request, ProdukService $produkService): RedirectResponse
    {
        $data = $request->validate(AturanProduk::rules());
        $produk = $produkService->buat($data);

        return redirect()->route('admin.produk.index')->with(
            'sukses',
            'Menu "'.$produk->nama.'" berhasil ditambahkan.',
        );
    }

    public function edit(Produk $produk): View
    {
        $produk->load(['varian' => fn ($query) => $query->orderBy('id')]);

        return view('admin.produk.form', [
            'produk' => $produk,
            'kategoriTersedia' => AturanProduk::kategori(),
        ]);
    }

    public function update(Request $request, Produk $produk, ProdukService $produkService): RedirectResponse
    {
        $data = $request->validate(AturanProduk::rules());
        $produkService->ubah($produk, $data);

        return redirect()->route('admin.produk.index')->with(
            'sukses',
            'Menu "'.$produk->nama.'" berhasil diperbarui.',
        );
    }

    public function destroy(Produk $produk, ProdukService $produkService): RedirectResponse
    {
        try {
            $produkService->hapus($produk);
        } catch (ApiException $exception) {
            return redirect()->back()->with('galat', $exception->getMessage());
        }

        return redirect()->route('admin.produk.index')->with(
            'sukses',
            'Menu "'.$produk->nama.'" berhasil dihapus.',
        );
    }
}
