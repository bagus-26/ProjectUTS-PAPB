<?php

namespace Database\Seeders;

use App\Models\MetodePembayaran;
use Illuminate\Database\Seeder;

class MetodePembayaranSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $metode = [
            ['kode' => 'tunai_di_tempat', 'nama' => 'Tunai di Tempat'],
            ['kode' => 'transfer_manual', 'nama' => 'Transfer Manual'],
        ];

        foreach ($metode as $data) {
            MetodePembayaran::query()->updateOrCreate(
                ['kode' => $data['kode']],
                ['nama' => $data['nama'], 'aktif' => true],
            );
        }
    }
}
