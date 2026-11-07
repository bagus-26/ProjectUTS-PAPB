<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Checkout\StoreCheckoutRequest;
use App\Services\CheckoutService;
use App\Support\ResponsApi;
use Illuminate\Http\JsonResponse;

class CheckoutController extends Controller
{
    public function __construct(
        private readonly CheckoutService $checkoutService,
    ) {}

    public function store(StoreCheckoutRequest $request): JsonResponse
    {
        $data = $request->validated();
        $kunciIdempoten = (string) $data['kunci_idempoten'];
        unset($data['kunci_idempoten']);

        $pesanan = $this->checkoutService->buat(
            $this->pelangganId($request),
            $data,
            $kunciIdempoten,
        );

        return ResponsApi::sukses($pesanan, 'Pesanan berhasil dibuat', 201);
    }
}
