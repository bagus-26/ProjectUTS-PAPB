<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Table;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Table('pesanan')]
#[Fillable([
    'nomor_pesanan',
    'pelanggan_id',
    'kurir_id',
    'metode_pembayaran_id',
    'nama_penerima',
    'alamat_penerima',
    'subtotal',
    'ongkos_kirim',
    'total',
    'status',
    'kunci_idempoten',
])]
class Pesanan extends Model
{
    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'subtotal' => 'integer',
            'ongkos_kirim' => 'integer',
            'total' => 'integer',
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
     * @return BelongsTo<Kurir, $this>
     */
    public function kurir(): BelongsTo
    {
        return $this->belongsTo(Kurir::class);
    }

    /**
     * @return BelongsTo<MetodePembayaran, $this>
     */
    public function metodePembayaran(): BelongsTo
    {
        return $this->belongsTo(MetodePembayaran::class);
    }

    /**
     * @return HasMany<DetailPesanan, $this>
     */
    public function detail(): HasMany
    {
        return $this->hasMany(DetailPesanan::class);
    }
}
