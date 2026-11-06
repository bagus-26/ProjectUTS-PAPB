<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Produk extends Model
{
    use SoftDeletes;

    protected $table = 'produk';

    protected $fillable = [
        'nama',
        'harga',
        'kategori',
        'stok',
        'tersedia',
        'deskripsi',
        'bisa_pedas',
        'waktu_persiapan_menit',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'harga' => 'integer',
            'stok' => 'integer',
            'tersedia' => 'boolean',
            'bisa_pedas' => 'boolean',
            'waktu_persiapan_menit' => 'integer',
        ];
    }

    /**
     * @return HasMany<VarianProduk, $this>
     */
    public function varian(): HasMany
    {
        return $this->hasMany(VarianProduk::class);
    }

    /**
     * @return HasMany<Keranjang, $this>
     */
    public function keranjang(): HasMany
    {
        return $this->hasMany(Keranjang::class);
    }

    /**
     * @return HasMany<DetailPesanan, $this>
     */
    public function detailPesanan(): HasMany
    {
        return $this->hasMany(DetailPesanan::class);
    }
}
