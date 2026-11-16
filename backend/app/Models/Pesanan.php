<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Pesanan extends Model
{
    protected $table = 'pesanan';

    protected $fillable = [
        'nomor_pesanan',
        'pelanggan_id',
        'kurir_id',
        'metode_pembayaran_id',
        'nama_penerima',
        'phone',
        'region',
        'street_address',
        'detail_note',
        'label',
        'latitude',
        'longitude',
        'user_voucher_id',
        'discount_amount',
        'poin_diberikan',
        'alamat_penerima',
        'subtotal',
        'ongkos_kirim',
        'total',
        'status',
        'kunci_idempoten',
        'xendit_invoice_id',
        'xendit_invoice_url',
        'xendit_status',
        'dibayar_pada',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'subtotal' => 'integer',
            'ongkos_kirim' => 'integer',
            'total' => 'integer',
            'discount_amount' => 'integer',
            'poin_diberikan' => 'integer',
            'latitude' => 'float',
            'longitude' => 'float',
            'dibayar_pada' => 'datetime',
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
     * @return BelongsTo<UserVoucher, $this>
     */
    public function voucher(): BelongsTo
    {
        return $this->belongsTo(UserVoucher::class, 'user_voucher_id');
    }

    /**
     * @return HasMany<DetailPesanan, $this>
     */
    public function detail(): HasMany
    {
        return $this->hasMany(DetailPesanan::class);
    }
}
