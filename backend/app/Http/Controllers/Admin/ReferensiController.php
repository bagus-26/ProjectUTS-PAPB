<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Kurir;
use App\Models\MetodePembayaran;
use App\Models\Pelanggan;
use Illuminate\View\View;

class ReferensiController extends Controller
{
    public function index(): View
    {
        return view('admin.referensi.index', [
            'kurir' => Kurir::query()->orderBy('tarif')->orderBy('id')->get(),
            'metode' => MetodePembayaran::query()->orderBy('id')->get(),
            'pelanggan' => Pelanggan::query()
                ->withCount('pesanan')
                ->orderBy('id')
                ->get(),
        ]);
    }
}
