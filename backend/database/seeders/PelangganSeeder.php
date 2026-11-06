<?php

namespace Database\Seeders;

use App\Models\Pelanggan;
use Illuminate\Database\Seeder;

class PelangganSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $pelanggan = [
            ['nama' => 'Pelanggan Uji 1', 'token' => 'kelompok1-token-statis'],
            ['nama' => 'Pelanggan Uji 2', 'token' => 'kelompok1-token-statis-2'],
        ];

        foreach ($pelanggan as $data) {
            Pelanggan::query()->updateOrCreate(
                ['token' => $data['token']],
                ['nama' => $data['nama']],
            );
        }
    }
}
