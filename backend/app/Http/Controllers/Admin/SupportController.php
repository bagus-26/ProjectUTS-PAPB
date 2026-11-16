<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Notifikasi;
use App\Models\Pelanggan;
use App\Models\SupportMessage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\View\View;

class SupportController extends Controller
{
    public function index(): View
    {
        $percakapan = Pelanggan::query()
            ->whereHas('supportMessages')
            ->withCount([
                'supportMessages as belum_dibaca' => fn ($query) => $query
                    ->where('sender_role', 'user')
                    ->where('is_read', false),
            ])
            ->with(['supportMessages' => fn ($query) => $query->latest('id')->limit(1)])
            ->get()
            ->sortByDesc(fn (Pelanggan $pelanggan): int => (int) $pelanggan->supportMessages->first()?->id)
            ->values();

        return view('admin.support.index', [
            'percakapan' => $percakapan,
            'totalBelumDibaca' => $percakapan->sum('belum_dibaca'),
        ]);
    }

    public function show(Pelanggan $pelanggan): View
    {
        $this->tandaiTerbaca($pelanggan->id);

        $pesan = SupportMessage::query()
            ->where('user_id', $pelanggan->id)
            ->orderBy('id')
            ->get();

        return view('admin.support.show', [
            'pelanggan' => $pelanggan,
            'pesan' => $pesan,
        ]);
    }

    public function store(Request $request, Pelanggan $pelanggan): RedirectResponse|JsonResponse
    {
        $data = $request->validate([
            'message' => ['required', 'string', 'max:1000'],
        ]);

        $pesan = SupportMessage::query()->create([
            'user_id' => $pelanggan->id,
            'sender_role' => 'admin',
            'message' => trim($data['message']),
            'is_read' => false,
        ]);

        Notifikasi::query()->create([
            'user_id' => $pelanggan->id,
            'judul' => 'Balasan dari CS MakanYuk!',
            'pesan' => Str::limit(trim($data['message']), 140),
            'tipe' => 'support',
        ]);

        if ($request->expectsJson()) {
            return response()->json([
                'status' => 'sukses',
                'data' => $this->payload($pesan),
            ], 201);
        }

        return redirect()->route('admin.support.show', $pelanggan)->with(
            'sukses',
            'Balasan berhasil dikirim ke pelanggan.',
        );
    }

    public function conversations(): JsonResponse
    {
        $percakapan = Pelanggan::query()
            ->whereHas('supportMessages')
            ->withCount([
                'supportMessages as belum_dibaca' => fn ($query) => $query
                    ->where('sender_role', 'user')
                    ->where('is_read', false),
            ])
            ->with(['supportMessages' => fn ($query) => $query->latest('id')->limit(1)])
            ->get()
            ->map(fn (Pelanggan $pelanggan): array => [
                'user_id' => $pelanggan->id,
                'nama' => $pelanggan->nama,
                'phone' => $pelanggan->phone,
                'belum_dibaca' => (int) $pelanggan->belum_dibaca,
                'pesan_terakhir' => $pelanggan->supportMessages->first()?->message,
                'waktu_terakhir' => $pelanggan->supportMessages->first()?->created_at?->toIso8601String(),
            ])
            ->values();

        return response()->json(['status' => 'sukses', 'data' => $percakapan]);
    }

    public function messages(Pelanggan $pelanggan): JsonResponse
    {
        $this->tandaiTerbaca($pelanggan->id);

        $pesan = SupportMessage::query()
            ->where('user_id', $pelanggan->id)
            ->orderBy('id')
            ->get()
            ->map(fn (SupportMessage $item): array => $this->payload($item))
            ->values();

        return response()->json(['status' => 'sukses', 'data' => $pesan]);
    }

    private function tandaiTerbaca(int $pelangganId): void
    {
        SupportMessage::query()
            ->where('user_id', $pelangganId)
            ->where('sender_role', 'user')
            ->where('is_read', false)
            ->update(['is_read' => true]);
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
            'waktu' => $pesan->created_at?->format('H:i'),
        ];
    }
}
