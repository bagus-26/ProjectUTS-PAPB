@extends('admin.layouts.app')

@section('judul', 'Kurir & Pembayaran')

@section('konten')
    <div class="page-head">
        <div>
            <h1>Data Referensi</h1>
            <p>Kurir, metode pembayaran, dan pelanggan yang dipakai oleh alur checkout Flutter.</p>
        </div>
    </div>

    <div class="stack">
        <section class="card">
            <div class="card-header">
                <div>
                    <h2 class="card-title">Kurir Toko</h2>
                    <p class="card-sub">Tarif ongkos kirim yang dikirim ke aplikasi melalui <code>GET /api/kurir</code>.</p>
                </div>
            </div>

            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>Nama</th>
                            <th>Wilayah</th>
                            <th>Tarif</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($kurir as $item)
                            <tr>
                                <td class="cell-main">{{ $item->nama }}</td>
                                <td>{{ $item->wilayah }}</td>
                                <td class="nowrap">{{ \App\Support\Uang::rupiah($item->tarif) }}</td>
                                <td>
                                    <span class="badge badge-{{ $item->aktif ? 'success' : 'neutral' }}">
                                        {{ $item->aktif ? 'Aktif' : 'Nonaktif' }}
                                    </span>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </section>

        <section class="card">
            <div class="card-header">
                <div>
                    <h2 class="card-title">Metode Pembayaran</h2>
                    <p class="card-sub">Metode simulasi yang tersedia pada layar checkout Flutter.</p>
                </div>
            </div>

            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>Kode</th>
                            <th>Nama</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($metode as $item)
                            <tr>
                                <td><code>{{ $item->kode }}</code></td>
                                <td class="cell-main">{{ $item->nama }}</td>
                                <td>
                                    <span class="badge badge-{{ $item->aktif ? 'success' : 'neutral' }}">
                                        {{ $item->aktif ? 'Aktif' : 'Nonaktif' }}
                                    </span>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </section>

        <section class="card">
            <div class="card-header">
                <div>
                    <h2 class="card-title">Pelanggan</h2>
                    <p class="card-sub">Pemilik token statis yang dipakai aplikasi Flutter saat mengakses API.</p>
                </div>
            </div>

            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Nama</th>
                            <th>Jumlah Pesanan</th>
                            <th>Dibuat</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($pelanggan as $item)
                            <tr>
                                <td>#{{ $item->id }}</td>
                                <td class="cell-main">{{ $item->nama }}</td>
                                <td>{{ $item->pesanan_count }}</td>
                                <td class="cell-sub">{{ $item->created_at?->format('d/m/Y H:i') }}</td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </section>
    </div>
@endsection
