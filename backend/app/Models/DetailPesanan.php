<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Table;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Table('detail_pesanan')]
#[Fillable([
    'pesanan_id',
    'produk_id',
    'nama_produk',
    'varian_nama',
    'harga_dasar',
    'tambahan_harga',
    'harga_satuan',
    'jumlah',
    'subtotal',
    'tingkat_pedas',
    'catatan',
])]
class DetailPesanan extends Model
{
    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'harga_dasar' => 'integer',
            'tambahan_harga' => 'integer',
            'harga_satuan' => 'integer',
            'jumlah' => 'integer',
            'subtotal' => 'integer',
        ];
    }

    /**
     * @return BelongsTo<Pesanan, $this>
     */
    public function pesanan(): BelongsTo
    {
        return $this->belongsTo(Pesanan::class);
    }

    /**
     * @return BelongsTo<Produk, $this>
     */
    public function produk(): BelongsTo
    {
        return $this->belongsTo(Produk::class);
    }
}
