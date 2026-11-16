<?php

namespace Database\Seeders;

use App\Models\Pelanggan;
use App\Models\Promo;
use App\Models\UserVoucher;
use Illuminate\Database\Seeder;

class PromoSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $promo = [
            [
                'code' => 'MAKAN20',
                'title' => 'Diskon Rp20.000 Makanan',
                'description' => 'Potongan langsung Rp20.000 untuk belanja makanan minimal Rp50.000.',
                'discount_type' => 'fixed',
                'discount_value' => 20000,
                'min_order' => 50000,
                'point_cost' => 0,
                'is_active' => true,
            ],
            [
                'code' => 'HEMAT10',
                'title' => 'Diskon 10% Semua Menu',
                'description' => 'Tukar 200 poin untuk potongan 10% tanpa minimum belanja.',
                'discount_type' => 'percent',
                'discount_value' => 10,
                'min_order' => 0,
                'point_cost' => 200,
                'is_active' => true,
            ],
            [
                'code' => 'NGOPI50',
                'title' => 'Ngopi Lebih Murah Rp5.000',
                'description' => 'Tukar 100 poin untuk potongan Rp5.000 di kategori minuman.',
                'discount_type' => 'fixed',
                'discount_value' => 5000,
                'min_order' => 15000,
                'point_cost' => 100,
                'is_active' => true,
            ],
            [
                'code' => 'GRATISONGKIR',
                'title' => 'Gratis Ongkir Rp10.000',
                'description' => 'Potongan ongkir Rp10.000 untuk belanja minimal Rp30.000.',
                'discount_type' => 'fixed',
                'discount_value' => 10000,
                'min_order' => 30000,
                'point_cost' => 150,
                'is_active' => true,
            ],
        ];

        foreach ($promo as $data) {
            Promo::query()->updateOrCreate(
                ['code' => $data['code']],
                $data,
            );
        }

        $pelanggan = Pelanggan::query()
            ->where('token', 'kelompok1-token-statis')
            ->first();

        $promoDemo = Promo::query()->where('code', 'MAKAN20')->first();

        if ($pelanggan !== null && $promoDemo !== null) {
            UserVoucher::query()->firstOrCreate([
                'user_id' => $pelanggan->id,
                'promo_id' => $promoDemo->id,
            ], [
                'status' => 'active',
            ]);
        }
    }
}
