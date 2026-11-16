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
        $namaPenerima = $this->input('nama_penerima', $this->input('recipient_name'));
        $streetAddress = $this->input('street_address');
        $region = $this->input('region');
        $alamatPenerima = $this->input('alamat_penerima');

        if (($alamatPenerima === null || trim((string) $alamatPenerima) === '')
            && ($streetAddress !== null || $region !== null)) {
            $alamatPenerima = trim(implode(', ', array_filter([
                trim((string) $streetAddress),
                trim((string) $region),
            ])));
        }

        $kunciIdempoten = $this->header('X-Kunci-Idempoten')
            ?? $this->input('kunci_idempoten')
            ?? (string) \Illuminate\Support\Str::uuid();
        $metodePembayaran = $this->input('metode_pembayaran', $this->input('payment_method'));
        $userVoucherId = $this->input('user_voucher_id', $this->input('voucher_id'));

        $this->merge([
            'kunci_idempoten' => $kunciIdempoten,
            'nama_penerima' => $namaPenerima,
            'alamat_penerima' => $alamatPenerima,
            'metode_pembayaran' => $metodePembayaran,
            'user_voucher_id' => $userVoucherId !== null && $userVoucherId !== ''
                ? (int) $userVoucherId
                : null,
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
            'phone' => ['nullable', 'string', 'max:30'],
            'region' => ['nullable', 'string', 'max:150'],
            'street_address' => ['nullable', 'string', 'max:255'],
            'detail_note' => ['nullable', 'string', 'max:200'],
            'label' => ['nullable', 'string', 'max:30'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'user_voucher_id' => [
                'nullable',
                'integer',
                Rule::exists('user_vouchers', 'id'),
            ],
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
            'phone.max' => 'Nomor WhatsApp terlalu panjang.',
            'latitude.between' => 'Koordinat lintang tidak valid.',
            'longitude.between' => 'Koordinat bujur tidak valid.',
            'user_voucher_id.exists' => 'Voucher tidak ditemukan.',
            'kurir_id.required' => 'Kurir wajib dipilih.',
            'kurir_id.exists' => 'Kurir tidak ditemukan atau sedang tidak aktif.',
            'metode_pembayaran.required' => 'Metode pembayaran wajib dipilih.',
            'metode_pembayaran.exists' => 'Metode pembayaran tidak ditemukan atau sedang tidak aktif.',
        ];
    }
}
