<?php

namespace App\Support;

use Illuminate\Validation\Rule;

class AturanProduk
{
    /**
     * Aturan validasi produk yang dipakai bersama oleh API dan panel admin.
     *
     * @return array<string, array<int, mixed>>
     */
    public static function rules(): array
    {
        return [
            'nama' => ['required', 'string', 'max:150'],
            'harga' => ['required', 'integer', 'min:1', 'max:4294967295'],
            'kategori' => ['required', 'string', Rule::in(self::kategori())],
            'stok' => ['required', 'integer', 'min:0', 'max:4294967295'],
            'tersedia' => ['required', 'boolean'],
            'deskripsi' => ['nullable', 'string'],
            'bisa_pedas' => ['required', 'boolean'],
            'waktu_persiapan_menit' => ['required', 'integer', 'min:0', 'max:65535'],
        ];
    }

    /**
     * Pilihan kategori yang sama dengan dropdown formulir produk di Flutter.
     *
     * @return array<int, string>
     */
    public static function kategori(): array
    {
        return ['Makanan', 'Minuman', 'Snack'];
    }
}
