<?php

namespace App\Services;

use App\Exceptions\XenditException;
use App\Models\Pesanan;
use App\Support\KanalXendit;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Klien tipis untuk Xendit Invoice API.
 *
 * Operasi yang dipakai aplikasi: membuat invoice, mengambil status invoice,
 * dan mengedaluwarsakan invoice saat pesanan dibatalkan. Kredensial tidak
 * pernah dikirim ke Flutter; seluruh komunikasi dengan Xendit terjadi di server.
 */
class XenditService
{
    public function siap(): bool
    {
        return trim((string) config('xendit.secret_key')) !== '';
    }

    /**
     * @return array<string, mixed>
     *
     * @throws XenditException
     */
    public function buatInvoice(Pesanan $pesanan, string $kodeKanal): array
    {
        $kunci = trim((string) config('xendit.secret_key'));

        if ($kunci === '') {
            throw new XenditException('Kunci API Xendit belum diatur.');
        }

        if (str_starts_with($kunci, 'xnd_public_')) {
            throw new XenditException(
                'XENDIT_SECRET_KEY berisi Public Key. Gunakan Secret Key (xnd_development_...) dari menu API Keys.',
            );
        }

        $payload = [
            'external_id' => $pesanan->nomor_pesanan,
            'amount' => (int) $pesanan->total,
            'description' => sprintf('%s - %s', $pesanan->nomor_pesanan, config('app.name')),
            'currency' => 'IDR',
            'invoice_duration' => (int) config('xendit.invoice_duration', 86400),
            'customer' => [
                'given_names' => $pesanan->nama_penerima,
            ],
            'success_redirect_url' => $this->urlKembali('selesai'),
            'failure_redirect_url' => $this->urlKembali('gagal'),
            'should_send_email' => false,
            'locale' => 'id',
            ...KanalXendit::opsi($kodeKanal),
        ];

        $response = $this->kirim('POST', '/v2/invoices', $payload);

        if (! $response->successful()) {
            throw new XenditException(
                sprintf('Xendit menolak pembuatan invoice (HTTP %d).', $response->status()),
                $response->json(),
            );
        }

        $data = $response->json();

        if (! is_array($data) || ! isset($data['id'], $data['invoice_url'])) {
            throw new XenditException('Respons invoice Xendit tidak lengkap.');
        }

        return $data;
    }

    /**
     * @return array<string, mixed>|null
     */
    public function ambilInvoice(string $invoiceId): ?array
    {
        try {
            $response = $this->kirim('GET', '/v2/invoices/'.$invoiceId);
        } catch (XenditException $exception) {
            Log::warning('Gagal menghubungi Xendit saat mengambil invoice.', [
                'invoice_id' => $invoiceId,
                'pesan' => $exception->getMessage(),
            ]);

            return null;
        }

        if ($response->status() === 404) {
            return null;
        }

        if (! $response->successful()) {
            Log::warning('Xendit mengembalikan galat saat mengambil invoice.', [
                'invoice_id' => $invoiceId,
                'status' => $response->status(),
            ]);

            return null;
        }

        $data = $response->json();

        return is_array($data) ? $data : null;
    }

    /**
     * Mengedaluwarsakan invoice agar tautan pembayaran tidak dapat dipakai
     * setelah pesanan dibatalkan. `null` berarti invoice tidak ditemukan atau
     * Xendit tidak dapat dihubungi; pembatalan pesanan tetap dianggap berhasil.
     *
     * @return array<string, mixed>|null
     */
    public function expireInvoice(string $invoiceId): ?array
    {
        if (! $this->siap()) {
            return null;
        }

        $invoiceId = trim($invoiceId);

        if ($invoiceId === '') {
            return null;
        }

        try {
            // Xendit mendokumentasikan endpoint ini dengan tanda seru di akhir.
            $response = $this->kirim('POST', '/invoices/'.$invoiceId.'/expire!');
        } catch (XenditException $exception) {
            Log::warning('Gagal menghubungi Xendit saat mengedaluwarsakan invoice.', [
                'invoice_id' => $invoiceId,
                'pesan' => $exception->getMessage(),
            ]);

            return null;
        }

        if (! $response->successful()) {
            Log::warning('Xendit menolak permintaan kedaluwarsa invoice.', [
                'invoice_id' => $invoiceId,
                'status' => $response->status(),
            ]);

            return null;
        }

        $data = $response->json();

        return is_array($data) ? $data : null;
    }

    /**
     * URL tujuan setelah pelanggan menyelesaikan atau membatalkan pembayaran.
     * Bila tidak dikonfigurasi, dipakai host permintaan saat ini agar tetap
     * dapat dibuka dari HP pada jaringan lokal.
     */
    public function urlKembali(string $hasil): string
    {
        $kunci = $hasil === 'gagal' ? 'failure_redirect_url' : 'success_redirect_url';
        $dikonfigurasi = trim((string) config('xendit.'.$kunci));

        if ($dikonfigurasi !== '') {
            return $dikonfigurasi;
        }

        return url('/pembayaran/'.$hasil);
    }

    /**
     * @param  array<string, mixed>  $payload
     *
     * @throws XenditException
     */
    private function kirim(string $metode, string $jalur, array $payload = []): Response
    {
        $url = rtrim((string) config('xendit.base_url', 'https://api.xendit.co'), '/').$jalur;

        try {
            $permintaan = Http::withBasicAuth((string) config('xendit.secret_key'), '')
                ->acceptJson()
                ->asJson()
                ->timeout((int) config('xendit.timeout', 15));

            return $metode === 'GET' ? $permintaan->get($url) : $permintaan->post($url, $payload);
        } catch (ConnectionException $exception) {
            throw new XenditException('Tidak dapat terhubung ke Xendit.', null, $exception);
        }
    }
}
