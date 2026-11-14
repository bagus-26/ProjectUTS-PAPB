<?php

namespace App\Support;

/**
 * Pemetaan kode metode pembayaran Xendit ke opsi Invoice API.
 *
 * Pemetaan ini membuat halaman pembayaran Xendit hanya menampilkan kanal yang
 * dipilih pelanggan, mirip daftar metode pada toko top-up: QRIS, e-wallet,
 * virtual account, atau kartu.
 */
class KanalXendit
{
    public const PREFIX = 'xendit_';

    public static function mendukung(?string $kode): bool
    {
        return $kode !== null && str_starts_with($kode, self::PREFIX);
    }

    /**
     * @return array<string, mixed>
     */
    public static function opsi(string $kode): array
    {
        return match ($kode) {
            'xendit_qris' => ['payment_methods' => ['QRIS']],
            'xendit_ewallet' => ['payment_methods' => ['OVO', 'DANA', 'SHOPEEPAY', 'LINKAJA']],
            'xendit_va' => ['payment_methods' => ['BCA', 'BNI', 'BRI', 'MANDIRI', 'PERMATA']],
            'xendit_kartu' => ['payment_methods' => ['CREDIT_CARD']],
            default => [],
        };
    }
}
