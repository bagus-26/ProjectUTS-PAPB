<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Promo;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class PromoController extends Controller
{
    public function index(Request $request): View
    {
        $cari = trim((string) $request->query('cari', ''));

        $daftar = Promo::query()
            ->when($cari !== '', function ($query) use ($cari): void {
                $query->where(function ($inner) use ($cari): void {
                    $inner->where('code', 'like', '%'.$cari.'%')
                        ->orWhere('title', 'like', '%'.$cari.'%');
                });
            })
            ->withCount('vouchers')
            ->orderByDesc('is_active')
            ->orderByDesc('id')
            ->paginate(12)
            ->withQueryString();

        return view('admin.promo.index', [
            'daftar' => $daftar,
            'cari' => $cari,
            'totalAktif' => Promo::query()->where('is_active', true)->count(),
            'totalVoucher' => Promo::query()->withCount('vouchers')->get()->sum('vouchers_count'),
        ]);
    }

    public function create(): View
    {
        return view('admin.promo.form', [
            'promo' => new Promo(['discount_type' => 'fixed', 'is_active' => true]),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $this->validasi($request);
        $promo = Promo::query()->create($data);

        return redirect()->route('admin.promo.index')->with(
            'sukses',
            'Promo "'.$promo->title.'" berhasil ditambahkan.',
        );
    }

    public function edit(Promo $promo): View
    {
        return view('admin.promo.form', [
            'promo' => $promo,
        ]);
    }

    public function update(Request $request, Promo $promo): RedirectResponse
    {
        $promo->update($this->validasi($request, $promo));

        return redirect()->route('admin.promo.index')->with(
            'sukses',
            'Promo "'.$promo->title.'" berhasil diperbarui.',
        );
    }

    public function destroy(Promo $promo): RedirectResponse
    {
        if ($promo->vouchers()->exists()) {
            return redirect()->back()->with(
                'galat',
                'Promo sudah memiliki voucher pelanggan. Nonaktifkan saja agar riwayat tetap tersimpan.',
            );
        }

        $promo->delete();

        return redirect()->route('admin.promo.index')->with(
            'sukses',
            'Promo berhasil dihapus.',
        );
    }

    public function toggle(Promo $promo): RedirectResponse
    {
        $promo->update(['is_active' => ! $promo->is_active]);

        return redirect()->back()->with(
            'sukses',
            sprintf(
                'Promo "%s" sekarang %s.',
                $promo->title,
                $promo->is_active ? 'aktif' : 'nonaktif',
            ),
        );
    }

    /**
     * @return array<string, mixed>
     */
    private function validasi(Request $request, ?Promo $promo = null): array
    {
        $data = $request->validate([
            'code' => [
                'required',
                'string',
                'max:40',
                Rule::unique('promos', 'code')->ignore($promo?->id),
            ],
            'title' => ['required', 'string', 'max:120'],
            'description' => ['nullable', 'string'],
            'discount_type' => ['required', Rule::in(['fixed', 'percent'])],
            'discount_value' => [
                'required',
                'integer',
                'min:1',
                $request->input('discount_type') === 'percent' ? 'max:100' : 'max:100000000',
            ],
            'min_order' => ['required', 'integer', 'min:0', 'max:4294967295'],
            'point_cost' => ['required', 'integer', 'min:0', 'max:4294967295'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $data['code'] = strtoupper(trim($data['code']));
        $data['is_active'] = $request->boolean('is_active');

        return $data;
    }
}
