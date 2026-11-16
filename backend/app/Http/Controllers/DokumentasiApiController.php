<?php

namespace App\Http\Controllers;

use Illuminate\Contracts\View\View;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class DokumentasiApiController extends Controller
{
    public function index(): View
    {
        return view('dokumentasi-api');
    }

    public function spesifikasi(): BinaryFileResponse
    {
        return response()->file(
            resource_path('openapi/openapi.json'),
            [
                'Content-Type' => 'application/json; charset=UTF-8',
                'Cache-Control' => 'no-cache, no-store, must-revalidate',
            ],
        );
    }
}
