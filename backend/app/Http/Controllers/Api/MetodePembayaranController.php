<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;

class MetodePembayaranController extends Controller
{
    public function index(): JsonResponse
    {
        $this->belumDiimplementasikan();
    }
}
