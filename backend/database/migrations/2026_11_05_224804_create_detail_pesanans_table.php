<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('detail_pesanan', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pesanan_id')->constrained('pesanan')->cascadeOnDelete();
            $table->foreignId('produk_id')->constrained('produk')->restrictOnDelete();
            $table->string('nama_produk', 150);
            $table->string('varian_nama', 50)->nullable();
            $table->unsignedInteger('harga_dasar');
            $table->unsignedInteger('tambahan_harga')->default(0);
            $table->unsignedInteger('harga_satuan');
            $table->unsignedSmallInteger('jumlah');
            $table->unsignedInteger('subtotal');
            $table->string('tingkat_pedas', 20)->nullable();
            $table->string('catatan', 200)->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('detail_pesanan');
    }
};
