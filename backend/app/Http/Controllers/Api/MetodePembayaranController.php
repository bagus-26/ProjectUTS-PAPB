<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MetodePembayaran;
use App\Support\ResponsApi;
use Illuminate\Http\JsonResponse;

class MetodePembayaranController extends Controller
{
    public function index(): JsonResponse
    {
        $metode = MetodePembayaran::query()
            ->where('aktif', true)
            ->orderBy('id')
            ->get(['id', 'kode', 'nama', 'aktif']);

        return ResponsApi::sukses($metode, 'Daftar metode pembayaran berhasil diambil');
    }
}
