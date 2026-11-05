<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Table;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Table('varian_produk')]
#[Fillable(['produk_id', 'nama', 'tambahan_harga', 'aktif'])]
class VarianProduk extends Model
{
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
