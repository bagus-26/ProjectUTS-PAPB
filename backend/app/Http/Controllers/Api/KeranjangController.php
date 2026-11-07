<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Keranjang\IndexKeranjangRequest;
use App\Http\Requests\Keranjang\StoreKeranjangRequest;
use App\Http\Requests\Keranjang\UpdateKeranjangRequest;
use App\Services\KeranjangService;
use App\Support\ResponsApi;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class KeranjangController extends Controller
{
    public function __construct(
        private readonly KeranjangService $keranjangService,
    ) {}

    public function index(IndexKeranjangRequest $request): JsonResponse
    {
        $kurirId = $request->validated('kurir_id');

        $data = $this->keranjangService->ambil(
            $this->pelangganId($request),
            $kurirId === null ? null : (int) $kurirId,
        );

        return ResponsApi::sukses($data, 'Isi keranjang berhasil diambil');
    }

    public function store(StoreKeranjangRequest $request): JsonResponse
    {
        $item = $this->keranjangService->tambah(
            $this->pelangganId($request),
            $request->validated(),
        );

        return ResponsApi::sukses($item, 'Item berhasil ditambahkan ke keranjang', 201);
    }

    public function update(UpdateKeranjangRequest $request, string $id): JsonResponse
    {
        $item = $this->keranjangService->ubah(
            $this->pelangganId($request),
            (int) $id,
            (int) $request->validated('jumlah'),
        );

        return ResponsApi::sukses($item, 'Jumlah item berhasil diubah');
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $this->keranjangService->hapus($this->pelangganId($request), (int) $id);

        return ResponsApi::sukses(['id' => (int) $id], 'Item keranjang berhasil dihapus');
    }
}
