<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;

class PesananController extends Controller
{
    public function index(): JsonResponse
    {
        $this->belumDiimplementasikan();
    }

    public function show(string $id): JsonResponse
    {
        $this->belumDiimplementasikan();
    }

    public function ubahStatus(string $id): JsonResponse
    {
        $this->belumDiimplementasikan();
    }
}
