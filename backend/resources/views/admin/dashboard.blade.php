@extends('admin.layouts.app')

@section('judul', 'Dashboard')

@section('konten')
    <div class="page-head">
        <div>
            <h1>Ringkasan Toko</h1>
            <p>Pantau pesanan masuk, pendapatan, dan status operasional MakanYuk!.</p>
        </div>
        <div class="actions">
            <a class="btn btn-outline" href="{{ route('admin.toko.index') }}">Atur Jam Kerja</a>
            <a class="btn btn-primary" href="{{ route('admin.pesanan.index') }}">Lihat Pesanan</a>
        </div>
    </div>

    <div class="grid stats">
        <div class="stat">
            <div class="stat-icon">🧾</div>
            <div class="stat-label">Pesanan Hari Ini</div>
            <div class="stat-value">{{ number_format($statistik['pesanan_hari_ini'], 0, ',', '.') }}</div>
            <div class="stat-hint">{{ number_format($pesananAktif, 0, ',', '.') }} pesanan masih berjalan</div>
        </div>
        <div class="stat">
            <div class="stat-icon">⏳</div>
            <div class="stat-label">Perlu Konfirmasi</div>
            <div class="stat-value">{{ number_format($statistik['perlu_konfirmasi'], 0, ',', '.') }}</div>
            <div class="stat-hint">Menunggu ACC pembayaran admin</div>
        </div>
        <div class="stat">
            <div class="stat-icon">💰</div>
            <div class="stat-label">Pendapatan</div>
            <div class="stat-value" style="font-size: 22px;">{{ $pendapatan }}</div>
            <div class="stat-hint">Dari pesanan yang sudah dibayar</div>
        </div>
        <div class="stat">
            <div class="stat-icon">🍽️</div>
            <div class="stat-label">Produk Siap Jual</div>
            <div class="stat-value">{{ number_format($statistik['produk_aktif'], 0, ',', '.') }}</div>
            <div class="stat-hint">Tersedia dan stok lebih dari nol</div>
        </div>
    </div>

    <div class="grid two-col">
        <section class="card">
            <div class="card-header">
                <div>
                    <h2 class="card-title">Pesanan Terbaru</h2>
                    <p class="card-sub">Delapan pesanan terakhir dari aplikasi Flutter.</p>
                </div>
                <a class="btn btn-sm btn-outline" href="{{ route('admin.pesanan.index') }}">Semua</a>
            </div>

            @if ($pesananTerbaru->isEmpty())
                <div class="empty">
                    <div class="empty-icon">🧾</div>
                    <h3>Belum ada pesanan</h3>
                    <p>Pesanan yang dibuat dari aplikasi Flutter akan muncul di sini.</p>
                </div>
            @else
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>Pesanan</th>
                                <th>Total</th>
                                <th>Status</th>
                                <th>Waktu</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($pesananTerbaru as $pesanan)
                                <tr>
                                    <td>
                                        <div class="cell-main">{{ $pesanan->nomor_pesanan }}</div>
                                        <div class="cell-sub">{{ $pesanan->nama_penerima }}</div>
                                    </td>
                                    <td class="nowrap">{{ \App\Support\Uang::rupiah($pesanan->total) }}</td>
                                    <td>@include('admin.partials.status-badge', ['status' => $pesanan->status])</td>
                                    <td class="cell-sub nowrap">{{ $pesanan->created_at?->format('d/m/Y H:i') }}</td>
                                    <td class="text-right">
                                        <a class="btn btn-sm btn-outline" href="{{ route('admin.pesanan.show', $pesanan) }}">Detail</a>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @endif
        </section>

        <div class="stack">
            <section class="card">
                <div class="card-header">
                    <div>
                        <h2 class="card-title">Status Toko</h2>
                        <p class="card-sub">Berlaku langsung pada validasi checkout Flutter.</p>
                    </div>
                </div>

                <div class="store-hero {{ $statusToko['buka'] ? '' : 'closed' }}">
                    <span class="pill"><span class="status-dot"></span>{{ $statusToko['buka'] ? 'Sedang Buka' : 'Sedang Tutup' }}</span>
                    <h2>{{ $statusToko['buka'] ? 'Toko siap menerima pesanan' : 'Checkout sedang ditolak' }}</h2>
                    <p>{{ $statusToko['pesan'] }}</p>
                    <div class="store-meta">
                        <span class="pill">Jadwal {{ $statusToko['jam_buka'] }}–{{ $statusToko['jam_tutup'] }} WIB</span>
                        <span class="pill">Penutupan manual: {{ $statusToko['tutup_manual'] ? 'Ya' : 'Tidak' }}</span>
                    </div>
                </div>

                <div class="actions" style="margin-top: 14px;">
                    <a class="btn btn-outline btn-block" href="{{ route('admin.toko.index') }}">Kelola Jam Kerja</a>
                </div>
            </section>

            <section class="card">
                <div class="card-header">
                    <div>
                        <h2 class="card-title">Sebaran Status</h2>
                        <p class="card-sub">Jumlah pesanan per status.</p>
                    </div>
                </div>

                <div class="status-list">
                    @foreach (\App\Support\StatusPesanan::semua() as $status)
                        <div class="status-row">
                            <div class="left">
                                @include('admin.partials.status-badge', ['status' => $status])
                            </div>
                            <span class="status-count">{{ number_format($hitungStatus[$status] ?? 0, 0, ',', '.') }}</span>
                        </div>
                    @endforeach
                </div>
            </section>
        </div>
    </div>
@endsection
