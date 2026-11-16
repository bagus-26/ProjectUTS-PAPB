<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Katalog promo yang dapat diklaim lewat kode atau ditukar dengan poin.
     */
    public function up(): void
    {
        Schema::create('promos', function (Blueprint $table) {
            $table->id();
            $table->string('code', 40)->unique();
            $table->string('title', 120);
            $table->text('description')->nullable();
            $table->string('discount_type', 20)->default('fixed');
            $table->unsignedInteger('discount_value');
            $table->unsignedInteger('min_order')->default(0);
            $table->unsignedInteger('point_cost')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index(['is_active', 'point_cost']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('promos');
    }
};
