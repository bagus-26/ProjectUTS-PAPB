<?php

use App\Exceptions\ApiException;
use App\Http\Middleware\ForceJson;
use App\Http\Middleware\PelangganStatis;
use App\Http\Middleware\SimulasiGangguan;
use App\Support\ResponsApi;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'force.json' => ForceJson::class,
            'pelanggan.statis' => PelangganStatis::class,
            'simulasi.gangguan' => SimulasiGangguan::class,
        ]);

        $middleware->api(prepend: [
            ForceJson::class,
            SimulasiGangguan::class,
        ]);

        $middleware->api(append: [
            PelangganStatis::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->dontReport(ApiException::class);

        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );

        $exceptions->render(function (ApiException $e, Request $request): ?JsonResponse {
            if (! $request->is('api/*')) {
                return null;
            }

            return $e->render();
        });

        $exceptions->render(function (ValidationException $e, Request $request): ?JsonResponse {
            if (! $request->is('api/*')) {
                return null;
            }

            return ResponsApi::gagal('Data yang dikirim tidak lengkap', 422, null, $e->errors());
        });

        $exceptions->render(function (AuthenticationException $e, Request $request): ?JsonResponse {
            if (! $request->is('api/*')) {
                return null;
            }

            return ResponsApi::gagal('Akses ditolak.', 401);
        });

        $exceptions->render(function (ModelNotFoundException $e, Request $request): ?JsonResponse {
            if (! $request->is('api/*')) {
                return null;
            }

            return ResponsApi::gagal('Data tidak ditemukan.', 404);
        });

        $exceptions->render(function (NotFoundHttpException $e, Request $request): ?JsonResponse {
            if (! $request->is('api/*')) {
                return null;
            }

            return ResponsApi::gagal('Data tidak ditemukan.', 404);
        });

        $exceptions->render(function (HttpExceptionInterface $e, Request $request): ?JsonResponse {
            if (! $request->is('api/*')) {
                return null;
            }

            $kode = $e->getStatusCode();
            $pesan = match (true) {
                $kode === 409 => $e->getMessage() !== '' ? $e->getMessage() : 'Permintaan bertentangan dengan keadaan server.',
                $kode >= 500 => 'Terjadi kesalahan pada server.',
                default => 'Permintaan tidak dapat diproses.',
            };

            return ResponsApi::gagal($pesan, $kode >= 500 ? 500 : $kode);
        });

        $exceptions->render(function (Throwable $e, Request $request): ?JsonResponse {
            if (! $request->is('api/*')) {
                return null;
            }

            return ResponsApi::gagal('Terjadi kesalahan pada server.', 500);
        });
    })->create();
