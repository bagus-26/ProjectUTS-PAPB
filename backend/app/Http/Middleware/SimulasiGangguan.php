<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use RuntimeException;
use Symfony\Component\HttpFoundation\Response;

class SimulasiGangguan
{
    /**
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        if (config('app.env') !== 'local') {
            return $next($request);
        }

        $detik = (int) env('SIMULASI_LAMBAT_DETIK', 0);

        if ($detik > 0) {
            sleep($detik);
        }

        $galat500 = filter_var(env('SIMULASI_GALAT_500', false), FILTER_VALIDATE_BOOLEAN);

        if ($galat500 && $request->isMethod('GET') && $request->is('api/produk')) {
            throw new RuntimeException('Gangguan simulasi 500.');
        }

        return $next($request);
    }
}
