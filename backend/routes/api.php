<?php

use App\Http\Controllers\Api\CheckoutController;
use App\Http\Controllers\Api\KategoriController;
use App\Http\Controllers\Api\KeranjangController;
use App\Http\Controllers\Api\KurirController;
use App\Http\Controllers\Api\MetodePembayaranController;
use App\Http\Controllers\Api\NotifikasiController;
use App\Http\Controllers\Api\PembayaranController;
use App\Http\Controllers\Api\PesananController;
use App\Http\Controllers\Api\ProdukController;
use App\Http\Controllers\Api\ProfilController;
use App\Http\Controllers\Api\PromoController;
use App\Http\Controllers\Api\SupportController;
use App\Http\Controllers\Api\XenditCallbackController;
use Illuminate\Support\Facades\Route;

// Katalog menu: endpoint utama dan alias /menus untuk klien baru.
Route::get('/produk', [ProdukController::class, 'index']);
Route::get('/menus', [ProdukController::class, 'index']);
Route::get('/admin/menus', [ProdukController::class, 'adminIndex']);
Route::patch('/admin/menus/{id}/stock', [ProdukController::class, 'ubahStok']);
Route::get('/produk/{id}', [ProdukController::class, 'show']);
Route::get('/menus/{id}', [ProdukController::class, 'show']);
Route::post('/produk', [ProdukController::class, 'store']);
Route::put('/produk/{id}', [ProdukController::class, 'update']);
Route::delete('/produk/{id}', [ProdukController::class, 'destroy']);

Route::get('/kategori', [KategoriController::class, 'index']);

Route::get('/keranjang', [KeranjangController::class, 'index']);
Route::post('/keranjang', [KeranjangController::class, 'store']);
Route::put('/keranjang/{id}', [KeranjangController::class, 'update']);
Route::delete('/keranjang/{id}', [KeranjangController::class, 'destroy']);

Route::get('/kurir', [KurirController::class, 'index']);
Route::get('/metode-pembayaran', [MetodePembayaranController::class, 'index']);

Route::post('/checkout', [CheckoutController::class, 'store']);
Route::post('/orders', [CheckoutController::class, 'store']);

Route::post('/xendit/callback', [XenditCallbackController::class, 'store']);

Route::get('/pesanan', [PesananController::class, 'index']);
Route::get('/orders', [PesananController::class, 'index']);
Route::get('/pesanan/{id}', [PesananController::class, 'show']);
Route::get('/orders/{id}', [PesananController::class, 'show']);
Route::post('/pesanan/{id}/pembayaran', [PembayaranController::class, 'store']);
Route::patch('/pesanan/{id}/status', [PesananController::class, 'ubahStatus']);

Route::get('/promos', [PromoController::class, 'index']);
Route::post('/promos/redeem-code', [PromoController::class, 'redeemCode']);
Route::post('/promos/redeem-point', [PromoController::class, 'redeemPoint']);

Route::get('/support/messages', [SupportController::class, 'index']);
Route::post('/support/messages', [SupportController::class, 'store']);
Route::get('/support/unread-count', [SupportController::class, 'unreadCount']);

Route::get('/notifications', [NotifikasiController::class, 'index']);
Route::post('/notifications/read', [NotifikasiController::class, 'markAllRead']);

Route::get('/profil', [ProfilController::class, 'show']);
Route::patch('/profil', [ProfilController::class, 'update']);
Route::get('/pelanggan/profil', [ProfilController::class, 'show']);
