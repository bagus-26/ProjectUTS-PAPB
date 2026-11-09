@extends('admin.layouts.app')

@section('judul', 'Kelola Produk')

@section('konten')
    <div class="page-head">
        <div>
            <h1>Kelola Produk</h1>
            <p>CRUD menu yang sama dengan halaman Kelola Produk di aplikasi Flutter.</p>
        </div>
        <a class="btn btn-primary" href="{{ route('admin.produk.create') }}">+ Tambah Produk</a>
    </div>

    <form class="toolbar" method="GET" action="{{ route('admin.produk.index') }}">
        <div class="grow">
            <input class="input-search" type="search" name="cari" value="{{ $cari }}" placeholder="Cari nama menu...">
        </div>
        <div class="field" style="min-width: 170px;">
            <select name="kategori">
                <option value="">Semua kategori</option>
                @foreach ($kategoriTersedia as $item)
                    <option value="{{ $item }}" @selected($kategori === $item)>{{ $item }}</option>
                @endforeach
            </select>
        </div>
        <button class="btn btn-outline" type="submit">Terapkan</button>
        @if ($cari !== '' || $kategori !== '')
            <a class="btn btn-ghost" href="{{ route('admin.produk.index') }}">Reset</a>
        @endif
    </form>

    <section class="card">
        @if ($daftar->isEmpty())
            <div class="empty">
                <div class="empty-icon">🍽️</div>
                <h3>Belum ada produk</h3>
                <p>Tambahkan menu baru agar muncul di katalog aplikasi Flutter.</p>
                <a class="btn btn-primary" href="{{ route('admin.produk.create') }}">Tambah Produk</a>
            </div>
        @else
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>Menu</th>
                            <th>Kategori</th>
                            <th>Harga</th>
                            <th>Stok</th>
                            <th>Status</th>
                            <th>Varian</th>
                            <th class="text-right">Aksi</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($daftar as $produk)
                            @php
                                $statusProduk = ! $produk->tersedia
                                    ? ['Nonaktif', 'danger']
                                    : ($produk->stok <= 0 ? ['Habis', 'warning'] : ['Tersedia', 'success']);
                            @endphp
                            <tr>
                                <td>
                                    <div class="cell-main">{{ $produk->nama }}</div>
                                    <div class="cell-sub">
                                        {{ $produk->bisa_pedas ? 'Bisa pedas' : 'Tidak pedas' }} ·
                                        persiapan {{ $produk->waktu_persiapan_menit }} menit
                                    </div>
                                </td>
                                <td>{{ $produk->kategori }}</td>
                                <td class="nowrap">{{ \App\Support\Uang::rupiah($produk->harga) }}</td>
                                <td>{{ $produk->stok }}</td>
                                <td><span class="badge badge-{{ $statusProduk[1] }}">{{ $statusProduk[0] }}</span></td>
                                <td class="cell-sub">
                                    {{ $produk->varian->map(fn ($varian) => $varian->nama)->implode(', ') ?: '-' }}
                                </td>
                                <td class="text-right">
                                    <div class="actions" style="justify-content: flex-end;">
                                        <a class="btn btn-sm btn-outline" href="{{ route('admin.produk.edit', $produk) }}">Ubah</a>
                                        <form class="inline-form" method="POST" action="{{ route('admin.produk.destroy', $produk) }}"
                                              data-konfirmasi="Hapus menu &quot;{{ $produk->nama }}&quot;? Tindakan ini tidak dapat dibatalkan.">
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
