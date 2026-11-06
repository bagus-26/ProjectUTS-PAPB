<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VarianProduk extends Model
{
    protected $table = 'varian_produk';

    protected $fillable = ['produk_id', 'nama', 'tambahan_harga', 'aktif'];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'tambahan_harga' => 'integer',
            'aktif' => 'boolean',
        ];
    }

    /**
     * @return BelongsTo<Produk, $this>
     */
    public function produk(): BelongsTo
    {
        return $this->belongsTo(Produk::class);
    }
}
