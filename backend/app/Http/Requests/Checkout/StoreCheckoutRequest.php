<?php

namespace App\Http\Requests\Checkout;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreCheckoutRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'kunci_idempoten' => $this->header('X-Kunci-Idempoten'),
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'kunci_idempoten' => ['required', 'uuid'],
            'nama_penerima' => ['required', 'string', 'max:100'],
            'alamat_penerima' => ['required', 'string', 'max:255'],
            'kurir_id' => [
                'required',
                'integer',
                Rule::exists('kurir', 'id')->where('aktif', true),
            ],
            'metode_pembayaran' => [
                'required',
                'string',
                Rule::exists('metode_pembayaran', 'kode')->where('aktif', true),
            ],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'kunci_idempoten.required' => 'Header X-Kunci-Idempoten wajib diisi.',
            'kunci_idempoten.uuid' => 'Header X-Kunci-Idempoten harus berupa UUID yang valid.',
            'nama_penerima.required' => 'Nama penerima wajib diisi.',
            'alamat_penerima.required' => 'Alamat penerima wajib diisi.',
            'kurir_id.required' => 'Kurir wajib dipilih.',
            'kurir_id.exists' => 'Kurir tidak ditemukan atau sedang tidak aktif.',
            'metode_pembayaran.required' => 'Metode pembayaran wajib dipilih.',
            'metode_pembayaran.exists' => 'Metode pembayaran tidak ditemukan atau sedang tidak aktif.',
        ];
    }
}
