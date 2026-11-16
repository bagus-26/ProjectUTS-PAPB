<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Promo extends Model
{
    protected $table = 'promos';

    protected $fillable = [
        'code',
        'title',
        'description',
        'discount_type',
        'discount_value',
        'min_order',
        'point_cost',
        'is_active',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'discount_value' => 'integer',
            'min_order' => 'integer',
            'point_cost' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    /**
     * @return HasMany<UserVoucher, $this>
     */
    public function vouchers(): HasMany
    {
        return $this->hasMany(UserVoucher::class);
    }

    public function labelDiskon(): string
    {
        if ($this->discount_type === 'percent') {
            return $this->discount_value.'%';
        }

        return 'Rp '.number_format($this->discount_value, 0, ',', '.');
    }
}
