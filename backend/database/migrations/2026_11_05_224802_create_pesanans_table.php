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
        Schema::create('pesanan', function (Blueprint $table) {
            $table->id();
            $table->string('nomor_pesanan', 30)->unique();
            $table->foreignId('pelanggan_id')->constrained('pelanggan')->restrictOnDelete();
            $table->foreignId('kurir_id')->constrained('kurir')->restrictOnDelete();
            $table->foreignId('metode_pembayaran_id')->constrained('metode_pembayaran')->restrictOnDelete();
            $table->string('nama_penerima', 100);
            $table->string('alamat_penerima', 255);
            $table->unsignedInteger('subtotal');
            $table->unsignedInteger('ongkos_kirim');
            $table->unsignedInteger('total');
            $table->string('status', 30)->default('menunggu_pembayaran');
            $table->uuid('kunci_idempoten');
            $table->timestamps();

            $table->unique(['pelanggan_id', 'kunci_idempoten']);
            $table->index(['pelanggan_id', 'created_at']);
            $table->index('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pesanan');
    }
};
