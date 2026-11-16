@extends('admin.layouts.app')

@section('judul', 'Promo & Voucher')

@section('konten')
    <div class="page-head">
        <div>
            <h1>Kelola Promo &amp; Voucher</h1>
            <p>Promo aktif langsung muncul di halaman Promo &amp; Tukar Poin aplikasi pelanggan.</p>
        </div>
        <a class="btn btn-primary" href="{{ route('admin.promo.create') }}">+ Tambah Promo</a>
    </div>

    <div class="grid stats" style="grid-template-columns: repeat(3, minmax(0, 1fr));">
        <div class="stat">
            <div class="stat-icon">🎟️</div>
            <div class="stat-label">Promo Aktif</div>
            <div class="stat-value">{{ number_format($totalAktif, 0, ',', '.') }}</div>
            <div class="stat-hint">Tampil di aplikasi Flutter</div>
        </div>
        <div class="stat">
            <div class="stat-icon">📦</div>
            <div class="stat-label">Voucher Diklaim</div>
            <div class="stat-value">{{ number_format($totalVoucher, 0, ',', '.') }}</div>
            <div class="stat-hint">Total voucher milik pelanggan</div>
        </div>
        <div class="stat">
            <div class="stat-icon">💡</div>
            <div class="stat-label">Cara Kerja</div>
            <div class="stat-value" style="font-size: 15px;">Kode &amp; Poin</div>
            <div class="stat-hint">Isi kode untuk klaim, isi poin untuk tukar</div>
        </div>
    </div>

    <form class="toolbar" method="GET" action="{{ route('admin.promo.index') }}">
        <div class="grow">
            <input class="input-search" type="search" name="cari" value="{{ $cari }}" placeholder="Cari kode atau judul promo...">
        </div>
        <button class="btn btn-outline" type="submit">Cari</button>
        @if ($cari !== '')
            <a class="btn btn-ghost" href="{{ route('admin.promo.index') }}">Reset</a>
        @endif
    </form>

    <section class="card">
        @if ($daftar->isEmpty())
            <div class="empty">
                <div class="empty-icon">🎟️</div>
                <h3>Belum ada promo</h3>
                <p>Buat promo pertama agar pelanggan bisa klaim kode atau tukar poin.</p>
                <a class="btn btn-primary" href="{{ route('admin.promo.create') }}">Tambah Promo</a>
            </div>
        @else
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>Promo</th>
                            <th>Kode</th>
                            <th>Diskon</th>
                            <th>Min. Belanja</th>
                            <th>Poin</th>
                            <th>Voucher</th>
                            <th>Status</th>
                            <th class="text-right">Aksi</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($daftar as $promo)
                            <tr>
                                <td>
                                    <div class="cell-main">{{ $promo->title }}</div>
                                    <div class="cell-sub">{{ \Illuminate\Support\Str::limit($promo->description ?? 'Tanpa deskripsi', 70) }}</div>
                                </td>
                                <td><span class="promo-code">{{ $promo->code }}</span></td>
                                <td class="promo-value">{{ $promo->labelDiskon() }}</td>
                                <td class="nowrap">{{ \App\Support\Uang::rupiah($promo->min_order) }}</td>
                                <td>
                                    @if ($promo->point_cost > 0)
                                        <span class="promo-point">{{ number_format($promo->point_cost, 0, ',', '.') }} poin</span>
                                    @else
                                        <span class="muted">Gratis klaim</span>
                                    @endif
                                </td>
                                <td>{{ number_format($promo->vouchers_count, 0, ',', '.') }}</td>
                                <td>
                                    <span class="badge badge-{{ $promo->is_active ? 'success' : 'neutral' }}">
                                        {{ $promo->is_active ? 'Aktif' : 'Nonaktif' }}
                                    </span>
                                </td>
                                <td class="text-right">
                                    <div class="actions" style="justify-content: flex-end;">
                                        <a class="btn btn-sm btn-outline" href="{{ route('admin.promo.edit', $promo) }}">Ubah</a>
                                        <form class="inline-form" method="POST" action="{{ route('admin.promo.toggle', $promo) }}">
                                            @csrf
                                            @method('PATCH')
                                            <button class="btn btn-sm {{ $promo->is_active ? 'btn-ghost' : 'btn-success' }}" type="submit">
                                                {{ $promo->is_active ? 'Nonaktifkan' : 'Aktifkan' }}
                                            </button>
                                        </form>
                                        <form class="inline-form" method="POST" action="{{ route('admin.promo.destroy', $promo) }}"
                                              data-konfirmasi="Hapus promo &quot;{{ $promo->title }}&quot;?">
                                            @csrf
                                            @method('DELETE')
                                            <button class="btn btn-sm btn-danger" type="submit">Hapus</button>
                                        </form>
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
