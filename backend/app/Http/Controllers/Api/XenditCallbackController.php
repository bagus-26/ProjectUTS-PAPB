<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\PembayaranService;
use App\Support\ResponsApi;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Webhook invoice Xendit.
 *
 * Endpoint ini tidak memakai token pelanggan; keaslian permintaan diperiksa
 * lewat header `x-callback-token` yang nilainya sama dengan Callback Token
 * pada dashboard Xendit.
 */
class XenditCallbackController extends Controller
{
    public function __construct(
        private readonly PembayaranService $pembayaranService,
    ) {}

    public function store(Request $request): JsonResponse
    {
        $token = (string) config('xendit.callback_token');
        $diberikan = (string) $request->header('x-callback-token', '');

        if ($token === '' || ! hash_equals($token, $diberikan)) {
            return ResponsApi::gagal('Token callback tidak sah.', 401);
        }

        $data = $request->validate([
            'id' => ['required', 'string'],
            'external_id' => ['required', 'string'],
            'status' => ['required', 'string'],
        ]);

        $this->pembayaranService->tanganiCallback($data);

        return response()->json([
            'status' => 'sukses',
            'message' => 'Callback Xendit diproses.',
        ]);
    }
}
