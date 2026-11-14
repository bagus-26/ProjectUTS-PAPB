<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use App\Services\PembayaranService;
use App\Support\KanalXendit;
use App\Support\ResponsApi;
use App\Support\StatusPesanan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PembayaranController extends Controller
{
    public function __construct(
        private readonly PembayaranService $pembayaranService,
    ) {}

    /**
     * Membuat atau memakai ulang tautan pembayaran Xendit untuk sebuah pesanan.
     */
    public function store(Request $request, string $id): JsonResponse
    {
        $pesanan = Pesanan::query()
            ->with('metodePembayaran')
            ->where('pelanggan_id', $this->pelangganId($request))
            ->whereKey($id)
            ->first();

        if ($pesanan === null) {
            return ResponsApi::gagal('Pesanan tidak ditemukan.', 404);
        }

        if (! KanalXendit::mendukung($pesanan->metodePembayaran?->kode)) {
            throw new ApiException('Pesanan ini tidak memakai pembayaran Xendit.', 422);
        }

        if ($pesanan->status !== StatusPesanan::MENUNGGU_PEMBAYARAN) {
            throw new ApiException('Pesanan ini tidak sedang menunggu pembayaran.', 409, [
                'alasan' => 'status_tidak_sesuai',
                'status' => $pesanan->status,
            ]);
        }

        $pembayaran = $this->pembayaranService->pastikanInvoice($pesanan);

        if ($pembayaran === null || empty($pembayaran['invoice_url'])) {
            throw new ApiException(
                'Halaman pembayaran belum dapat dibuat. Periksa konfigurasi Xendit lalu coba lagi.',
                502,
            );
        }

        return ResponsApi::sukses($pembayaran, 'Halaman pembayaran berhasil disiapkan.');
    }
}
