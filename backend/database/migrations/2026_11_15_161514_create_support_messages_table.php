<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Percakapan dua arah antara pelanggan dan admin CS.
     */
    public function up(): void
    {
        Schema::create('support_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('pelanggan')->cascadeOnDelete();
            $table->string('sender_role', 10);
            $table->text('message');
            $table->boolean('is_read')->default(false);
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
            $table->index(['sender_role', 'is_read']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('support_messages');
    }
};
