<?php

namespace App\Support;

class StatusPesanan
{
    public const MENUNGGU_PEMBAYARAN = 'menunggu_pembayaran';

    public const MENUNGGU_KONFIRMASI = 'menunggu_konfirmasi';

    public const DIBAYAR = 'dibayar';

    public const DIPROSES = 'diproses';

    public const DIKIRIM = 'dikirim';

    public const SELESAI = 'selesai';

    public const DIBATALKAN = 'dibatalkan';

    /**
     * State machine yang sama dengan yang dipakai endpoint PATCH /api/pesanan/{id}/status.
     *
     * @var array<string, array<int, string>>
     */
    public const TRANSISI = [
        self::MENUNGGU_PEMBAYARAN => [self::MENUNGGU_KONFIRMASI, self::DIBATALKAN],
        self::MENUNGGU_KONFIRMASI => [self::DIBAYAR, self::DIBATALKAN],
        self::DIBAYAR => [self::DIPROSES],
        self::DIPROSES => [self::DIKIRIM],
        self::DIKIRIM => [self::SELESAI],
        self::SELESAI => [],
        self::DIBATALKAN => [],
    ];

    /**
     * @return array<int, string>
     */
    public static function semua(): array
    {
        return array_keys(self::TRANSISI);
    }

    /**
     * @return array<int, string>
     */
    public static function transisi(string $status): array
    {
        return self::TRANSISI[$status] ?? [];
    }

    public static function boleh(string $dari, string $ke): bool
    {
        return in_array($ke, self::transisi($dari), true);
    }

    /**
     * Status yang masih berjalan dan boleh ditampilkan sebagai pesanan aktif.
     *
     * @return array<int, string>
     */
    public static function aktif(): array
    {
        return [
            self::MENUNGGU_PEMBAYARAN,
            self::MENUNGGU_KONFIRMASI,
            self::DIBAYAR,
            self::DIPROSES,
            self::DIKIRIM,
        ];
    }

    public static function label(string $status): string
    {
        return match ($status) {
            self::MENUNGGU_PEMBAYARAN => 'Menunggu Pembayaran',
            self::MENUNGGU_KONFIRMASI => 'Menunggu Konfirmasi',
            self::DIBAYAR => 'Sudah Dibayar',
            self::DIPROSES => 'Sedang Diracik',
            self::DIKIRIM => 'Dalam Pengiriman',
            self::SELESAI => 'Pesanan Selesai',
            self::DIBATALKAN => 'Dibatalkan',
            default => $status,
        };
    }

    public static function nada(string $status): string
    {
        return match ($status) {
            self::SELESAI => 'success',
            self::DIBATALKAN => 'danger',
            self::MENUNGGU_PEMBAYARAN => 'warning',
            self::MENUNGGU_KONFIRMASI => 'info',
            self::DIBAYAR, self::DIPROSES, self::DIKIRIM => 'primary',
            default => 'neutral',
        };
    }

    /**
     * Label tombol aksi admin untuk sebuah transisi status.
     */
    public static function aksi(string $dari, string $ke): string
    {
        return match ($dari.'>'.$ke) {
            self::MENUNGGU_PEMBAYARAN.'>'.self::MENUNGGU_KONFIRMASI => 'Tandai Sudah Dibayar',
            self::MENUNGGU_PEMBAYARAN.'>'.self::DIBATALKAN => 'Batalkan Pesanan',
            self::MENUNGGU_KONFIRMASI.'>'.self::DIBAYAR => 'ACC Pembayaran',
            self::MENUNGGU_KONFIRMASI.'>'.self::DIBATALKAN => 'Tolak Pesanan',
            self::DIBAYAR.'>'.self::DIPROSES => 'Proses Pesanan',
            self::DIPROSES.'>'.self::DIKIRIM => 'Kirim Pesanan',
            self::DIKIRIM.'>'.self::SELESAI => 'Selesaikan Pesanan',
            default => 'Ubah ke '.self::label($ke),
        };
    }
}
