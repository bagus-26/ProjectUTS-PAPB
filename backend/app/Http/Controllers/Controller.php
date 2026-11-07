<?php

namespace App\Http\Controllers;

use App\Exceptions\ApiException;
use Illuminate\Http\Request;

abstract class Controller
{
    protected function pelangganId(Request $request): int
    {
        return (int) $request->attributes->get('pelanggan_id');
    }

    protected function belumDiimplementasikan(): never
    {
        throw new ApiException('Endpoint belum diimplementasikan.', 501);
    }
}
