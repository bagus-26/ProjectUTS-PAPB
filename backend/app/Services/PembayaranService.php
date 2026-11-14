<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Exceptions\XenditException;
use App\Models\Pesanan;
use App\Support\KanalXendit;
use App\Support\StatusPesanan;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

/**
 * Menjembatani pesanan dengan Xendit: membuat tautan pembayaran,
 * menyinkronkan status invoice, dan memproses webhook.
 *
 * Status pesanan tetap mengikuti state machine `StatusPesanan`. Invoice yang
 * sudah dibayar dipetakan ke `menunggu_konfirmasi`, lalu admin meng-ACC
 * menjadi `dibayar` seperti alur simulasi sebelumnya.
 */
class PembayaranService
{
    public function __construct(
        private readonly XenditService $xendit,
        private readonly PesananService $pesananService,
    ) {}

    public static function memakaiXendit(?Pesanan $pesanan): bool
    {
        return KanalXendit::mendukung($pesanan?->metodePembayaran?->kode);
    }

    /**
     * Mengembalikan ringkasan pembayaran; invoice dibuat bila belum ada.
     * Kegagalan gateway tidak menggagalkan checkout yang sudah tersimpan.
     *
     * @return array<string, mixed>|null
     */
    public function pastikanInvoice(Pesanan $pesanan): ?array
    {
        if (! self::memakaiXendit($pesanan)) {
            return null;
        }

        if ($pesanan->status !== StatusPesanan::MENUNGGU_PEMBAYARAN) {
            return $this->ringkasan($pesanan);
        }

        $sudahAda = $pesanan->xendit_invoice_url !== null
            && $pesanan->xendit_invoice_url !== ''
            && $pesanan->xendit_status !== 'EXPIRED';

        if ($sudahAda) {
            return $this->ringkasan($pesanan);
        }

        if (! $this->xendit->siap()) {
            Log::warning('Xendit belum dikonfigurasi; tautan pembayaran tidak dibuat.', [
                'pesanan_id' => $pesanan->id,
            ]);

            return null;
        }

        try {
            $invoice = $this->xendit->buatInvoice($pesanan, (string) $pesanan->metodePembayaran?->kode);
        } catch (XenditException $exception) {
            Log::error('Pembuatan invoice Xendit gagal.', [
                'pesanan_id' => $pesanan->id,
                'pesan' => $exception->getMessage(),
                'respons' => $exception->respons,
            ]);

            return null;
        }

        $pesanan->forceFill([
            'xendit_invoice_id' => (string) ($invoice['id'] ?? ''),
            'xendit_invoice_url' => (string) ($invoice['invoice_url'] ?? ''),
            'xendit_status' => strtoupper((string) ($invoice['status'] ?? 'PENDING')),
            'dibayar_pada' => null,
        ])->save();

        return $this->ringkasan($pesanan);
    }

    /**
     * Menanyakan status invoice langsung ke Xendit. Dipakai saat rincian
     * pesanan dibuka agar status tetap mutakhir walau webhook belum masuk
     * (mis. saat pengembangan di localhost). Dibatasi 5 detik per pesanan.
     */
    public function sinkronkan(Pesanan $pesanan): Pesanan
    {
        if (! self::memakaiXendit($pesanan)) {
            return $pesanan;
        }

        if ($pesanan->status !== StatusPesanan::MENUNGGU_PEMBAYARAN) {
            return $pesanan;
        }

        if ($pesanan->xendit_invoice_id === null || $pesanan->xendit_invoice_id === '') {
            return $pesanan;
        }

        if (! $this->xendit->siap()) {
            return $pesanan;
        }

        $kunciCache = 'xendit-sinkron-'.$pesanan->id;

        if (! Cache::add($kunciCache, true, 5)) {
            return $pesanan;
        }

        $invoice = $this->xendit->ambilInvoice($pesanan->xendit_invoice_id);

        if ($invoice === null) {
            return $pesanan;
        }

        $this->terapkanStatus($pesanan, $invoice);

        return $pesanan->refresh()->load(['kurir', 'metodePembayaran', 'detail']);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function tanganiCallback(array $payload): void
    {
        $pesanan = Pesanan::query()
            ->with('metodePembayaran')
            ->where('nomor_pesanan', (string) ($payload['external_id'] ?? ''))
            ->first();

        if ($pesanan === null && isset($payload['id'])) {
            $pesanan = Pesanan::query()
                ->with('metodePembayaran')
                ->where('xendit_invoice_id', (string) $payload['id'])
                ->first();
        }

        if ($pesanan === null) {
            Log::warning('Callback Xendit tidak cocok dengan pesanan mana pun.', [
                'external_id' => $payload['external_id'] ?? null,
            ]);

            return;
        }

        if (! self::memakaiXendit($pesanan)) {
            Log::warning('Callback Xendit diabaikan karena pesanan memakai metode non-Xendit.', [
                'pesanan_id' => $pesanan->id,
                'external_id' => $payload['external_id'] ?? null,
            ]);

            return;
        }

        $this->terapkanStatus($pesanan, $payload);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    private function terapkanStatus(Pesanan $pesanan, array $payload): void
    {
        $status = strtoupper((string) ($payload['status'] ?? ''));
        $perubahan = [];

        if ($status !== '') {
            $perubahan['xendit_status'] = $status;
        }

        if (isset($payload['id'])) {
            $perubahan['xendit_invoice_id'] = (string) $payload['id'];
        }

        if (in_array($status, ['PAID', 'SETTLED'], true)) {
            if ($pesanan->status === StatusPesanan::DIBATALKAN) {
                Log::warning('Pembayaran Xendit diterima untuk pesanan yang sudah dibatalkan.', [
                    'pesanan_id' => $pesanan->id,
                    'invoice_id' => $payload['id'] ?? $pesanan->xendit_invoice_id,
                ]);
            } else {
                $perubahan['dibayar_pada'] = $pesanan->dibayar_pada ?? now();
            }
        }

        if ($perubahan !== []) {
            $pesanan->forceFill($perubahan)->save();
        }

        if (! in_array($status, ['PAID', 'SETTLED'], true)) {
            return;
        }

        if ($pesanan->status !== StatusPesanan::MENUNGGU_PEMBAYARAN) {
            return;
        }

        try {
            $this->pesananService->ubahStatus($pesanan->id, StatusPesanan::MENUNGGU_KONFIRMASI);
        } catch (ApiException $exception) {
            // Callback ganda atau admin sudah memproses pesanan: abaikan.
            Log::info('Transisi status setelah pembayaran Xendit dilewati.', [
                'pesanan_id' => $pesanan->id,
                'pesan' => $exception->getMessage(),
            ]);
        }
    }

    /**
     * Mengedaluwarsakan invoice Xendit milik pesanan yang baru dibatalkan agar
     * tautan pembayaran tidak lagi dapat dipakai. Kegagalan gateway tidak
     * membatalkan pembatalan yang sudah tersimpan.
     */
    public function batalkanInvoice(Pesanan $pesanan): void
    {
        if (! self::memakaiXendit($pesanan)) {
            return;
        }

        $invoiceId = trim((string) $pesanan->xendit_invoice_id);

        if ($invoiceId === '') {
            return;
        }

        if (in_array((string) $pesanan->xendit_status, ['PAID', 'SETTLED', 'EXPIRED'], true)) {
            return;
        }

        $invoice = $this->xendit->expireInvoice($invoiceId);

        if ($invoice === null) {
            return;
        }

        $pesanan->forceFill([
            'xendit_status' => strtoupper((string) ($invoice['status'] ?? 'EXPIRED')),
        ])->save();
    }

    /**
     * @return array<string, mixed>|null
     */
    public function ringkasan(Pesanan $pesanan): ?array
    {
        if (! self::memakaiXendit($pesanan)) {
            return null;
        }

        return [
            'kanal' => $pesanan->metodePembayaran?->kode,
            'invoice_id' => $pesanan->xendit_invoice_id,
            'invoice_url' => $pesanan->xendit_invoice_url,
            'status' => $pesanan->xendit_status,
            'dibayar_pada' => $pesanan->dibayar_pada?->toIso8601String(),
        ];
    }
}
