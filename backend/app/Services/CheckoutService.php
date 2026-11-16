<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Keranjang;
use App\Models\Kurir;
use App\Models\MetodePembayaran;
use App\Models\Pelanggan;
use App\Models\Pesanan;
use App\Models\Produk;
use App\Models\UserVoucher;
use App\Models\VarianProduk;
use App\Support\JamOperasiToko;
use App\Support\NomorPesanan;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class CheckoutService
{
    public function __construct(
        private readonly JamOperasiToko $jamOperasiToko,
        private readonly PembayaranService $pembayaranService,
    ) {}

    /**
     * @param  array{nama_penerima: string, alamat_penerima: string, kurir_id: int, metode_pembayaran: string, phone?: string|null, region?: string|null, street_address?: string|null, detail_note?: string|null, label?: string|null, latitude?: float|string|null, longitude?: float|string|null, user_voucher_id?: int|null}  $data
     * @return array<string, mixed>
     */
    public function buat(int $pelangganId, array $data, string $kunciIdempoten): array
    {
        // D-10: jalur cepat idempotensi sebelum menyentuh transaksi.
        $pesananLama = $this->cariPesananIdempoten($pelangganId, $kunciIdempoten);

        if ($pesananLama !== null) {
            return $this->payloadPesanan($pesananLama);
        }

        $statusToko = $this->jamOperasiToko->status();

        if (! $statusToko['buka']) {
            throw new ApiException(
                $statusToko['pesan'],
                409,
                [
                    'alasan' => 'toko_tutup',
                    'jam_buka' => $statusToko['jam_buka'],
                    'jam_tutup' => $statusToko['jam_tutup'],
                ],
            );
        }

        // A2-07: ulangi transaksi hingga 3 kali bila terjadi deadlock.
        $pesanan = DB::transaction(function () use ($pelangganId, $data, $kunciIdempoten): Pesanan {
            // D-10: serialisasi checkout per pelanggan.
            Pelanggan::query()
                ->whereKey($pelangganId)
                ->lockForUpdate()
                ->first();

            $pesananLama = $this->cariPesananIdempoten($pelangganId, $kunciIdempoten);

            if ($pesananLama !== null) {
                return $pesananLama;
            }

            $items = Keranjang::query()
                ->where('pelanggan_id', $pelangganId)
                ->orderBy('id')
                ->lockForUpdate()
                ->get();

            if ($items->isEmpty()) {
                throw new ApiException('Keranjang masih kosong.', 409, [
                    'alasan' => 'keranjang_kosong',
                ]);
            }

            $produk = $this->kunciProduk($items);
            $varian = $this->ambilVarian($items);

            $this->pastikanStokCukup($items, $produk);
            $this->pastikanVarianValid($items, $produk, $varian);

            $kurir = Kurir::query()
                ->whereKey($data['kurir_id'])
                ->where('aktif', true)
                ->lockForUpdate()
                ->first();

            if ($kurir === null) {
                throw new ApiException('Kurir tidak ditemukan atau sedang tidak aktif.', 422, null, [
                    'kurir_id' => ['Kurir tidak ditemukan atau sedang tidak aktif.'],
                ]);
            }

            $metode = MetodePembayaran::query()
                ->where('kode', $data['metode_pembayaran'])
                ->where('aktif', true)
                ->lockForUpdate()
                ->first();

            if ($metode === null) {
                throw new ApiException('Metode pembayaran tidak ditemukan atau sedang tidak aktif.', 422, null, [
                    'metode_pembayaran' => ['Metode pembayaran tidak ditemukan atau sedang tidak aktif.'],
                ]);
            }

            $detail = [];
            $subtotal = 0;

            foreach ($items as $item) {
                $produkItem = $produk->get($item->produk_id);
                $varianItem = $item->varian_id === null ? null : $varian->get($item->varian_id);

                $hargaDasar = $produkItem->harga;
                $tambahanHarga = $varianItem?->tambahan_harga ?? 0;
                $hargaSatuan = $hargaDasar + $tambahanHarga;
                $subtotalItem = $hargaSatuan * $item->jumlah;
                $subtotal += $subtotalItem;

                // D-08: salin harga dan nama ke detail agar riwayat tidak berubah.
                $detail[] = [
                    'produk_id' => $produkItem->id,
                    'nama_produk' => $produkItem->nama,
                    'varian_nama' => $varianItem?->nama,
                    'harga_dasar' => $hargaDasar,
                    'tambahan_harga' => $tambahanHarga,
                    'harga_satuan' => $hargaSatuan,
                    'jumlah' => $item->jumlah,
                    'subtotal' => $subtotalItem,
                    'tingkat_pedas' => $item->tingkat_pedas,
                    'catatan' => $item->catatan,
                ];
            }

            $ongkosKirim = $kurir->tarif;

            $voucher = $this->ambilVoucher($pelangganId, $data['user_voucher_id'] ?? null, $subtotal);
            $diskon = $this->hitungDiskon($voucher, $subtotal);
            $total = max(0, $subtotal + $ongkosKirim - $diskon);

            $pesanan = Pesanan::query()->create([
                'nomor_pesanan' => NomorPesanan::berikutnya(),
                'pelanggan_id' => $pelangganId,
                'kurir_id' => $kurir->id,
                'metode_pembayaran_id' => $metode->id,
                'nama_penerima' => $data['nama_penerima'],
                'phone' => $data['phone'] ?? null,
                'region' => $data['region'] ?? null,
                'street_address' => $data['street_address'] ?? $data['alamat_penerima'],
                'detail_note' => $data['detail_note'] ?? null,
                'label' => $data['label'] ?? null,
                'latitude' => $data['latitude'] ?? null,
                'longitude' => $data['longitude'] ?? null,
                'user_voucher_id' => $voucher?->id,
                'discount_amount' => $diskon,
                'alamat_penerima' => $data['alamat_penerima'],
                'subtotal' => $subtotal,
                'ongkos_kirim' => $ongkosKirim,
                'total' => $total,
                'status' => 'menunggu_pembayaran',
                'kunci_idempoten' => $kunciIdempoten,
            ]);

            $pesanan->detail()->createMany($detail);

            foreach ($items->groupBy('produk_id') as $produkId => $itemsProduk) {
                $produkItem = $produk->get((int) $produkId);
                $produkItem->decrement('stok', (int) $itemsProduk->sum('jumlah'));
            }

            Keranjang::query()
                ->where('pelanggan_id', $pelangganId)
                ->delete();

            return $pesanan->load(['kurir', 'metodePembayaran', 'voucher.promo']);
        }, 3);

        return $this->payloadPesanan($pesanan);
    }

    private function cariPesananIdempoten(int $pelangganId, string $kunciIdempoten): ?Pesanan
    {
        return Pesanan::query()
            ->with(['kurir', 'metodePembayaran', 'voucher.promo'])
            ->where('pelanggan_id', $pelangganId)
            ->where('kunci_idempoten', $kunciIdempoten)
            ->first();
    }

    private function ambilVoucher(int $pelangganId, ?int $voucherId, int $subtotal): ?UserVoucher
    {
        if ($voucherId === null) {
            return null;
        }

        $voucher = UserVoucher::query()
            ->with('promo')
            ->where('user_id', $pelangganId)
            ->whereKey($voucherId)
            ->lockForUpdate()
            ->first();

        if ($voucher === null) {
            throw new ApiException('Voucher tidak ditemukan pada akun ini.', 422, null, [
                'user_voucher_id' => ['Voucher tidak ditemukan pada akun ini.'],
            ]);
        }

        if ($voucher->status !== 'active') {
            throw new ApiException('Voucher sudah tidak aktif.', 409, [
                'alasan' => 'voucher_tidak_aktif',
                'status_voucher' => $voucher->status,
            ]);
        }

        $promo = $voucher->promo;

        if ($promo === null || ! $promo->is_active) {
            throw new ApiException('Promo voucher sudah tidak berlaku.', 409, [
                'alasan' => 'promo_tidak_aktif',
            ]);
        }

        if ($subtotal < $promo->min_order) {
            throw new ApiException(
                'Minimal belanja untuk voucher ini adalah Rp '.number_format($promo->min_order, 0, ',', '.').'.',
                409,
                [
                    'alasan' => 'min_order_belum_terpenuhi',
                    'min_order' => $promo->min_order,
                    'subtotal' => $subtotal,
                ],
            );
        }

        return $voucher;
    }

    private function hitungDiskon(?UserVoucher $voucher, int $subtotal): int
    {
        if ($voucher === null || $voucher->promo === null) {
            return 0;
        }

        $promo = $voucher->promo;

        $diskon = $promo->discount_type === 'percent'
            ? intdiv($subtotal * $promo->discount_value, 100)
            : $promo->discount_value;

        return max(0, min($diskon, $subtotal));
    }

    /**
     * @param  Collection<int, Keranjang>  $items
     * @return Collection<int, Produk>
     */
    private function kunciProduk(Collection $items): Collection
    {
        $ids = $items->pluck('produk_id')->unique()->sort()->values()->all();

        $produk = Produk::query()
            ->withTrashed()
            ->whereIn('id', $ids)
            ->orderBy('id')
            ->lockForUpdate()
            ->get()
            ->keyBy('id');

        foreach ($ids as $id) {
            $item = $produk->get($id);

            if ($item === null || $item->trashed() || ! $item->tersedia) {
                throw new ApiException('Produk pada keranjang sudah tidak tersedia.', 409, [
                    'alasan' => 'produk_tidak_tersedia',
                    'produk_id' => $id,
                    'nama' => $item?->nama,
                ]);
            }
        }

        return $produk;
    }

    /**
     * @param  Collection<int, Keranjang>  $items
     * @return Collection<int, VarianProduk>
     */
    private function ambilVarian(Collection $items): Collection
    {
        $ids = $items->pluck('varian_id')->filter()->unique()->values()->all();

        if ($ids === []) {
            return collect();
        }

        return VarianProduk::query()
            ->whereIn('id', $ids)
            ->lockForUpdate()
            ->get()
            ->keyBy('id');
    }

    /**
     * @param  Collection<int, Keranjang>  $items
     * @param  Collection<int, Produk>  $produk
     */
    private function pastikanStokCukup(Collection $items, Collection $produk): void
    {
        $kurang = [];

        foreach ($items->groupBy('produk_id') as $produkId => $itemsProduk) {
            $produkItem = $produk->get((int) $produkId);
            $diminta = (int) $itemsProduk->sum('jumlah');

            if ($diminta > $produkItem->stok) {
                $kurang[] = [
                    'produk_id' => $produkItem->id,
                    'nama' => $produkItem->nama,
                    'diminta' => $diminta,
                    'tersedia' => $produkItem->stok,
                ];
            }
        }

        if ($kurang !== []) {
            throw new ApiException(
                sprintf('Stok tidak mencukupi untuk %d item', count($kurang)),
                409,
                [
                    'alasan' => 'stok_kurang',
                    'item_kurang' => $kurang,
                ],
            );
        }
    }

    /**
     * @param  Collection<int, Keranjang>  $items
     * @param  Collection<int, Produk>  $produk
     * @param  Collection<int, VarianProduk>  $varian
     */
    private function pastikanVarianValid(Collection $items, Collection $produk, Collection $varian): void
    {
        foreach ($items as $item) {
            if ($item->varian_id === null) {
                continue;
            }

            $varianItem = $varian->get($item->varian_id);
            $produkItem = $produk->get($item->produk_id);

            if (
                $varianItem === null
                || ! $varianItem->aktif
                || (int) $varianItem->produk_id !== (int) $produkItem->id
            ) {
                throw new ApiException('Varian pada keranjang sudah tidak tersedia.', 409, [
                    'alasan' => 'varian_tidak_tersedia',
                    'varian_id' => $item->varian_id,
                ]);
            }
        }
    }

    /**
     * @return array<string, mixed>
     */
    private function payloadPesanan(Pesanan $pesanan): array
    {
        $pesanan->loadMissing(['kurir', 'metodePembayaran', 'voucher.promo']);

        $voucher = $pesanan->voucher;

        return [
            'id' => $pesanan->id,
            'nomor_pesanan' => $pesanan->nomor_pesanan,
            'status' => $pesanan->status,
            'nama_penerima' => $pesanan->nama_penerima,
            'alamat_penerima' => $pesanan->alamat_penerima,
            'phone' => $pesanan->phone,
            'region' => $pesanan->region,
            'street_address' => $pesanan->street_address,
            'detail_note' => $pesanan->detail_note,
            'label' => $pesanan->label,
            'latitude' => $pesanan->latitude,
            'longitude' => $pesanan->longitude,
            'subtotal' => $pesanan->subtotal,
            'ongkos_kirim' => $pesanan->ongkos_kirim,
            'discount_amount' => $pesanan->discount_amount,
            'total' => $pesanan->total,
            'poin_diberikan' => $pesanan->poin_diberikan,
            'metode_pembayaran' => $pesanan->metodePembayaran?->kode,
            'voucher' => $voucher === null ? null : [
                'id' => $voucher->id,
                'status' => $voucher->status,
                'promo' => $voucher->promo === null ? null : [
                    'id' => $voucher->promo->id,
                    'code' => $voucher->promo->code,
                    'title' => $voucher->promo->title,
                    'discount_type' => $voucher->promo->discount_type,
                    'discount_value' => $voucher->promo->discount_value,
                ],
            ],
            'pembayaran' => $this->pembayaranService->pastikanInvoice($pesanan),
        ];
    }
}
