<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Alamat ala Shopee, voucher, dan jejak poin reward pada pesanan.
     */
    public function up(): void
    {
        Schema::table('pesanan', function (Blueprint $table) {
            $table->string('phone', 30)->nullable()->after('nama_penerima');
            $table->string('region', 150)->nullable()->after('phone');
            $table->string('street_address', 255)->nullable()->after('region');
            $table->string('detail_note', 200)->nullable()->after('street_address');
            $table->string('label', 30)->nullable()->after('detail_note');
            $table->decimal('latitude', 10, 7)->nullable()->after('label');
            $table->decimal('longitude', 10, 7)->nullable()->after('latitude');
            $table->foreignId('user_voucher_id')->nullable()->after('longitude')
                ->constrained('user_vouchers')->nullOnDelete();
            $table->unsignedInteger('discount_amount')->default(0)->after('user_voucher_id');
            $table->unsignedInteger('poin_diberikan')->default(0)->after('discount_amount');
        });
    }

    public function down(): void
    {
        Schema::table('pesanan', function (Blueprint $table) {
            $table->dropConstrainedForeignId('user_voucher_id');
            $table->dropColumn([
                'phone',
                'region',
                'street_address',
                'detail_note',
                'label',
                'latitude',
                'longitude',
                'discount_amount',
                'poin_diberikan',
            ]);
        });
    }
};
