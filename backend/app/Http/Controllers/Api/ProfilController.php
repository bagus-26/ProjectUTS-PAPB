<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notifikasi;
use App\Models\Pelanggan;
use App\Models\SupportMessage;
use App\Models\UserVoucher;
use App\Support\ResponsApi;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfilController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $pelanggan = Pelanggan::query()->find($this->pelangganId($request));

        if ($pelanggan === null) {
            return ResponsApi::gagal('Pelanggan tidak ditemukan.', 404);
        }

        return ResponsApi::sukses($this->payload($pelanggan), 'Profil berhasil diambil');
    }

    public function update(Request $request): JsonResponse
    {
        $data = $request->validate([
            'nama' => ['sometimes', 'required', 'string', 'max:100'],
            'phone' => ['nullable', 'string', 'max:30'],
            'email' => ['nullable', 'email', 'max:120'],
        ]);

        $pelanggan = Pelanggan::query()->find($this->pelangganId($request));

        if ($pelanggan === null) {
            return ResponsApi::gagal('Pelanggan tidak ditemukan.', 404);
        }

        $pelanggan->update($data);

        return ResponsApi::sukses($this->payload($pelanggan->refresh()), 'Profil berhasil diperbarui');
    }

    /**
     * @return array<string, mixed>
     */
    private function payload(Pelanggan $pelanggan): array
    {
        $voucherAktif = UserVoucher::query()
            ->where('user_id', $pelanggan->id)
            ->where('status', 'active')
            ->count();

        $pesanBelumDibaca = SupportMessage::query()
            ->where('user_id', $pelanggan->id)
            ->where('sender_role', 'admin')
            ->where('is_read', false)
            ->count();

        $notifikasiBelumDibaca = Notifikasi::query()
            ->where('user_id', $pelanggan->id)
            ->where('is_read', false)
            ->count();

        return [
            'id' => $pelanggan->id,
            'nama' => $pelanggan->nama,
            'phone' => $pelanggan->phone,
            'email' => $pelanggan->email,
            'poin' => (int) $pelanggan->poin,
            'voucher_aktif' => $voucherAktif,
            'pesan_belum_dibaca' => $pesanBelumDibaca,
            'notifikasi_belum_dibaca' => $notifikasiBelumDibaca,
        ];
    }
}
