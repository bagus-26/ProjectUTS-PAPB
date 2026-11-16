<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Pelanggan extends Model
{
    protected $table = 'pelanggan';

    protected $fillable = ['nama', 'phone', 'email', 'token', 'poin'];

    protected $hidden = ['token'];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'poin' => 'integer',
        ];
    }

    /**
     * @return HasMany<Keranjang, $this>
     */
    public function keranjang(): HasMany
    {
        return $this->hasMany(Keranjang::class);
    }

    /**
     * @return HasMany<Pesanan, $this>
     */
    public function pesanan(): HasMany
    {
        return $this->hasMany(Pesanan::class);
    }

    /**
     * @return HasMany<UserVoucher, $this>
     */
    public function vouchers(): HasMany
    {
        return $this->hasMany(UserVoucher::class, 'user_id');
    }

    /**
     * @return HasMany<SupportMessage, $this>
     */
    public function supportMessages(): HasMany
    {
        return $this->hasMany(SupportMessage::class, 'user_id');
    }

    /**
     * @return HasMany<Notifikasi, $this>
     */
    public function notifikasi(): HasMany
    {
        return $this->hasMany(Notifikasi::class, 'user_id');
    }
}
