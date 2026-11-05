<?php

namespace Database\Seeders;

use App\Models\Produk;
use Illuminate\Database\Seeder;

class ProdukSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $produk = [
            ['nama' => 'Nasi Goreng Spesial', 'kategori' => 'Makanan', 'harga' => 25000, 'stok' => 30, 'tersedia' => true, 'bisa_pedas' => true, 'waktu_persiapan_menit' => 15, 'deskripsi' => null],
            ['nama' => 'Mie Goreng Jawa', 'kategori' => 'Makanan', 'harga' => 22000, 'stok' => 25, 'tersedia' => true, 'bisa_pedas' => true, 'waktu_persiapan_menit' => 12, 'deskripsi' => null],
            ['nama' => 'Ayam Geprek', 'kategori' => 'Makanan', 'harga' => 24000, 'stok' => 20, 'tersedia' => true, 'bisa_pedas' => true, 'waktu_persiapan_menit' => 15, 'deskripsi' => null],
            ['nama' => 'Soto Ayam Lamongan', 'kategori' => 'Makanan', 'harga' => 20000, 'stok' => 20, 'tersedia' => true, 'bisa_pedas' => false, 'waktu_persiapan_menit' => 10, 'deskripsi' => null],
            ['nama' => 'Bakso Malang', 'kategori' => 'Makanan', 'harga' => 18000, 'stok' => 40, 'tersedia' => true, 'bisa_pedas' => true, 'waktu_persiapan_menit' => 10, 'deskripsi' => null],
            ['nama' => 'Rawon Daging', 'kategori' => 'Makanan', 'harga' => 28000, 'stok' => 3, 'tersedia' => true, 'bisa_pedas' => false, 'waktu_persiapan_menit' => 15, 'deskripsi' => null],
            ['nama' => 'Nasi Pecel', 'kategori' => 'Makanan', 'harga' => 15000, 'stok' => 30, 'tersedia' => true, 'bisa_pedas' => true, 'waktu_persiapan_menit' => 8, 'deskripsi' => null],
            ['nama' => 'Ayam Bakar Madu', 'kategori' => 'Makanan', 'harga' => 27000, 'stok' => 0, 'tersedia' => true, 'bisa_pedas' => false, 'waktu_persiapan_menit' => 20, 'deskripsi' => null],
            ['nama' => 'Es Teh Manis', 'kategori' => 'Minuman', 'harga' => 5000, 'stok' => 100, 'tersedia' => true, 'bisa_pedas' => false, 'waktu_persiapan_menit' => 3, 'deskripsi' => null],
            ['nama' => 'Es Jeruk', 'kategori' => 'Minuman', 'harga' => 8000, 'stok' => 80, 'tersedia' => true, 'bisa_pedas' => false, 'waktu_persiapan_menit' => 3, 'deskripsi' => null],
            ['nama' => 'Kopi Susu Gula Aren', 'kategori' => 'Minuman', 'harga' => 15000, 'stok' => 50, 'tersedia' => true, 'bisa_pedas' => false, 'waktu_persiapan_menit' => 5, 'deskripsi' => null],
            ['nama' => 'Es Cendol', 'kategori' => 'Minuman', 'harga' => 12000, 'stok' => 30, 'tersedia' => true, 'bisa_pedas' => false, 'waktu_persiapan_menit' => 5, 'deskripsi' => null],
            ['nama' => 'Wedang Jahe', 'kategori' => 'Minuman', 'harga' => 7000, 'stok' => 40, 'tersedia' => true, 'bisa_pedas' => false, 'waktu_persiapan_menit' => 5, 'deskripsi' => null],
            ['nama' => 'Jus Alpukat', 'kategori' => 'Minuman', 'harga' => 14000, 'stok' => 10, 'tersedia' => false, 'bisa_pedas' => false, 'waktu_persiapan_menit' => 7, 'deskripsi' => null],
        ];

        foreach ($produk as $data) {
            Produk::query()->updateOrCreate(
                ['nama' => $data['nama']],
                $data,
            );
        }

        $varian = [
            'Makanan' => ['Reguler' => 0, 'Jumbo' => 8000],
            'Minuman' => ['Reguler' => 0, 'Large' => 3000],
        ];

        foreach (Produk::query()->get() as $item) {
            foreach ($varian[$item->kategori] ?? [] as $nama => $tambahanHarga) {
                $item->varian()->updateOrCreate(
                    ['nama' => $nama],
                    ['tambahan_harga' => $tambahanHarga, 'aktif' => true],
                );
            }
        }
    }
}
