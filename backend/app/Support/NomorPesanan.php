<?php

namespace App\Support;

use App\Models\Pesanan;
use Carbon\CarbonInterface;
use Illuminate\Support\Carbon;

class NomorPesanan
{
    /**
     * Format: TKO1-YYYYMMDD-0001.
     *
     * Dipanggil di dalam transaksi checkout. Kunci baris terakhir hari itu
     * agar dua checkout paralel tidak menghasilkan nomor yang sama.
     */
    public static function berikutnya(?CarbonInterface $waktu = null): string
    {
        $waktu ??= Carbon::now();
        $awalan = 'TKO1-'.$waktu->format('Ymd').'-';
        $terakhir = Pesanan::query()
            ->where('nomor_pesanan', 'like', $awalan.'%')
            ->orderByDesc('nomor_pesanan')
            ->lockForUpdate()
            ->value('nomor_pesanan');

        $urut = $terakhir === null ? 1 : ((int) substr($terakhir, -4)) + 1;

        return $awalan.str_pad((string) $urut, 4, '0', STR_PAD_LEFT);
    }
}
