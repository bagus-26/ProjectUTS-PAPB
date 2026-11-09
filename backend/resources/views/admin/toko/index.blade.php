@extends('admin.layouts.app')

@section('judul', 'Jam Kerja')

@section('konten')
    @php
        $jamBuka = substr((string) $toko->jam_buka, 0, 5);
        $jamTutup = substr((string) $toko->jam_tutup, 0, 5);
    @endphp

    <div class="page-head">
        <div>
            <h1>Jam Kerja Toko</h1>
            <p>Atur jadwal buka/tutup. Perubahan langsung dipakai server saat memvalidasi checkout Flutter.</p>
        </div>
    </div>

    <div class="store-hero {{ $status['buka'] ? '' : 'closed' }} mb-16">
        <span class="pill"><span class="status-dot"></span>{{ $status['buka'] ? 'Sedang Buka' : 'Sedang Tutup' }}</span>
        <h2>{{ $status['buka'] ? 'Toko menerima pesanan' : 'Checkout ditolak server' }}</h2>
        <p>{{ $status['pesan'] }}</p>
        <div class="store-meta">
            <span class="pill">Jadwal {{ $jamBuka }}–{{ $jamTutup }} WIB</span>
            <span class="pill">Waktu sekarang {{ now()->format('H:i') }} WIB</span>
            <span class="pill">Penutupan manual: {{ $status['tutup_manual'] ? 'Ya' : 'Tidak' }}</span>
        </div>
    </div>

    <div class="grid two-col">
        <section class="card">
            <div class="card-header">
                <div>
                    <h2 class="card-title">Atur Jadwal</h2>
                    <p class="card-sub">Jam tutup yang melewati tengah malam didukung, mis. 18:00–02:00.</p>
                </div>
            </div>

            <form method="POST" action="{{ route('admin.toko.update', $toko) }}">
                @csrf
                @method('PUT')

                <div class="form-grid">
                    <div class="field full @error('nama') has-error @enderror">
                        <label for="nama">Nama toko</label>
                        <input id="nama" type="text" name="nama" value="{{ old('nama', $toko->nama) }}" maxlength="100" required>
                        @error('nama') <span class="error">{{ $message }}</span> @enderror
                    </div>

                    <div class="field @error('jam_buka') has-error @enderror">
                        <label for="jam_buka">Jam buka</label>
                        <input id="jam_buka" type="time" name="jam_buka" value="{{ old('jam_buka', $jamBuka) }}" required>
                        @error('jam_buka') <span class="error">{{ $message }}</span> @enderror
                    </div>

                    <div class="field @error('jam_tutup') has-error @enderror">
                        <label for="jam_tutup">Jam tutup</label>
                        <input id="jam_tutup" type="time" name="jam_tutup" value="{{ old('jam_tutup', $jamTutup) }}" required>
                        @error('jam_tutup') <span class="error">{{ $message }}</span> @enderror
                    </div>
                </div>

                <div class="alert alert-info" style="margin: 16px 0 0;">
                    Aturan jam buka hanya ditegakkan di server. Aplikasi Flutter tetap mengirim checkout,
                    lalu menampilkan pesan <strong>409 toko_tutup</strong> bila di luar jadwal.
                </div>

                <div class="form-actions">
                    <button class="btn btn-primary" type="submit">Simpan Jam Kerja</button>
                </div>
            </form>
        </section>

        <div class="stack">
            <section class="card">
                <div class="card-header">
                    <div>
                        <h2 class="card-title">Buka / Tutup Cepat</h2>
                        <p class="card-sub">Menutup manual mengabaikan jadwal sampai dibuka kembali.</p>
                    </div>
                </div>

                @if ($status['tutup_manual'])
                    <div class="alert alert-danger">
                        Toko sedang ditutup manual. Checkout dari Flutter akan ditolak meskipun berada di dalam jam kerja.
                    </div>
                    <form method="POST" action="{{ route('admin.toko.buka', $toko) }}">
                        @csrf
                        @method('PATCH')
                        <button class="btn btn-success btn-block" type="submit">Buka Toko Kembali</button>
                    </form>
                @else
                    <p class="muted small">
                        Gunakan tombol ini untuk menghentikan pesanan sementara tanpa mengubah jadwal jam kerja.
                    </p>
                    <form method="POST" action="{{ route('admin.toko.tutup', $toko) }}"
                          data-konfirmasi="Tutup toko sekarang? Checkout dari aplikasi Flutter akan ditolak sampai toko dibuka kembali.">
                        @csrf
                        @method('PATCH')
                        <button class="btn btn-danger btn-block" type="submit">Tutup Toko Sekarang</button>
                    </form>
                @endif
            </section>

            <section class="card">
                <div class="card-header">
                    <div>
                        <h2 class="card-title">Ringkasan</h2>
                    </div>
                </div>
                <div class="info-list">
                    <div class="info-row"><span>Nama toko</span><strong>{{ $toko->nama }}</strong></div>
                    <div class="info-row"><span>Jadwal</span><strong>{{ $jamBuka }}–{{ $jamTutup }} WIB</strong></div>
                    <div class="info-row"><span>Status jadwal</span><strong>{{ $status['tutup_manual'] ? 'Ditimpa penutupan manual' : 'Mengikuti jam kerja' }}</strong></div>
                    <div class="info-row"><span>Zona waktu</span><strong>Asia/Jakarta</strong></div>
                </div>
            </section>
        </div>
    </div>
@endsection
