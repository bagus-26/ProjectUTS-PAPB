<?php

namespace App\Support;

class Uang
{
    public static function rupiah(int|float|string|null $nilai): string
    {
        return 'Rp '.number_format((int) $nilai, 0, ',', '.');
    }
}
