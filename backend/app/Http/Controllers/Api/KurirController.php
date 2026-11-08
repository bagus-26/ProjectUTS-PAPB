<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Kurir;
use App\Support\ResponsApi;
use Illuminate\Http\JsonResponse;

class KurirController extends Controller
{
    public function index(): JsonResponse
    {
        $kurir = Kurir::query()
            ->where('aktif', true)
            ->orderBy('tarif')
            ->orderBy('id')
            ->get(['id', 'nama', 'wilayah', 'tarif', 'aktif']);

        return ResponsApi::sukses($kurir, 'Daftar kurir berhasil diambil');
    }
}
