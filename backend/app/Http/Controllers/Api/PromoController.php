<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pelanggan;
use App\Models\Promo;
use App\Models\UserVoucher;
use App\Support\ResponsApi;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PromoController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $pelangganId = $this->pelangganId($request);
        $pelanggan = Pelanggan::query()->find($pelangganId);

        $promos = Promo::query()
            ->where('is_active', true)
            ->orderBy('point_cost')
            ->orderBy('id')
            ->get()
            ->map(fn (Promo $promo): array => $this->payloadPromo($promo));

        $vouchers = UserVoucher::query()
            ->with('promo')
            ->where('user_id', $pelangganId)
            ->orderByDesc('id')
            ->get()
            ->map(fn (UserVoucher $voucher): array => $this->payloadVoucher($voucher));

        return ResponsApi::sukses([
            'poin' => (int) ($pelanggan?->poin ?? 0),
            'promos' => $promos->values(),
            'vouchers' => $vouchers->values(),
        ], 'Katalog promo berhasil diambil');
    }

    public function redeemCode(Request $request): JsonResponse
    {
        $data = $request->validate([
            'code' => ['required', 'string', 'max:40'],
        ]);

        $pelangganId = $this->pelangganId($request);
        $kode = strtoupper(trim($data['code']));

        $promo = Promo::query()
            ->whereRaw('UPPER(code) = ?', [$kode])
            ->first();

        if ($promo === null || ! $promo->is_active) {
            return ResponsApi::gagal(
                'Kode promo tidak valid atau sudah tidak aktif.',
                422,
                null,
                ['code' => ['Kode promo tidak valid atau sudah tidak aktif.']],
            );
        }

        $sudahDiklaim = UserVoucher::query()
            ->where('user_id', $pelangganId)
            ->where('promo_id', $promo->id)
            ->exists();

        if ($sudahDiklaim) {
            return ResponsApi::gagal('Kode promo sudah pernah kamu klaim.', 409, [
                'alasan' => 'sudah_diklaim',
            ]);
        }

        $voucher = UserVoucher::query()->create([
            'user_id' => $pelangganId,
            'promo_id' => $promo->id,
            'status' => 'active',
        ])->load('promo');

        return ResponsApi::sukses([
            'poin' => (int) Pelanggan::query()->whereKey($pelangganId)->value('poin'),
            'voucher' => $this->payloadVoucher($voucher),
        ], 'Kode promo berhasil diklaim', 201);
    }

    public function redeemPoint(Request $request): JsonResponse
    {
        $data = $request->validate([
            'promo_id' => ['required', 'integer', 'exists:promos,id'],
        ]);

        $pelangganId = $this->pelangganId($request);

        return DB::transaction(function () use ($pelangganId, $data): JsonResponse {
            $pelanggan = Pelanggan::query()
                ->whereKey($pelangganId)
                ->lockForUpdate()
                ->first();

            $promo = Promo::query()
                ->whereKey((int) $data['promo_id'])
                ->lockForUpdate()
                ->first();

            if ($pelanggan === null) {
                return ResponsApi::gagal('Pelanggan tidak ditemukan.', 404);
            }

            if ($promo === null || ! $promo->is_active || $promo->point_cost <= 0) {
                return ResponsApi::gagal('Promo poin tidak tersedia.', 422, null, [
                    'promo_id' => ['Promo poin tidak tersedia.'],
                ]);
            }

            if ($pelanggan->poin < $promo->point_cost) {
                return ResponsApi::gagal('Poin kamu belum cukup untuk menukar promo ini.', 409, [
                    'alasan' => 'poin_kurang',
                    'poin' => (int) $pelanggan->poin,
                    'dibutuhkan' => (int) $promo->point_cost,
                ]);
            }

            $sudahDiklaim = UserVoucher::query()
                ->where('user_id', $pelangganId)
                ->where('promo_id', $promo->id)
                ->exists();

            if ($sudahDiklaim) {
                return ResponsApi::gagal('Promo ini sudah pernah kamu tukar.', 409, [
                    'alasan' => 'sudah_diklaim',
                ]);
            }

            $pelanggan->decrement('poin', $promo->point_cost);

            $voucher = UserVoucher::query()->create([
                'user_id' => $pelangganId,
                'promo_id' => $promo->id,
                'status' => 'active',
            ])->load('promo');

            return ResponsApi::sukses([
                'poin' => (int) $pelanggan->refresh()->poin,
                'voucher' => $this->payloadVoucher($voucher),
            ], 'Poin berhasil ditukar menjadi voucher', 201);
        });
    }

    /**
     * @return array<string, mixed>
     */
    private function payloadPromo(Promo $promo): array
    {
        return [
            'id' => $promo->id,
            'code' => $promo->code,
            'title' => $promo->title,
            'description' => $promo->description,
            'discount_type' => $promo->discount_type,
            'discount_value' => $promo->discount_value,
            'label_diskon' => $promo->labelDiskon(),
            'min_order' => $promo->min_order,
            'point_cost' => $promo->point_cost,
            'is_active' => $promo->is_active,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function payloadVoucher(UserVoucher $voucher): array
    {
        return [
            'id' => $voucher->id,
            'promo_id' => $voucher->promo_id,
            'status' => $voucher->status,
            'created_at' => $voucher->created_at?->toIso8601String(),
            'promo' => $voucher->promo === null ? null : $this->payloadPromo($voucher->promo),
        ];
    }
}
