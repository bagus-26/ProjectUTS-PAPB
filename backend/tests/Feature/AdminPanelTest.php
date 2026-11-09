<?php

namespace Tests\Feature;

use App\Models\Pesanan;
use App\Models\Produk;
use App\Models\Toko;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminPanelTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
    }

    public function test_tamu_diarahkan_ke_halaman_login_admin(): void
    {
        $this->get('/admin')->assertRedirect('/admin/login');
        $this->get('/admin/pesanan')->assertRedirect('/admin/login');
        $this->get('/admin/produk')->assertRedirect('/admin/login');
    }

    public function test_admin_dapat_login_dan_membuka_dashboard(): void
    {
        $this->post('/admin/login', [
            'email' => 'admin@makanyuk.test',
            'password' => 'admin12345',
        ])->assertRedirect(route('admin.dashboard'));

        $this->assertAuthenticated();

        $this->get(route('admin.dashboard'))
            ->assertOk()
            ->assertSee('Ringkasan Toko')
            ->assertSee('Status Toko');
    }

    public function test_pengguna_biasa_tidak_dapat_masuk_panel_admin(): void
    {
        $pengguna = User::factory()->create([
            'email' => 'biasa@example.com',
            'password' => 'rahasia123',
        ]);

        $this->post('/admin/login', [
            'email' => $pengguna->email,
            'password' => 'rahasia123',
        ])->assertSessionHasErrors('email');

        $this->assertGuest();
    }

    public function test_pengguna_biasa_yang_sudah_login_tidak_dapat_membuka_panel_admin(): void
    {
        $pengguna = User::factory()->create();

        $this->actingAs($pengguna)
            ->get(route('admin.dashboard'))
            ->assertForbidden();
    }

    public function test_semua_halaman_admin_dapat_dirender(): void
    {
        $admin = $this->admin();
        $pesanan = Pesanan::query()->firstOrFail();
        $produk = Produk::query()->firstOrFail();

        $this->actingAs($admin)->get(route('admin.pesanan.index'))->assertOk()->assertSee('Pesanan Masuk');
        $this->actingAs($admin)->get(route('admin.pesanan.show', $pesanan))->assertOk()->assertSee($pesanan->nomor_pesanan);
        $this->actingAs($admin)->get(route('admin.produk.index'))->assertOk()->assertSee('Kelola Produk');
        $this->actingAs($admin)->get(route('admin.produk.create'))->assertOk()->assertSee('Tambah Produk Baru');
        $this->actingAs($admin)->get(route('admin.produk.edit', $produk))->assertOk()->assertSee($produk->nama);
        $this->actingAs($admin)->get(route('admin.toko.index'))->assertOk()->assertSee('Jam Kerja Toko');
        $this->actingAs($admin)->get(route('admin.referensi.index'))->assertOk()->assertSee('Data Referensi');
    }

    public function test_admin_dapat_meng_acc_pembayaran_pesanan(): void
    {
        $admin = $this->admin();
        $pesanan = Pesanan::query()->where('nomor_pesanan', 'TKO1-20261101-0001')->firstOrFail();
        $pesanan->update(['status' => 'menunggu_konfirmasi']);

        $this->actingAs($admin)
            ->patch(route('admin.pesanan.status', $pesanan), ['status' => 'dibayar'])
            ->assertRedirect()
            ->assertSessionHas('sukses');

        $this->assertSame('dibayar', $pesanan->fresh()->status);
    }

    public function test_pembatalan_pesanan_mengembalikan_stok_produk(): void
    {
        $admin = $this->admin();
        $pesanan = Pesanan::query()->where('nomor_pesanan', 'TKO1-20261101-0001')->firstOrFail();
        $pesanan->update(['status' => 'menunggu_konfirmasi']);
        $pesanan->load('detail');

        $stokAwal = [];
        foreach ($pesanan->detail as $item) {
            $stokAwal[$item->produk_id] = Produk::query()->findOrFail($item->produk_id)->stok;
        }

        $this->actingAs($admin)
            ->patch(route('admin.pesanan.status', $pesanan), ['status' => 'dibatalkan'])
            ->assertRedirect();

        $this->assertSame('dibatalkan', $pesanan->fresh()->status);

        foreach ($pesanan->detail as $item) {
            $this->assertSame(
                $stokAwal[$item->produk_id] + $item->jumlah,
                Produk::query()->findOrFail($item->produk_id)->stok,
            );
        }
    }

    public function test_admin_dapat_mengubah_jam_kerja_dan_menutup_toko(): void
    {
        $admin = $this->admin();
        $toko = Toko::query()->firstOrFail();

        $this->actingAs($admin)
            ->put(route('admin.toko.update', $toko), [
                'nama' => 'Warung Kelompok 1',
                'jam_buka' => '09:00',
                'jam_tutup' => '22:00',
            ])
            ->assertRedirect(route('admin.toko.index'));

        $toko->refresh();
        $this->assertSame('09:00', substr((string) $toko->jam_buka, 0, 5));
        $this->assertSame('22:00', substr((string) $toko->jam_tutup, 0, 5));

        $this->actingAs($admin)
            ->patch(route('admin.toko.tutup', $toko))
            ->assertRedirect(route('admin.toko.index'));

        $this->assertTrue($toko->fresh()->tutup_manual);

        $api = $this->withToken('kelompok1-token-statis');

        $api->postJson('/api/keranjang', [
            'produk_id' => 1,
            'jumlah' => 1,
            'varian_id' => 1,
        ])->assertCreated();

        $api->postJson('/api/checkout', [
            'nama_penerima' => 'Demo',
            'alamat_penerima' => 'Jl. Soepraoen No. 10, Malang',
            'kurir_id' => 1,
            'metode_pembayaran' => 'tunai_di_tempat',
        ], ['X-Kunci-Idempoten' => 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'])
            ->assertStatus(409)
            ->assertJsonPath('data.alasan', 'toko_tutup');
    }

    public function test_admin_dapat_menambah_mengubah_dan_menghapus_produk(): void
    {
        $admin = $this->admin();
        $data = [
            'nama' => 'Menu Admin',
            'harga' => 15000,
            'kategori' => 'Makanan',
            'stok' => 9,
            'tersedia' => '1',
            'deskripsi' => 'Menu dari panel admin.',
            'bisa_pedas' => '1',
            'waktu_persiapan_menit' => 10,
        ];

        $this->actingAs($admin)
            ->post(route('admin.produk.store'), $data)
            ->assertRedirect(route('admin.produk.index'));

        $produk = Produk::query()->where('nama', 'Menu Admin')->firstOrFail();
        $this->assertTrue($produk->tersedia);
        $this->assertTrue($produk->bisa_pedas);

        $this->actingAs($admin)
            ->put(route('admin.produk.update', $produk), array_merge($data, [
                'nama' => 'Menu Admin Diubah',
                'harga' => 20000,
            ]))
            ->assertRedirect(route('admin.produk.index'));

        $this->assertSame('Menu Admin Diubah', $produk->fresh()->nama);
        $this->assertSame(20000, $produk->fresh()->harga);

        $this->actingAs($admin)
            ->delete(route('admin.produk.destroy', $produk))
            ->assertRedirect(route('admin.produk.index'));

        $this->assertSoftDeleted('produk', ['id' => $produk->id]);
    }

    public function test_produk_yang_dipakai_pesanan_aktif_tidak_dapat_dihapus(): void
    {
        $admin = $this->admin();
        $produk = Produk::query()->where('nama', 'Nasi Goreng Spesial')->firstOrFail();

        $this->actingAs($admin)
            ->delete(route('admin.produk.destroy', $produk))
            ->assertRedirect()
            ->assertSessionHas('galat');

        $this->assertNotSoftDeleted($produk);
    }

    private function admin(): User
    {
        return User::query()->where('email', 'admin@makanyuk.test')->firstOrFail();
    }
}
