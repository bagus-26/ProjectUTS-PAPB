<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notifikasi;
use App\Support\ResponsApi;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotifikasiController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $pelangganId = $this->pelangganId($request);

        $items = Notifikasi::query()
            ->where('user_id', $pelangganId)
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->limit(50)
            ->get()
            ->map(fn (Notifikasi $item): array => $this->payload($item));

        $belumDibaca = Notifikasi::query()
            ->where('user_id', $pelangganId)
            ->where('is_read', false)
            ->count();

        return ResponsApi::sukses([
            'jumlah_belum_dibaca' => $belumDibaca,
            'items' => $items->values(),
        ], 'Daftar notifikasi berhasil diambil');
    }

    public function markAllRead(Request $request): JsonResponse
    {
        Notifikasi::query()
            ->where('user_id', $this->pelangganId($request))
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return ResponsApi::sukses(['jumlah_belum_dibaca' => 0], 'Notifikasi ditandai terbaca');
    }

    /**
     * @return array<string, mixed>
     */
    private function payload(Notifikasi $item): array
    {
        return [
            'id' => $item->id,
            'judul' => $item->judul,
            'pesan' => $item->pesan,
            'tipe' => $item->tipe,
            'is_read' => $item->is_read,
            'created_at' => $item->created_at?->toIso8601String(),
        ];
    }
}
