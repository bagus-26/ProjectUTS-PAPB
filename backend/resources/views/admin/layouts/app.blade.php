<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('judul', 'Dashboard') · MakanYuk! Admin</title>
    <link rel="stylesheet" href="{{ asset('css/admin.css') }}">
</head>
<body>
    <div class="sidebar-backdrop" data-tutup-sidebar></div>

    <div class="admin-shell">
        <aside class="sidebar">
            <div class="brand">
                <span class="brand-mark">MY</span>
                <div>
                    <strong>MakanYuk!</strong>
                    <small>Panel Admin</small>
                </div>
            </div>

            <nav class="nav">
                <span class="nav-section">Ringkasan</span>
                <a class="nav-link {{ request()->routeIs('admin.dashboard') ? 'active' : '' }}" href="{{ route('admin.dashboard') }}">
                    <span class="nav-icon">▦</span> Dashboard
                </a>

                <span class="nav-section">Operasional</span>
                <a class="nav-link {{ request()->routeIs('admin.pesanan.*') ? 'active' : '' }}" href="{{ route('admin.pesanan.index') }}">
                    <span class="nav-icon">🧾</span> Pesanan
                    @if (($jumlahPerluKonfirmasi ?? 0) > 0)
                        <span class="nav-badge">{{ $jumlahPerluKonfirmasi }}</span>
                    @endif
                </a>
                <a class="nav-link {{ request()->routeIs('admin.produk.*') ? 'active' : '' }}" href="{{ route('admin.produk.index') }}">
                    <span class="nav-icon">🍽️</span> Kelola Produk
                </a>
                <a class="nav-link {{ request()->routeIs('admin.toko.*') ? 'active' : '' }}" href="{{ route('admin.toko.index') }}">
                    <span class="nav-icon">⏱️</span> Jam Kerja
                </a>

                <span class="nav-section">Referensi</span>
                <a class="nav-link {{ request()->routeIs('admin.referensi.*') ? 'active' : '' }}" href="{{ route('admin.referensi.index') }}">
                    <span class="nav-icon">📚</span> Kurir &amp; Pembayaran
                </a>
            </nav>

            <div class="sidebar-footer">
                <div class="user-chip">
                    <img
                        class="avatar"
                        src="{{ asset('images/admin-profile.png') }}"
                        alt="Foto profil {{ auth()->user()->name }}"
                    >
                    <div>
                        <strong>{{ auth()->user()->name }}</strong>
                        <small>{{ auth()->user()->email }}</small>
                    </div>
                </div>
                <form method="POST" action="{{ route('admin.logout') }}">
                    @csrf
                    <button class="btn btn-outline btn-block" type="submit">Keluar</button>
                </form>
            </div>
        </aside>

        <div class="main">
            <header class="topbar">
                <button class="icon-btn menu-toggle" type="button" data-buka-sidebar aria-label="Buka menu">☰</button>
                <div class="topbar-title">
                    <span class="eyebrow">Panel Admin</span>
                    <strong>@yield('judul', 'Dashboard')</strong>
                </div>
                <div class="topbar-actions">
                    <span class="live-dot"></span>
                    <span>Data tersinkron dengan aplikasi Flutter</span>
                </div>
            </header>

            <main class="content">
                @if (session('sukses'))
                    <div class="alert alert-success">{{ session('sukses') }}</div>
                @endif

                @if (session('galat'))
                    <div class="alert alert-danger">{{ session('galat') }}</div>
                @endif

                @if ($errors->any())
                    <div class="alert alert-danger">
                        <strong>Periksa kembali data yang diisi.</strong>
                        <ul>
                            @foreach ($errors->all() as $error)
                                <li>{{ $error }}</li>
                            @endforeach
                        </ul>
                    </div>
                @endif

                @yield('konten')
            </main>
        </div>
    </div>

    <script src="{{ asset('js/admin.js') }}"></script>
</body>
</html>
