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
            [
                'nama' => 'Budi Santoso',
                'phone' => '+62 812-3456-7890',
                'email' => 'budi.santoso@email.com',
                'poin' => 1450,
                'token' => 'kelompok1-token-statis',
            ],
            [
                'nama' => 'Pelanggan Uji 2',
                'phone' => '+62 813-2222-3333',
                'email' => 'pelanggan2@makanyuk.test',
                'poin' => 250,
                'token' => 'kelompok1-token-statis-2',
            ],
        ];

        foreach ($pelanggan as $data) {
            Pelanggan::query()->updateOrCreate(
                ['token' => $data['token']],
                $data,
            );
        }
    }
}
