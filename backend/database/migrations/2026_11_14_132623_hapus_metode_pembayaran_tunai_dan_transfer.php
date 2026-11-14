<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    private const KODE_LAMA = ['tunai_di_tempat', 'transfer_manual'];

    /**
     * Menghapus pesanan lama dan metode pembayaran yang sudah tidak didukung.
     */
    public function up(): void
    {
        $idLama = DB::table('metode_pembayaran')
            ->whereIn('kode', self::KODE_LAMA)
            ->pluck('id');

        if ($idLama->isEmpty()) {
            return;
        }

        DB::table('pesanan')
            ->whereIn('metode_pembayaran_id', $idLama)
            ->delete();

        DB::table('metode_pembayaran')->whereIn('id', $idLama)->delete();
    }

    /**
     * Mengembalikan pilihan metode lama. Pesanan yang dihapus tidak dipulihkan.
     */
    public function down(): void
    {
        foreach (self::KODE_LAMA as $kode) {
            DB::table('metode_pembayaran')->updateOrInsert(
                ['kode' => $kode],
                [
                    'nama' => $kode === 'tunai_di_tempat' ? 'Tunai di Tempat' : 'Transfer Manual',
                    'aktif' => true,
                    'updated_at' => now(),
                    'created_at' => now(),
                ],
            );
        }
    }
};
