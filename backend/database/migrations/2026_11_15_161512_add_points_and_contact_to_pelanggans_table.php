<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Menambahkan identitas kontak dan saldo poin reward pelanggan.
     */
    public function up(): void
    {
        Schema::table('pelanggan', function (Blueprint $table) {
            $table->string('phone', 30)->nullable()->after('nama');
            $table->string('email', 120)->nullable()->after('phone');
            $table->unsignedInteger('poin')->default(0)->after('token');
        });
    }

    public function down(): void
    {
        Schema::table('pelanggan', function (Blueprint $table) {
            $table->dropColumn(['phone', 'email', 'poin']);
        });
    }
};
