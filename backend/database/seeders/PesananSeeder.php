<?php

namespace Database\Seeders;

use App\Models\Kurir;
use App\Models\MetodePembayaran;
use App\Models\Pelanggan;
use App\Models\Pesanan;
use App\Models\Produk;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

class PesananSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $pelanggan = Pelanggan::query()->where('token', 'kelompok1-token-statis')->firstOrFail();

        $kurirAreaKampus = Kurir::query()->where('nama', 'Kurir Toko — Area Kampus')->firstOrFail();
        $kurirDalamKota = Kurir::query()->where('nama', 'Kurir Toko — Dalam Kota')->firstOrFail();

        $tunai = MetodePembayaran::query()->where('kode', 'tunai_di_tempat')->firstOrFail();
        $transfer = MetodePembayaran::query()->where('kode', 'transfer_manual')->firstOrFail();

        $this->buatPesanan([
            'nomor_pesanan' => 'TKO1-20261101-0001',
            'pelanggan_id' => $pelanggan->id,
            'kurir_id' => $kurirAreaKampus->id,
            'metode_pembayaran_id' => $transfer->id,
            'nama_penerima' => 'Pelanggan Uji 1',
            'alamat_penerima' => 'Jl. Soepraoen No. 10, Malang',
            'ongkos_kirim' => 5000,
            'status' => 'menunggu_pembayaran',
            'kunci_idempoten' => '11111111-1111-4111-8111-111111111111',
            'dibuat_pada' => '2026-11-01 10:00:00',
        ], [
            ['produk' => 'Nasi Goreng Spesial', 'varian' => 'Jumbo', 'jumlah' => 2, 'tingkat_pedas' => 'sedang', 'catatan' => null],
            ['produk' => 'Es Teh Manis', 'varian' => 'Reguler', 'jumlah' => 2, 'tingkat_pedas' => null, 'catatan' => null],
        ]);

        $this->buatPesanan([
            'nomor_pesanan' => 'TKO1-20261102-0002',
            'pelanggan_id' => $pelanggan->id,
            'kurir_id' => $kurirDalamKota->id,
            'metode_pembayaran_id' => $tunai->id,
            'nama_penerima' => 'Pelanggan Uji 1',
            'alamat_penerima' => 'Jl. Soepraoen No. 10, Malang',
            'ongkos_kirim' => 10000,
            'status' => 'dibayar',
            'kunci_idempoten' => '22222222-2222-4222-8222-222222222222',
            'dibuat_pada' => '2026-11-02 12:30:00',
        ], [
            ['produk' => 'Bakso Malang', 'varian' => 'Reguler', 'jumlah' => 1, 'tingkat_pedas' => 'sedang', 'catatan' => 'Kuah dipisah'],
            ['produk' => 'Es Jeruk', 'varian' => 'Reguler', 'jumlah' => 1, 'tingkat_pedas' => null, 'catatan' => null],
        ]);

        $this->buatPesanan([
            'nomor_pesanan' => 'TKO1-20261103-0003',
            'pelanggan_id' => $pelanggan->id,
            'kurir_id' => $kurirAreaKampus->id,
            'metode_pembayaran_id' => $transfer->id,
            'nama_penerima' => 'Pelanggan Uji 1',
            'alamat_penerima' => 'Jl. Soepraoen No. 10, Malang',
            'ongkos_kirim' => 5000,
            'status' => 'selesai',
            'kunci_idempoten' => '33333333-3333-4333-8333-333333333333',
            'dibuat_pada' => '2026-11-03 18:15:00',
        ], [
            ['produk' => 'Kopi Susu Gula Aren', 'varian' => 'Reguler', 'jumlah' => 2, 'tingkat_pedas' => null, 'catatan' => null, 'harga_dasar' => 14000],
        ]);
    }

    /**
     * @param  array<string, mixed>  $data
     * @param  array<int, array<string, mixed>>  $items
     */
    private function buatPesanan(array $data, array $items): void
    {
        $detail = [];
        $subtotal = 0;

        foreach ($items as $item) {
            $produk = Produk::query()->where('nama', $item['produk'])->firstOrFail();
            $varian = $produk->varian()->where('nama', $item['varian'])->firstOrFail();
            $hargaDasar = $item['harga_dasar'] ?? $produk->harga;
            $hargaSatuan = $hargaDasar + $varian->tambahan_harga;
            $subtotalItem = $hargaSatuan * $item['jumlah'];
            $subtotal += $subtotalItem;

            $detail[] = [
                'produk_id' => $produk->id,
                'nama_produk' => $produk->nama,
                'varian_nama' => $varian->nama,
                'harga_dasar' => $hargaDasar,
                'tambahan_harga' => $varian->tambahan_harga,
                'harga_satuan' => $hargaSatuan,
                'jumlah' => $item['jumlah'],
                'subtotal' => $subtotalItem,
                'tingkat_pedas' => $item['tingkat_pedas'] ?? null,
                'catatan' => $item['catatan'] ?? null,
            ];
        }

        $pesanan = Pesanan::query()->updateOrCreate(
            ['nomor_pesanan' => $data['nomor_pesanan']],
            [
                'pelanggan_id' => $data['pelanggan_id'],
                'kurir_id' => $data['kurir_id'],
                'metode_pembayaran_id' => $data['metode_pembayaran_id'],
                'nama_penerima' => $data['nama_penerima'],
                'alamat_penerima' => $data['alamat_penerima'],
                'subtotal' => $subtotal,
                'ongkos_kirim' => $data['ongkos_kirim'],
                'total' => $subtotal + $data['ongkos_kirim'],
                'status' => $data['status'],
                'kunci_idempoten' => $data['kunci_idempoten'],
            ],
        );

        $pesanan->detail()->delete();
        $pesanan->detail()->createMany($detail);

        $dibuatPada = Carbon::parse($data['dibuat_pada']);

        $pesanan->forceFill([
            'created_at' => $dibuatPada,
            'updated_at' => $dibuatPada,
        ])->save();
    }
}
