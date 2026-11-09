<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Toko;
use App\Support\JamOperasiToko;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class TokoController extends Controller
{
    public function index(JamOperasiToko $jamOperasiToko): View
    {
        $toko = Toko::query()->firstOrCreate([], [
            'nama' => 'Warung Kelompok 1',
            'jam_buka' => '08:00',
            'jam_tutup' => '21:00',
            'tutup_manual' => false,
        ]);

        return view('admin.toko.index', [
            'toko' => $toko,
            'status' => $jamOperasiToko->status(),
        ]);
    }

    public function update(Request $request, Toko $toko): RedirectResponse
    {
        $data = $request->validate([
            'nama' => ['required', 'string', 'max:100'],
            'jam_buka' => ['required', 'date_format:H:i'],
            'jam_tutup' => ['required', 'date_format:H:i'],
        ]);

        $toko->update($data);

        return redirect()->route('admin.toko.index')->with(
            'sukses',
            'Jam kerja toko berhasil diperbarui menjadi '.$data['jam_buka'].'–'.$data['jam_tutup'].' WIB.',
        );
    }

    public function tutupSekarang(Toko $toko): RedirectResponse
    {
        $toko->update(['tutup_manual' => true]);

        return redirect()->route('admin.toko.index')->with(
            'sukses',
            'Toko ditutup sementara. Checkout dari aplikasi Flutter akan ditolak sampai toko dibuka kembali.',
        );
    }

    public function bukaSekarang(Toko $toko): RedirectResponse
    {
        $toko->update(['tutup_manual' => false]);

        return redirect()->route('admin.toko.index')->with(
            'sukses',
            'Penutupan manual dilepas. Toko kembali mengikuti jadwal jam kerja.',
        );
    }
}
