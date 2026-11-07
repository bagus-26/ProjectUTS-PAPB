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
     * @return array{buka: bool, jam_buka: string, jam_tutup: string, pesan: string}
     */
    public function status(?CarbonInterface $waktu = null): array
    {
        $toko = $this->toko();
        $sekarang = $waktu ?? Carbon::now();
        $jamBuka = $this->normalisasiJam($toko->jam_buka);
        $jamTutup = $this->normalisasiJam($toko->jam_tutup);
        $jamSekarang = $sekarang->format('H:i:s');

        // Mendukung jam tutup yang melewati tengah malam, mis. 18:00–02:00.
        $buka = $jamTutup >= $jamBuka
            ? ($jamSekarang >= $jamBuka && $jamSekarang < $jamTutup)
            : ($jamSekarang >= $jamBuka || $jamSekarang < $jamTutup);

        return [
            'buka' => $buka,
            'jam_buka' => substr($jamBuka, 0, 5),
            'jam_tutup' => substr($jamTutup, 0, 5),
            'pesan' => sprintf(
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
