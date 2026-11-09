<?php

namespace App\Support;

use App\Exceptions\ApiException;
use App\Models\Toko;
use Carbon\CarbonInterface;
use Illuminate\Support\Carbon;

class JamOperasiToko
{
    public function toko(): Toko
    {
        $toko = Toko::query()->first();

        if ($toko === null) {
            throw new ApiException('Konfigurasi toko belum tersedia.', 500);
        }

        return $toko;
    }

    public function apakahBuka(?CarbonInterface $waktu = null): bool
    {
        return $this->status($waktu)['buka'];
    }

    /**
     * @return array{buka: bool, tutup_manual: bool, jam_buka: string, jam_tutup: string, pesan: string}
     */
    public function status(?CarbonInterface $waktu = null): array
    {
        $toko = $this->toko();
        $sekarang = $waktu ?? Carbon::now();
        $jamBuka = $this->normalisasiJam($toko->jam_buka);
        $jamTutup = $this->normalisasiJam($toko->jam_tutup);
        $jamSekarang = $sekarang->format('H:i:s');
        $tutupManual = (bool) $toko->tutup_manual;

        // Mendukung jam tutup yang melewati tengah malam, mis. 18:00–02:00.
        $sesuaiJadwal = $jamTutup >= $jamBuka
            ? ($jamSekarang >= $jamBuka && $jamSekarang < $jamTutup)
            : ($jamSekarang >= $jamBuka || $jamSekarang < $jamTutup);

        $buka = ! $tutupManual && $sesuaiJadwal;

        return [
            'buka' => $buka,
            'tutup_manual' => $tutupManual,
            'jam_buka' => substr($jamBuka, 0, 5),
            'jam_tutup' => substr($jamTutup, 0, 5),
            'pesan' => $tutupManual
                ? 'Toko sedang ditutup sementara oleh admin. Silakan coba beberapa saat lagi.'
                : sprintf(
                    'Toko sedang tutup. Pesanan hanya dapat dibuat pukul %s–%s WIB.',
                    $this->formatJam($jamBuka),
                    $this->formatJam($jamTutup),
                ),
        ];
    }

    private function normalisasiJam(string $jam): string
    {
        return strlen($jam) === 5 ? $jam.':00' : $jam;
    }

    private function formatJam(string $jam): string
    {
        return str_replace(':', '.', substr($jam, 0, 5));
    }
}
