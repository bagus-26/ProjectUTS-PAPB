@extends('admin.layouts.app')

@section('judul', 'Detail Pesanan')

@section('konten')
    @php
        $langkah = match ($pesanan->status) {
            \App\Support\StatusPesanan::MENUNGGU_PEMBAYARAN, \App\Support\StatusPesanan::MENUNGGU_KONFIRMASI => 0,
            \App\Support\StatusPesanan::DIBAYAR, \App\Support\StatusPesanan::DIPROSES => 1,
            \App\Support\StatusPesanan::DIKIRIM => 2,
            \App\Support\StatusPesanan::SELESAI => 3,
            default => 0,
        };
        $labelLangkah = ['Dibuat', 'Diracik', 'Dikirim', 'Selesai'];
    @endphp

    <div class="page-head">
        <div>
            <div class="actions" style="margin-bottom: 6px;">
                <a class="btn btn-sm btn-outline" href="{{ route('admin.pesanan.index') }}">← Kembali</a>
            </div>
            <h1>{{ $pesanan->nomor_pesanan }}</h1>
            <p>
                Dibuat {{ $pesanan->created_at?->format('d/m/Y H:i') }} WIB ·
                @include('admin.partials.status-badge', ['status' => $pesanan->status])
            </p>
        </div>
    </div>

    @if ($pesanan->status !== \App\Support\StatusPesanan::DIBATALKAN)
        <section class="card mb-16">
            <div class="card-header">
                <div>
                    <h2 class="card-title">Progres Pesanan</h2>
                    <p class="card-sub">Status mengikuti state machine API yang sama dengan aplikasi Flutter.</p>
                </div>
            </div>
            <div class="steps">
                @foreach ($labelLangkah as $index => $label)
                    @php
                        $selesai = $index < $langkah || $pesanan->status === \App\Support\StatusPesanan::SELESAI;
                        $aktif = $index === $langkah && $pesanan->status !== \App\Support\StatusPesanan::SELESAI;
                        $kelas = $selesai ? 'done' : ($aktif ? 'active' : '');
                    @endphp
                    <div class="step {{ $kelas }}">
                        <div class="bar"></div>
                        {{ $label }}
                    </div>
                @endforeach
            </div>
        </section>
    @endif

    <div class="grid detail-grid">
        <div class="stack">
            <section class="card">
                <div class="card-header">
                    <div>
                        <h2 class="card-title">Aksi Admin</h2>
                        <p class="card-sub">Hanya transisi status yang sah yang ditampilkan.</p>
                    </div>
                </div>

                @if (empty($transisi))
                    <div class="alert alert-info mb-0">
                        Pesanan berstatus <strong>{{ \App\Support\StatusPesanan::label($pesanan->status) }}</strong>.
                        Tidak ada perubahan status lanjutan yang dapat dilakukan.
                    </div>
                @else
                    <div class="actions">
                        @foreach ($transisi as $tujuan)
                            @php
                                $kelas = match ($tujuan) {
                                    \App\Support\StatusPesanan::DIBATALKAN => 'btn-danger',
                                    \App\Support\StatusPesanan::SELESAI, \App\Support\StatusPesanan::DIBAYAR => 'btn-success',
                                    default => 'btn-primary',
                                };
                                $konfirmasi = $tujuan === \App\Support\StatusPesanan::DIBATALKAN
                                    ? 'Batalkan pesanan ini? Stok produk akan dikembalikan otomatis.'
                                    : null;
                            @endphp
                            <form class="inline-form" method="POST" action="{{ route('admin.pesanan.status', $pesanan) }}"
                                  @if ($konfirmasi) data-konfirmasi="{{ $konfirmasi }}" @endif>
                                @csrf
                                @method('PATCH')
                                <input type="hidden" name="status" value="{{ $tujuan }}">
                                <button class="btn {{ $kelas }}" type="submit">
                                    {{ \App\Support\StatusPesanan::aksi($pesanan->status, $tujuan) }}
                                </button>
                            </form>
                        @endforeach
                    </div>
                @endif
            </section>

            <section class="card">
                <div class="card-header">
                    <div>
                        <h2 class="card-title">Rincian Menu</h2>
                        <p class="card-sub">{{ $pesanan->detail->count() }} baris menu dengan harga saat pembelian.</p>
                    </div>
                </div>

                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>Menu</th>
                                <th>Jumlah</th>
                                <th>Harga</th>
                                <th class="text-right">Subtotal</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($pesanan->detail as $item)
                                <tr>
                                    <td>
                                        <div class="cell-main">{{ $item->nama_produk }}</div>
                                        @if ($item->varian_nama || $item->tingkat_pedas)
                                            <div class="cell-sub">
                                                {{ collect([$item->varian_nama, $item->tingkat_pedas ? str_replace('_', ' ', $item->tingkat_pedas) : null])->filter()->implode(' · ') }}
                                            </div>
                                        @endif
                                        @if ($item->catatan)
                                            <div class="item-note">Catatan: {{ $item->catatan }}</div>
                                        @endif
                                    </td>
                                    <td>{{ $item->jumlah }}x</td>
                                    <td class="nowrap">{{ \App\Support\Uang::rupiah($item->harga_satuan) }}</td>
                                    <td class="text-right nowrap">{{ \App\Support\Uang::rupiah($item->subtotal) }}</td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>

                <div class="divider"></div>

                <div class="total-box">
                    <div class="total-row">
                        <span class="muted">Subtotal</span>
                        <span>{{ \App\Support\Uang::rupiah($pesanan->subtotal) }}</span>
                    </div>
                    <div class="total-row">
                        <span class="muted">Ongkos kirim</span>
                        <span>{{ \App\Support\Uang::rupiah($pesanan->ongkos_kirim) }}</span>
                    </div>
                    <div class="total-row big">
                        <span>Total</span>
                        <span>{{ \App\Support\Uang::rupiah($pesanan->total) }}</span>
                    </div>
                </div>
            </section>
        </div>

        <div class="stack">
            <section class="card">
                <div class="card-header">
                    <div>
                        <h2 class="card-title">Penerima</h2>
                    </div>
                </div>
                <div class="info-list">
                    <div class="info-row"><span>Nama</span><strong>{{ $pesanan->nama_penerima }}</strong></div>
                    <div class="info-row"><span>Pelanggan</span><strong>{{ $pesanan->pelanggan?->nama ?? '-' }}</strong></div>
                    <div class="info-row"><span>Alamat</span><strong>{{ $pesanan->alamat_penerima }}</strong></div>
                </div>
            </section>

            <section class="card">
                <div class="card-header">
                    <div>
                        <h2 class="card-title">Pembayaran &amp; Pengiriman</h2>
                    </div>
                </div>
                <div class="info-list">
                    <div class="info-row"><span>Metode</span><strong>{{ $pesanan->metodePembayaran?->nama ?? '-' }}</strong></div>
                    <div class="info-row"><span>Kode</span><strong>{{ $pesanan->metodePembayaran?->kode ?? '-' }}</strong></div>
                    <div class="info-row"><span>Kurir</span><strong>{{ $pesanan->kurir?->nama ?? '-' }}</strong></div>
                    <div class="info-row"><span>Wilayah</span><strong>{{ $pesanan->kurir?->wilayah ?? '-' }}</strong></div>
                    <div class="info-row"><span>Ongkos kirim</span><strong>{{ \App\Support\Uang::rupiah($pesanan->ongkos_kirim) }}</strong></div>
                    @if ($pesanan->xendit_invoice_id)
                        <div class="info-row"><span>Invoice Xendit</span><strong>{{ $pesanan->xendit_invoice_id }}</strong></div>
                        <div class="info-row"><span>Status Xendit</span><strong>{{ $pesanan->xendit_status ?? '-' }}</strong></div>
                        @if ($pesanan->xendit_invoice_url)
                            <div class="info-row"><span>Halaman bayar</span><strong><a href="{{ $pesanan->xendit_invoice_url }}" target="_blank" rel="noopener">Buka</a></strong></div>
                        @endif
                    @endif
                </div>
            </section>
        </div>
    </div>
@endsection
