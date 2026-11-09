<?php

namespace Tests\Feature;

use Database\Seeders\KurirSeeder;
use Database\Seeders\MetodePembayaranSeeder;
use Database\Seeders\PelangganSeeder;
use Database\Seeders\PesananSeeder;
use Database\Seeders\ProdukSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProdukApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed([
            PelangganSeeder::class,
            ProdukSeeder::class,
        ]);
    }

    public function test_daftar_produk_menyertakan_varian_aktif(): void
    {
        $response = $this->withToken('kelompok1-token-statis')
            ->getJson('/api/produk');

        $response->assertOk()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('data.0.nama', 'Nasi Goreng Spesial')
            ->assertJsonPath('data.0.varian.0.nama', 'Reguler')
            ->assertJsonPath('data.0.varian.1.tambahan_harga', 8000);
    }

    public function test_daftar_produk_dapat_difilter_dengan_kategori_dan_pencarian(): void
    {
        $response = $this->withToken('kelompok1-token-statis')
            ->getJson('/api/produk?kategori=Minuman&cari=jeruk');

        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.nama', 'Es Jeruk');
    }

    public function test_rincian_produk_tidak_ditemukan_mengembalikan_404(): void
    {
        $this->withToken('kelompok1-token-statis')
            ->getJson('/api/produk/9999')
            ->assertNotFound()
            ->assertJsonPath('code', '404');
    }

    public function test_daftar_kategori_hanya_memuat_kategori_produk_aktif(): void
    {
        $this->withToken('kelompok1-token-statis')
            ->getJson('/api/kategori')
            ->assertOk()
            ->assertJsonPath('data', ['Makanan', 'Minuman']);
    }

    public function test_produk_dapat_ditambah_diubah_dan_dihapus(): void
    {
        $api = $this->withToken('kelompok1-token-statis');
        $produk = [
            'nama' => 'Menu Tes',
            'harga' => 12000,
            'kategori' => 'Makanan',
            'stok' => 8,
            'tersedia' => true,
            'deskripsi' => 'Menu untuk pengujian.',
            'bisa_pedas' => false,
            'waktu_persiapan_menit' => 10,
        ];

        $id = $api->postJson('/api/produk', $produk)
            ->assertCreated()
            ->assertJsonPath('data.nama', 'Menu Tes')
            ->json('data.id');

        $api->putJson('/api/produk/'.$id, [...$produk, 'nama' => 'Menu Diperbarui'])
            ->assertOk()
            ->assertJsonPath('data.nama', 'Menu Diperbarui');

        $api->postJson('/api/keranjang', ['produk_id' => $id, 'jumlah' => 1])
            ->assertCreated();

        $api->deleteJson('/api/produk/'.$id)
            ->assertOk();

        $this->assertSoftDeleted('produk', ['id' => $id]);
        $this->assertDatabaseMissing('keranjang', ['produk_id' => $id]);
    }

    public function test_produk_pada_pesanan_aktif_tidak_dapat_dihapus(): void
    {
        $this->seed([
            KurirSeeder::class,
            MetodePembayaranSeeder::class,
            PesananSeeder::class,
        ]);

        $this->withToken('kelompok1-token-statis')
            ->deleteJson('/api/produk/1')
            ->assertStatus(409)
            ->assertJsonPath('data.alasan', 'produk_dipakai_pesanan_aktif');
    }
}
