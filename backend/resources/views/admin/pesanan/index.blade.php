@extends('admin.layouts.app')

@section('judul', 'Pesanan')

@section('konten')
    <div class="page-head">
        <div>
            <h1>Pesanan Masuk</h1>
            <p>ACC pembayaran dan jalankan pesanan sesuai state machine yang sama dengan API Flutter.</p>
        </div>
        <form class="toolbar" method="GET" action="{{ route('admin.pesanan.index') }}" style="margin: 0;">
            @if ($status !== '')
                <input type="hidden" name="status" value="{{ $status }}">
            @endif
            <input class="input-search" style="width: 240px;" type="search" name="cari" value="{{ $cari }}" placeholder="Cari nomor atau penerima...">
            <button class="btn btn-outline" type="submit">Cari</button>
        </form>
    </div>

    <div class="filters">
        <a class="filter-chip {{ $status === '' ? 'active' : '' }}"
           href="{{ route('admin.pesanan.index', array_filter(['cari' => $cari])) }}">
            Semua <span class="count">{{ $totalSemua }}</span>
        </a>
        @foreach (\App\Support\StatusPesanan::semua() as $s)
            <a class="filter-chip {{ $status === $s ? 'active' : '' }}"
               href="{{ route('admin.pesanan.index', array_filter(['status' => $s, 'cari' => $cari])) }}">
                {{ \App\Support\StatusPesanan::label($s) }}
                <span class="count">{{ $hitungStatus[$s] ?? 0 }}</span>
            </a>
        @endforeach
    </div>

    <section class="card">
        @if ($daftar->isEmpty())
            <div class="empty">
                <div class="empty-icon">🧾</div>
                <h3>Tidak ada pesanan</h3>
                <p>Belum ada pesanan yang cocok dengan filter saat ini.</p>
            </div>
        @else
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>Nomor / Penerima</th>
                            <th>Total</th>
                            <th>Pembayaran</th>
                            <th>Kurir</th>
                            <th>Status</th>
                            <th>Waktu</th>
                            <th class="text-right">Aksi</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($daftar as $pesanan)
                            @php
                                $aksiCepat = collect(\App\Support\StatusPesanan::transisi($pesanan->status))
                                    ->first(fn ($tujuan) => $tujuan !== \App\Support\StatusPesanan::DIBATALKAN);
                                $kelasAksi = $aksiCepat === \App\Support\StatusPesanan::DIBAYAR
                                    ? 'btn-success'
                                    : 'btn-primary';
                            @endphp
                            <tr>
                                <td>
                                    <div class="cell-main">{{ $pesanan->nomor_pesanan }}</div>
                                    <div class="cell-sub">{{ $pesanan->nama_penerima }}</div>
                                </td>
                                <td class="nowrap">{{ \App\Support\Uang::rupiah($pesanan->total) }}</td>
                                <td>
                                    <div>{{ $pesanan->metodePembayaran?->nama ?? '-' }}</div>
                                    <div class="cell-sub">Ongkir {{ \App\Support\Uang::rupiah($pesanan->ongkos_kirim) }}</div>
                                </td>
                                <td>
                                    <div>{{ $pesanan->kurir?->nama ?? '-' }}</div>
                                    <div class="cell-sub">{{ $pesanan->kurir?->wilayah }}</div>
                                </td>
                                <td>@include('admin.partials.status-badge', ['status' => $pesanan->status])</td>
                                <td class="cell-sub nowrap">{{ $pesanan->created_at?->format('d/m/Y H:i') }}</td>
                                <td class="text-right">
                                    <div class="actions" style="justify-content: flex-end;">
                                        @if ($aksiCepat)
                                            <form class="inline-form" method="POST" action="{{ route('admin.pesanan.status', $pesanan) }}">
                                                @csrf
                                                @method('PATCH')
                                                <input type="hidden" name="status" value="{{ $aksiCepat }}">
                                                <button class="btn btn-sm {{ $kelasAksi }}" type="submit">
                                                    {{ \App\Support\StatusPesanan::aksi($pesanan->status, $aksiCepat) }}
                                                </button>
                                            </form>
                                        @endif
                                        <a class="btn btn-sm btn-outline" href="{{ route('admin.pesanan.show', $pesanan) }}">Detail</a>
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            @include('admin.partials.pagination', ['paginator' => $daftar])
        @endif
    </section>
@endsection
