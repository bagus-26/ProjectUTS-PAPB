<?php

use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\PesananController;
use App\Http\Controllers\Admin\ProdukController;
use App\Http\Controllers\Admin\PromoController;
use App\Http\Controllers\Admin\ReferensiController;
use App\Http\Controllers\Admin\SupportController;
use App\Http\Controllers\Admin\TokoController;
use App\Http\Controllers\DokumentasiApiController;
use App\Http\Controllers\HalamanPembayaranController;
use Illuminate\Support\Facades\Route;

Route::redirect('/', '/admin');

Route::get('/pembayaran/{hasil}', HalamanPembayaranController::class)
    ->whereIn('hasil', ['selesai', 'gagal'])
    ->name('pembayaran.status');

Route::get('/api', [DokumentasiApiController::class, 'index'])->name('dokumentasi.api');
Route::get('/api/openapi.json', [DokumentasiApiController::class, 'spesifikasi'])->name('dokumentasi.api.spesifikasi');

Route::prefix('admin')->name('admin.')->group(function (): void {
    Route::get('login', [AuthController::class, 'tampilkanLogin'])->name('login');
    Route::post('login', [AuthController::class, 'login'])
        ->middleware('throttle:6,1')
        ->name('login.proses');

    Route::middleware(['auth', 'admin'])->group(function (): void {
        Route::post('logout', [AuthController::class, 'logout'])->name('logout');
        Route::get('/', [DashboardController::class, 'index'])->name('dashboard');

        Route::get('pesanan', [PesananController::class, 'index'])->name('pesanan.index');
        Route::get('pesanan/{pesanan}', [PesananController::class, 'show'])->name('pesanan.show');
        Route::patch('pesanan/{pesanan}/status', [PesananController::class, 'ubahStatus'])->name('pesanan.status');

        Route::resource('produk', ProdukController::class)->except(['show']);
        Route::patch('produk/{produk}/stok', [ProdukController::class, 'ubahStok'])->name('produk.stok');
        Route::patch('produk/{produk}/ketersediaan', [ProdukController::class, 'ubahKetersediaan'])->name('produk.ketersediaan');

        // Alias penamaan /admin/menus untuk keselarasan instruksi
        Route::get('menus', [ProdukController::class, 'index'])->name('menus.index');
        Route::patch('menus/{produk}/stock', [ProdukController::class, 'ubahStok'])->name('menus.stock');

        Route::resource('promo', PromoController::class)->except(['show']);
        Route::patch('promo/{promo}/toggle', [PromoController::class, 'toggle'])->name('promo.toggle');

        Route::get('support/conversations', [SupportController::class, 'conversations'])->name('support.conversations');
        Route::get('support/messages/{pelanggan}', [SupportController::class, 'messages'])->name('support.messages');
        Route::post('support/messages/{pelanggan}', [SupportController::class, 'store'])->name('support.messages.store');
        Route::get('support', [SupportController::class, 'index'])->name('support.index');
        Route::get('support/{pelanggan}', [SupportController::class, 'show'])->name('support.show');
        Route::post('support/{pelanggan}', [SupportController::class, 'store'])->name('support.store');

        Route::get('toko', [TokoController::class, 'index'])->name('toko.index');
        Route::put('toko/{toko}', [TokoController::class, 'update'])->name('toko.update');
        Route::patch('toko/{toko}/tutup', [TokoController::class, 'tutupSekarang'])->name('toko.tutup');
        Route::patch('toko/{toko}/buka', [TokoController::class, 'bukaSekarang'])->name('toko.buka');

        Route::get('referensi', [ReferensiController::class, 'index'])->name('referensi.index');
    });
});
