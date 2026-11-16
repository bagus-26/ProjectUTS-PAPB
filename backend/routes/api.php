<?php

use App\Http\Controllers\Api\CheckoutController;
use App\Http\Controllers\Api\KategoriController;
use App\Http\Controllers\Api\KeranjangController;
use App\Http\Controllers\Api\KurirController;
use App\Http\Controllers\Api\MetodePembayaranController;
use App\Http\Controllers\Api\PembayaranController;
use App\Http\Controllers\Api\PesananController;
use App\Http\Controllers\Api\ProdukController;
use App\Http\Controllers\Api\XenditCallbackController;
use Illuminate\Support\Facades\Route;

Route::get('/produk', [ProdukController::class, 'index']);
Route::get('/produk/{id}', [ProdukController::class, 'show']);
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

Route::post('/xendit/callback', [XenditCallbackController::class, 'store']);

Route::get('/pesanan', [PesananController::class, 'index']);
Route::get('/pesanan/{id}', [PesananController::class, 'show']);
Route::post('/pesanan/{id}/pembayaran', [PembayaranController::class, 'store']);
Route::patch('/pesanan/{id}/status', [PesananController::class, 'ubahStatus']);
