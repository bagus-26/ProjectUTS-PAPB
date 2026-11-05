<?php

namespace App\Http\Controllers;

use App\Exceptions\ApiException;

abstract class Controller
{
    protected function belumDiimplementasikan(): never
    {
        throw new ApiException('Endpoint belum diimplementasikan.', 501);
    }
}
