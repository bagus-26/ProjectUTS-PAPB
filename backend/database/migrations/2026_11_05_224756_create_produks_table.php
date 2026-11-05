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
        Schema::create('produk', function (Blueprint $table) {
            $table->id();
            $table->string('nama', 150);
            $table->unsignedInteger('harga');
            $table->string('kategori', 50);
            $table->unsignedInteger('stok')->default(0);
            $table->boolean('tersedia')->default(true);
            $table->text('deskripsi')->nullable();
            $table->boolean('bisa_pedas')->default(false);
            $table->unsignedSmallInteger('waktu_persiapan_menit')->default(0);
            $table->softDeletes();
            $table->timestamps();

            $table->index('nama');
            $table->index(['kategori', 'deleted_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('produk');
    }
};
