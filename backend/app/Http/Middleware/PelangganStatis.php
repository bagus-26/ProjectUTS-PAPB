<?php

namespace App\Http\Middleware;

use App\Support\ResponsApi;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class PelangganStatis
{
    /**
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->bearerToken();

        if ($token === null || $token === '') {
            return ResponsApi::gagal('Akses ditolak. Token pelanggan tidak valid.', 401);
        }

        $pelanggan = DB::table('pelanggan')->where('token', $token)->first();

        if ($pelanggan === null) {
            return ResponsApi::gagal('Akses ditolak. Token pelanggan tidak valid.', 401);
        }

        $request->attributes->set('pelanggan_id', (int) $pelanggan->id);
        $request->attributes->set('pelanggan', $pelanggan);

        return $next($request);
    }
}
