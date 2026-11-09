@extends('admin.layouts.guest')

@section('judul', 'Masuk Admin')

@section('konten')
    <div class="login-card">
        <div class="login-brand">
            <span class="brand-mark">MY</span>
            <div>
                <strong>MakanYuk!</strong>
                <div class="small muted">Panel Admin · Kelompok 1</div>
            </div>
        </div>

        <h1>Masuk Panel Admin</h1>
        <p>Kelola pesanan, produk, dan jam operasional toko yang tersinkron dengan aplikasi Flutter.</p>

        @if ($errors->any())
            <div class="alert alert-danger">
                <strong>Gagal masuk.</strong>
                <ul>
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        @if (session('sukses'))
            <div class="alert alert-success">{{ session('sukses') }}</div>
        @endif

        <form method="POST" action="{{ route('admin.login.proses') }}">
            @csrf

            <div class="field">
                <label for="email">Email admin</label>
                <input id="email" type="email" name="email" value="{{ old('email') }}" required autofocus autocomplete="username">
            </div>

            <div class="field">
                <label for="password">Kata sandi</label>
                <input id="password" type="password" name="password" required autocomplete="current-password">
            </div>

            <label class="check" style="margin-bottom: 18px;">
                <input type="checkbox" name="ingat" value="1">
                <span>Ingat saya di perangkat ini</span>
            </label>

            <button class="btn btn-primary btn-block" type="submit">Masuk</button>
        </form>

        <p class="login-foot">Akun admin dibuat oleh <code>AdminSeeder</code>.</p>
    </div>
@endsection
