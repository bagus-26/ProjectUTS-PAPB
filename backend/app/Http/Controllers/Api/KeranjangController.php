<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;

class KeranjangController extends Controller
{
    public function index(): JsonResponse
    {
        $this->belumDiimplementasikan();
    }

    public function store(): JsonResponse
    {
        $this->belumDiimplementasikan();
    }

    public function update(string $id): JsonResponse
    {
        $this->belumDiimplementasikan();
    }

    public function destroy(string $id): JsonResponse
    {
        $this->belumDiimplementasikan();
    }
}
