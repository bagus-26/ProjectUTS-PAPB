<?php

namespace App\Http\Requests\Keranjang;

use Illuminate\Foundation\Http\FormRequest;

class UpdateKeranjangRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'jumlah' => ['required', 'integer', 'min:1', 'max:65535'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'jumlah.required' => 'Jumlah item wajib diisi.',
            'jumlah.integer' => 'Jumlah item harus berupa bilangan bulat.',
            'jumlah.min' => 'Jumlah item minimal 1.',
            'jumlah.max' => 'Jumlah item terlalu besar.',
        ];
    }
}
