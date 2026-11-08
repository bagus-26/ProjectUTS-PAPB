<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Produk;
use App\Support\ResponsApi;
use Illuminate\Http\JsonResponse;

class KategoriController extends Controller
{
    public function index(): JsonResponse
    {
        $kategori = Produk::query()
            ->select('kategori')
            ->distinct()
            ->orderBy('kategori')
            ->pluck('kategori');

        return ResponsApi::sukses($kategori, 'Daftar kategori berhasil diambil');
    }
}
