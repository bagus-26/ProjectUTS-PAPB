<?php

namespace App\Http\Requests\Keranjang;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class IndexKeranjangRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        if ($this->query('kurir_id') === '') {
            $this->merge(['kurir_id' => null]);
        }
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'kurir_id' => [
                'nullable',
                'integer',
                Rule::exists('kurir', 'id')->where('aktif', true),
            ],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'kurir_id.integer' => 'Kurir tidak valid.',
            'kurir_id.exists' => 'Kurir tidak ditemukan atau sedang tidak aktif.',
        ];
    }
}
