<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class AuthController extends Controller
{
    public function tampilkanLogin(): View|RedirectResponse
    {
        if (Auth::check()) {
            return redirect()->route('admin.dashboard');
        }

        return view('admin.auth.login');
    }

    public function login(Request $request): RedirectResponse
    {
        $kredensial = $request->validate([
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
        ]);

        $berhasil = Auth::attempt([
            'email' => $kredensial['email'],
            'password' => $kredensial['password'],
            'is_admin' => true,
        ], $request->boolean('ingat'));

        if (! $berhasil) {
            throw ValidationException::withMessages([
                'email' => 'Email atau kata sandi salah, atau akun ini bukan admin.',
            ]);
        }

        $request->session()->regenerate();

        return redirect()->intended(route('admin.dashboard'))
            ->with('sukses', 'Selamat datang kembali, '.Auth::user()->name.'.');
    }

    public function logout(Request $request): RedirectResponse
    {
        Auth::logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login')
            ->with('sukses', 'Anda telah keluar dari panel admin.');
    }
}
