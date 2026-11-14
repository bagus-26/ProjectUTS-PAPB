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
        Schema::table('pesanan', function (Blueprint $table) {
            $table->string('xendit_invoice_id', 100)->nullable()->after('kunci_idempoten');
            $table->string('xendit_invoice_url', 255)->nullable()->after('xendit_invoice_id');
            $table->string('xendit_status', 30)->nullable()->after('xendit_invoice_url');
            $table->timestamp('dibayar_pada')->nullable()->after('xendit_status');

            $table->index('xendit_invoice_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('pesanan', function (Blueprint $table) {
            $table->dropIndex(['xendit_invoice_id']);
            $table->dropColumn([
                'xendit_invoice_id',
                'xendit_invoice_url',
                'xendit_status',
                'dibayar_pada',
            ]);
        });
    }
};
