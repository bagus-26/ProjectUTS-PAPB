<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Table;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Table('keranjang')]
#[Fillable([
    'pelanggan_id',
    'produk_id',
    'varian_id',
    'jumlah',
    'tingkat_pedas',
    'catatan',
])]
class Keranjang extends Model
{
    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'jumlah' => 'integer',
        ];
    }

    /**
     * @return BelongsTo<Pelanggan, $this>
     */
    public function pelanggan(): BelongsTo
    {
        return $this->belongsTo(Pelanggan::class);
    }

    /**
     * @return BelongsTo<Produk, $this>
     */
    public function produk(): BelongsTo
    {
        return $this->belongsTo(Produk::class);
    }

    /**
     * @return BelongsTo<VarianProduk, $this>
     */
    public function varian(): BelongsTo
    {
        return $this->belongsTo(VarianProduk::class, 'varian_id');
    }
}
