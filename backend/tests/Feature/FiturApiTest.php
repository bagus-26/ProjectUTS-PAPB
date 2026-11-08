<?php

namespace Tests\Feature;

use App\Models\Pesanan;
use App\Models\Produk;
use Carbon\Carbon;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FiturApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow(Carbon::parse('2026-11-08 12:00:00', 'Asia/Jakarta'));
        $this->seed(DatabaseSeeder::class);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_referensi_kurir_dan_metode_pembayaran_tersedia(): void
    {
        $this->withToken('kelompok1-token-statis')
            ->getJson('/api/kurir')
            ->assertOk()
            ->assertJsonPath('data.0.wilayah', 'Sekitar ITSK RS dr. Soepraoen');

        $this->withToken('kelompok1-token-statis')
            ->getJson('/api/metode-pembayaran')
            ->assertOk()
            ->assertJsonPath('data.0.kode', 'tunai_di_tempat');
    }

    public function test_pelanggan_dapat_menambah_mengubah_dan_menghapus_keranjang(): void
    {
        $api = $this->withToken('kelompok1-token-statis');
        $item = $api->postJson('/api/keranjang', [
            'produk_id' => 1,
            'jumlah' => 2,
            'varian_id' => 2,
            'tingkat_pedas' => 'sedang',
        ])->assertCreated()
            ->assertJsonPath('data.subtotal', 66000)
            ->json('data');

        $api->getJson('/api/keranjang?kurir_id=1')
            ->assertOk()
            ->assertJsonPath('data.jumlah_item', 2)
            ->assertJsonPath('data.ringkasan.total', 71000);

        $api->putJson('/api/keranjang/'.$item['id'], ['jumlah' => 1])
            ->assertOk()
            ->assertJsonPath('data.subtotal', 33000);

        $api->deleteJson('/api/keranjang/'.$item['id'])
            ->assertOk();
    }

    public function test_pelanggan_hanya_melihat_pesanan_miliknya_dan_detailnya(): void
    {
        $item = $this->withToken('kelompok1-token-statis')
            ->postJson('/api/keranjang', [
                'produk_id' => 1,
                'jumlah' => 1,
                'varian_id' => 1,
            ])
            ->assertCreated()
            ->json('data');

        $response = $this->withToken('kelompok1-token-statis')
            ->postJson('/api/checkout', [
                'nama_penerima' => 'Demo',
                'alamat_penerima' => 'Malang',
                'kurir_id' => 1,
                'metode_pembayaran' => 'transfer_manual',
            ], ['X-Kunci-Idempoten' => '13333333-3333-4333-8333-333333333333'])
            ->assertCreated()
            ->assertJsonPath('data.subtotal', 25000)
            ->json('data');

        $this->withToken('kelompok1-token-statis')
            ->getJson('/api/pesanan')
            ->assertOk()
            ->assertJsonPath('data.0.id', $response['id']);

        $this->withToken('kelompok1-token-statis')
            ->getJson('/api/pesanan/'.$response['id'])
            ->assertOk()
            ->assertJsonPath('data.items.0.produk_id', $item['produk_id'])
            ->assertJsonPath('data.items.0.harga_satuan', 25000);

        $this->withToken('kelompok1-token-statis-2')
            ->getJson('/api/pesanan/'.$response['id'])
            ->assertNotFound();
    }

    public function test_kunci_checkout_idempoten_mencegah_pesanan_ganda(): void
    {
        $this->withToken('kelompok1-token-statis')
            ->postJson('/api/keranjang', ['produk_id' => 1, 'jumlah' => 1, 'varian_id' => 1])
            ->assertCreated();

        $jumlahAwal = Pesanan::query()->count();
        $payload = [
            'nama_penerima' => 'Demo',
            'alamat_penerima' => 'Malang',
            'kurir_id' => 1,
            'metode_pembayaran' => 'transfer_manual',
        ];
        $header = ['X-Kunci-Idempoten' => '23333333-3333-4333-8333-333333333333'];

        $pertama = $this->withToken('kelompok1-token-statis')
            ->postJson('/api/checkout', $payload, $header)
            ->assertCreated()
            ->json('data.id');

        $kedua = $this->withToken('kelompok1-token-statis')
            ->postJson('/api/checkout', $payload, $header)
            ->assertCreated()
            ->json('data.id');

        $this->assertSame($pertama, $kedua);
        $this->assertDatabaseCount('pesanan', $jumlahAwal + 1);
    }

    public function test_checkout_mengosongkan_keranjang_dan_mengurangi_stok(): void
    {
        $this->withToken('kelompok1-token-statis')
            ->postJson('/api/keranjang', ['produk_id' => 1, 'jumlah' => 2, 'varian_id' => 1])
            ->assertCreated();

        $this->withToken('kelompok1-token-statis')
            ->postJson('/api/checkout', [
                'nama_penerima' => 'Demo',
                'alamat_penerima' => 'Malang',
                'kurir_id' => 1,
                'metode_pembayaran' => 'transfer_manual',
            ], ['X-Kunci-Idempoten' => '63333333-3333-4333-8333-333333333333'])
            ->assertCreated();

        $this->assertDatabaseHas('produk', ['id' => 1, 'stok' => 28]);
        $this->assertDatabaseMissing('keranjang', ['pelanggan_id' => 1]);
    }

    public function test_transisi_status_pesanan_mengikuti_alur_yang_diizinkan(): void
    {
        $pesanan = Pesanan::query()->where('pelanggan_id', 1)->firstOrFail();

        $this->withToken('kelompok1-token-statis')
            ->patchJson('/api/pesanan/'.$pesanan->id.'/status', ['status' => 'dibayar'])
            ->assertStatus(409);

        $this->withToken('kelompok1-token-statis')
            ->patchJson('/api/pesanan/'.$pesanan->id.'/status', ['status' => 'nilai_tidak_sah'])
            ->assertUnprocessable();

        $this->withToken('kelompok1-token-statis')
            ->patchJson('/api/pesanan/'.$pesanan->id.'/status', ['status' => 'menunggu_konfirmasi'])
            ->assertOk()
            ->assertJsonPath('data.status', 'menunggu_konfirmasi');
    }

    public function test_batal_pesanan_mengembalikan_stok(): void
    {
        $stokAwal = (int) Produk::query()->findOrFail(1)->stok;

        $this->withToken('kelompok1-token-statis')
            ->postJson('/api/keranjang', ['produk_id' => 1, 'jumlah' => 2, 'varian_id' => 1])
            ->assertCreated();

        $pesananId = $this->withToken('kelompok1-token-statis')
            ->postJson('/api/checkout', [
                'nama_penerima' => 'Demo',
                'alamat_penerima' => 'Malang',
                'kurir_id' => 1,
                'metode_pembayaran' => 'transfer_manual',
            ], ['X-Kunci-Idempoten' => '43333333-3333-4333-8333-333333333333'])
            ->assertCreated()
            ->json('data.id');

        $this->withToken('kelompok1-token-statis')
            ->patchJson('/api/pesanan/'.$pesananId.'/status', ['status' => 'dibatalkan'])
            ->assertOk()
            ->assertJsonPath('data.status', 'dibatalkan');

        $this->assertDatabaseHas('produk', ['id' => 1, 'stok' => $stokAwal]);
    }
}
