<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Toko extends Model
{
    protected $table = 'toko';

    protected $fillable = ['nama', 'jam_buka', 'jam_tutup', 'tutup_manual'];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'tutup_manual' => 'boolean',
        ];
    }
}
