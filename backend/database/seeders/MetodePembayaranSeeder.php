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
            ['kode' => 'xendit_qris', 'nama' => 'QRIS (GoPay, OVO, DANA, ShopeePay)'],
            ['kode' => 'xendit_ewallet', 'nama' => 'E-Wallet (OVO, DANA, ShopeePay, LinkAja)'],
            ['kode' => 'xendit_va', 'nama' => 'Virtual Account Bank'],
            ['kode' => 'xendit_kartu', 'nama' => 'Kartu Kredit / Debit'],
        ];

        foreach ($metode as $data) {
            MetodePembayaran::query()->updateOrCreate(
                ['kode' => $data['kode']],
                ['nama' => $data['nama'], 'aktif' => true],
            );
        }
    }
}
