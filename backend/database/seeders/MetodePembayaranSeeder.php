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
            ['kode' => 'xendit_qris', 'nama' => 'QRIS'],
            ['kode' => 'xendit_gopay', 'nama' => 'GoPay'],
            ['kode' => 'xendit_dana', 'nama' => 'DANA'],
            ['kode' => 'xendit_ovo', 'nama' => 'OVO'],
            ['kode' => 'xendit_transfer', 'nama' => 'Transfer Bank'],
        ];

        foreach ($metode as $data) {
            MetodePembayaran::query()->updateOrCreate(
                ['kode' => $data['kode']],
                ['nama' => $data['nama'], 'aktif' => true],
            );
        }

        MetodePembayaran::query()
            ->whereIn('kode', ['xendit_ewallet', 'xendit_va', 'xendit_kartu'])
            ->update(['aktif' => false]);
    }
}
