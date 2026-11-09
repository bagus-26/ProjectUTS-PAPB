<?php

namespace App\Http\Controllers\Admin;

use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use App\Services\PesananService;
use App\Support\StatusPesanan;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class PesananController extends Controller
{
    public function index(Request $request): View
    {
        $status = (string) $request->query('status', '');
        $cari = trim((string) $request->query('cari', ''));

        if (! in_array($status, StatusPesanan::semua(), true)) {
            $status = '';
        }

        $daftar = Pesanan::query()
            ->with(['kurir', 'metodePembayaran'])
            ->when($status !== '', fn ($query) => $query->where('status', $status))
            ->when($cari !== '', function ($query) use ($cari): void {
                $query->where(function ($inner) use ($cari): void {
                    $inner->where('nomor_pesanan', 'like', '%'.$cari.'%')
                        ->orWhere('nama_penerima', 'like', '%'.$cari.'%');
                });
            })
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->paginate(15)
            ->withQueryString();

        $hitungStatus = Pesanan::query()
            ->selectRaw('status, count(*) as jumlah')
            ->groupBy('status')
            ->pluck('jumlah', 'status')
            ->all();

        return view('admin.pesanan.index', [
            'daftar' => $daftar,
            'status' => $status,
            'cari' => $cari,
            'hitungStatus' => $hitungStatus,
            'totalSemua' => Pesanan::query()->count(),
        ]);
    }

    public function show(Pesanan $pesanan): View
    {
        $pesanan->load(['pelanggan', 'kurir', 'metodePembayaran', 'detail']);

        return view('admin.pesanan.show', [
            'pesanan' => $pesanan,
            'transisi' => StatusPesanan::transisi($pesanan->status),
        ]);
    }

    public function ubahStatus(Request $request, Pesanan $pesanan, PesananService $pesananService): RedirectResponse
    {
        $data = $request->validate([
            'status' => ['required', 'string', Rule::in(StatusPesanan::semua())],
        ]);

        try {
            $pesananService->ubahStatus($pesanan->id, $data['status']);
        } catch (ApiException $exception) {
            return redirect()->back()->with('galat', $exception->getMessage());
        }

        return redirect()->back()->with(
            'sukses',
            sprintf(
                'Status pesanan %s berhasil diubah menjadi %s.',
                $pesanan->nomor_pesanan,
                StatusPesanan::label($data['status']),
            ),
        );
    }
}
