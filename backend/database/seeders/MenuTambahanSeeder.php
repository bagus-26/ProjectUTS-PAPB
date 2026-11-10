<?php

namespace Database\Seeders;

use App\Models\Produk;
use Illuminate\Database\Seeder;

class MenuTambahanSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $produk = [
            [
                'nama' => 'Ayam Penyet Sambal Ijo',
                'kategori' => 'Makanan',
                'harga' => 25000,
                'stok' => 25,
                'tersedia' => true,
                'bisa_pedas' => true,
                'waktu_persiapan_menit' => 15,
                'deskripsi' => 'Ayam penyet dengan sambal ijo dan nasi hangat.',
                'varian' => ['Reguler' => 0, 'Jumbo' => 8000],
            ],
            [
                'nama' => 'Sate Ayam Madura',
                'kategori' => 'Makanan',
                'harga' => 28000,
                'stok' => 20,
                'tersedia' => true,
                'bisa_pedas' => false,
                'waktu_persiapan_menit' => 18,
                'deskripsi' => 'Sate ayam berbumbu kacang, disajikan dengan lontong.',
                'varian' => ['Reguler' => 0, 'Jumbo' => 8000],
            ],
            [
                'nama' => 'Matcha Latte',
                'kategori' => 'Minuman',
                'harga' => 18000,
                'stok' => 30,
                'tersedia' => true,
                'bisa_pedas' => false,
                'waktu_persiapan_menit' => 5,
                'deskripsi' => 'Matcha lembut berpadu dengan susu segar.',
                'varian' => ['Reguler' => 0, 'Large' => 3000],
            ],
            [
                'nama' => 'Es Teh Leci',
                'kategori' => 'Minuman',
                'harga' => 10000,
                'stok' => 30,
                'tersedia' => true,
                'bisa_pedas' => false,
                'waktu_persiapan_menit' => 4,
                'deskripsi' => 'Teh dingin dengan rasa manis dan buah leci.',
                'varian' => ['Reguler' => 0, 'Large' => 3000],
            ],
            [
                'nama' => 'Pisang Goreng Cokelat',
                'kategori' => 'Snack',
                'harga' => 12000,
                'stok' => 0,
                'tersedia' => true,
                'bisa_pedas' => false,
                'waktu_persiapan_menit' => 8,
                'deskripsi' => 'Pisang goreng renyah dengan lelehan cokelat.',
                'varian' => ['Reguler' => 0, 'Jumbo' => 6000],
            ],
        ];

        foreach ($produk as $data) {
            $varian = $data['varian'];
            unset($data['varian']);

            $item = Produk::query()->updateOrCreate(
                ['nama' => $data['nama']],
                $data,
            );

            foreach ($varian as $nama => $tambahanHarga) {
                $item->varian()->updateOrCreate(
                    ['nama' => $nama],
                    ['tambahan_harga' => $tambahanHarga, 'aktif' => true],
                );
            }
        }
    }
}
