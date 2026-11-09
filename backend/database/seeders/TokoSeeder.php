<?php

namespace Database\Seeders;

use App\Models\Toko;
use Illuminate\Database\Seeder;

class TokoSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        Toko::query()->updateOrCreate(
            ['nama' => 'Warung Kelompok 1'],
            ['jam_buka' => '08:00', 'jam_tutup' => '21:00', 'tutup_manual' => false],
        );
    }
}
