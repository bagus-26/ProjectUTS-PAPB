<?php

namespace App\Http\Controllers;

use Illuminate\View\View;

/**
 * Halaman tujuan setelah pelanggan keluar dari halaman pembayaran Xendit.
 * Aplikasi Flutter akan menyegarkan status pesanan secara berkala, sehingga
 * halaman ini hanya perlu memberi tahu pelanggan untuk kembali ke aplikasi.
 */
class HalamanPembayaranController extends Controller
{
    public function __invoke(string $hasil): View
    {
        return view('pembayaran.status', [
            'berhasil' => $hasil === 'selesai',
        ]);
    }
}
