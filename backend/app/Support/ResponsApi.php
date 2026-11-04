<?php

namespace App\Support;

use Illuminate\Http\JsonResponse;

class ResponsApi
{
    public static function sukses(mixed $data, string $message = 'Berhasil', int $kode = 200): JsonResponse
    {
        return response()->json([
            'status' => 'sukses',
            'code' => (string) $kode,
            'message' => $message,
            'data' => $data,
        ], $kode, [], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }

    /**
     * @param  array<string, mixed>|null  $errors
     */
    public static function gagal(string $message, int $kode, mixed $data = null, ?array $errors = null): JsonResponse
    {
        $payload = [
            'status' => 'gagal',
            'code' => (string) $kode,
            'message' => $message,
            'data' => $data,
        ];

        if ($errors !== null) {
            $payload['errors'] = $errors;
        }

        return response()->json($payload, $kode, [], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }
}
