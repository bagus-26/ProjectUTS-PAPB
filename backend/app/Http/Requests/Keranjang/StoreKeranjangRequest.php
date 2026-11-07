<?php

namespace App\Http\Requests\Keranjang;

use App\Models\Produk;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class StoreKeranjangRequest extends FormRequest
{
    /**
     * @var array<int, string>
     */
    public const TINGKAT_PEDAS = ['tidak_pedas', 'sedang', 'pedas', 'sangat_pedas'];

    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $catatan = $this->input('catatan');

        $this->merge([
            'varian_id' => $this->input('varian_id') === '' ? null : $this->input('varian_id'),
            'tingkat_pedas' => $this->input('tingkat_pedas') === '' ? null : $this->input('tingkat_pedas'),
            'catatan' => is_string($catatan) && trim($catatan) === '' ? null : $catatan,
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'produk_id' => [
                'required',
                'integer',
                Rule::exists('produk', 'id')->whereNull('deleted_at'),
            ],
            'jumlah' => ['required', 'integer', 'min:1', 'max:65535'],
            'varian_id' => [
                'nullable',
                'integer',
                Rule::exists('varian_produk', 'id')
                    ->where('produk_id', $this->input('produk_id'))
                    ->where('aktif', true),
            ],
            'tingkat_pedas' => ['nullable', 'string', Rule::in(self::TINGKAT_PEDAS)],
            'catatan' => ['nullable', 'string', 'max:200'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'produk_id.required' => 'Produk wajib dipilih.',
            'produk_id.exists' => 'Produk tidak ditemukan.',
            'jumlah.required' => 'Jumlah item wajib diisi.',
            'jumlah.min' => 'Jumlah item minimal 1.',
            'jumlah.max' => 'Jumlah item terlalu besar.',
            'varian_id.exists' => 'Varian tidak valid untuk produk ini.',
            'tingkat_pedas.in' => 'Tingkat kepedasan tidak dikenal.',
            'catatan.max' => 'Catatan maksimal 200 karakter.',
        ];
    }

    /**
     * @return array<int, callable(Validator): void>
     */
    public function after(): array
    {
        return [
            function (Validator $validator): void {
                if ($validator->errors()->isNotEmpty()) {
                    return;
                }

                $produk = Produk::query()->find($this->integer('produk_id'));

                if ($produk !== null && $this->filled('tingkat_pedas') && ! $produk->bisa_pedas) {
                    $validator->errors()->add(
                        'tingkat_pedas',
                        'Produk ini tidak menerima pilihan tingkat kepedasan.',
                    );
                }
            },
        ];
    }
}
