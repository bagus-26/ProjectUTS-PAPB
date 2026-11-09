<?php

namespace App\Providers;

use App\Models\Pesanan;
use App\Support\StatusPesanan;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        View::composer('admin.layouts.app', function ($view): void {
            if (! Auth::check()) {
                return;
            }

            $view->with(
                'jumlahPerluKonfirmasi',
                Pesanan::query()->where('status', StatusPesanan::MENUNGGU_KONFIRMASI)->count(),
            );
        });
    }
}
