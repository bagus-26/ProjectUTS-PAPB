<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Attributes\Table;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Table('pelanggan')]
#[Fillable(['nama', 'token'])]
#[Hidden(['token'])]
class Pelanggan extends Model
{
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
}
