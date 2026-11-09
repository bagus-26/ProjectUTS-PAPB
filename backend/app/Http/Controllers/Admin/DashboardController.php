<?php

namespace App\Http\Controllers\Admin;

use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use App\Models\Produk;
use App\Support\JamOperasiToko;
use App\Support\StatusPesanan;
use App\Support\Uang;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(JamOperasiToko $jamOperasiToko): View
    {
        $statusToko = $this->statusToko($jamOperasiToko);

        $statistik = [
            'pesanan_hari_ini' => Pesanan::query()->whereDate('created_at', today())->count(),
            'perlu_konfirmasi' => Pesanan::query()
                ->where('status', StatusPesanan::MENUNGGU_KONFIRMASI)
                ->count(),
            'pendapatan' => (int) Pesanan::query()
                ->whereIn('status', [
                    StatusPesanan::DIBAYAR,
                    StatusPesanan::DIPROSES,
                    StatusPesanan::DIKIRIM,
                    StatusPesanan::SELESAI,
                ])
                ->sum('total'),
            'produk_aktif' => Produk::query()
                ->where('tersedia', true)
                ->where('stok', '>', 0)
                ->count(),
        ];

        $hitungStatus = Pesanan::query()
            ->selectRaw('status, count(*) as jumlah')
            ->groupBy('status')
            ->pluck('jumlah', 'status')
            ->all();

        $pesananTerbaru = Pesanan::query()
            ->with(['kurir', 'metodePembayaran'])
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->limit(8)
            ->get();

        $pesananAktif = Pesanan::query()
            ->whereIn('status', StatusPesanan::aktif())
            ->count();

        return view('admin.dashboard', [
            'statistik' => $statistik,
            'pendapatan' => Uang::rupiah($statistik['pendapatan']),
            'hitungStatus' => $hitungStatus,
            'pesananTerbaru' => $pesananTerbaru,
            'pesananAktif' => $pesananAktif,
            'statusToko' => $statusToko,
        ]);
    }

    /**
     * @return array{buka: bool, tutup_manual: bool, jam_buka: string, jam_tutup: string, pesan: string}
     */
    private function statusToko(JamOperasiToko $jamOperasiToko): array
    {
        try {
            return $jamOperasiToko->status();
        } catch (ApiException) {
            return [
                'buka' => false,
                'tutup_manual' => false,
                'jam_buka' => '08:00',
                'jam_tutup' => '21:00',
                'pesan' => 'Konfigurasi toko belum tersedia. Buka menu Jam Kerja untuk mengaturnya.',
            ];
        }
    }
}
