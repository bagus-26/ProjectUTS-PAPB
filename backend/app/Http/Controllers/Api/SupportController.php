<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SupportMessage;
use App\Support\ResponsApi;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SupportController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $pelangganId = $this->pelangganId($request);

        $pesan = SupportMessage::query()
            ->where('user_id', $pelangganId)
            ->orderBy('id')
            ->get()
            ->map(fn (SupportMessage $item): array => $this->payload($item));

        SupportMessage::query()
            ->where('user_id', $pelangganId)
            ->where('sender_role', 'admin')
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return ResponsApi::sukses($pesan, 'Pesan dukungan berhasil diambil');
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'message' => ['required', 'string', 'max:1000'],
        ]);

        $pesan = SupportMessage::query()->create([
            'user_id' => $this->pelangganId($request),
            'sender_role' => 'user',
            'message' => trim($data['message']),
            'is_read' => false,
        ]);

        return ResponsApi::sukses($this->payload($pesan), 'Pesan berhasil dikirim', 201);
    }

    public function unreadCount(Request $request): JsonResponse
    {
        $jumlah = SupportMessage::query()
            ->where('user_id', $this->pelangganId($request))
            ->where('sender_role', 'admin')
            ->where('is_read', false)
            ->count();

        return ResponsApi::sukses(['jumlah' => $jumlah], 'Jumlah pesan belum dibaca');
    }

    /**
     * @return array<string, mixed>
     */
    private function payload(SupportMessage $pesan): array
    {
        return [
            'id' => $pesan->id,
            'sender_role' => $pesan->sender_role,
            'message' => $pesan->message,
            'is_read' => $pesan->is_read,
            'created_at' => $pesan->created_at?->toIso8601String(),
        ];
    }
}
