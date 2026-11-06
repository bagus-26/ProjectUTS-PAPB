<?php

namespace Database\Seeders;

use App\Models\Kurir;
use Illuminate\Database\Seeder;

class KurirSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $kurir = [
            ['nama' => 'Kurir Toko — Area Kampus', 'wilayah' => 'Sekitar ITSK RS dr. Soepraoen', 'tarif' => 5000],
            ['nama' => 'Kurir Toko — Dalam Kota', 'wilayah' => 'Kota Malang', 'tarif' => 10000],
            ['nama' => 'Kurir Toko — Kabupaten', 'wilayah' => 'Kabupaten Malang', 'tarif' => 18000],
        ];

        foreach ($kurir as $data) {
            Kurir::query()->updateOrCreate(
                ['nama' => $data['nama']],
                ['wilayah' => $data['wilayah'], 'tarif' => $data['tarif'], 'aktif' => true],
            );
        }
    }
}
