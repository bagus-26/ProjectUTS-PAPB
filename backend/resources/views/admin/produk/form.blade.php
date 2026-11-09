@extends('admin.layouts.app')

@section('judul', $produk->exists ? 'Ubah Produk' : 'Tambah Produk')

@section('konten')
    @php
        $isUbah = $produk->exists;
        $pilihanKategori = collect($kategoriTersedia)
            ->push($produk->kategori)
            ->filter()
            ->unique()
            ->values();
    @endphp

    <div class="page-head">
        <div>
            <div class="actions" style="margin-bottom: 6px;">
                <a class="btn btn-sm btn-outline" href="{{ route('admin.produk.index') }}">← Kembali</a>
            </div>
            <h1>{{ $isUbah ? 'Ubah Produk' : 'Tambah Produk Baru' }}</h1>
            <p>{{ $isUbah ? 'Perubahan langsung terlihat di katalog Flutter.' : 'Lengkapi data menu sesuai kontrak API v1.' }}</p>
        </div>
    </div>

    <form method="POST"
          action="{{ $isUbah ? route('admin.produk.update', $produk) : route('admin.produk.store') }}">
        @csrf
        @if ($isUbah)
            @method('PUT')
        @endif

        <div class="grid" style="grid-template-columns: 1.6fr 0.9fr; align-items: start;">
            <section class="card">
                <div class="card-header">
                    <div>
                        <h2 class="card-title">Informasi Menu</h2>
                        <p class="card-sub">Field yang sama dengan formulir produk di Flutter.</p>
                    </div>
                </div>

                <div class="form-grid">
                    <div class="field full @error('nama') has-error @enderror">
                        <label for="nama">Nama menu</label>
                        <input id="nama" type="text" name="nama" value="{{ old('nama', $produk->nama) }}" maxlength="150" required placeholder="Contoh: Nasi Goreng Spesial">
                        @error('nama') <span class="error">{{ $message }}</span> @enderror
                    </div>

                    <div class="field @error('harga') has-error @enderror">
                        <label for="harga">Harga (Rupiah)</label>
                        <input id="harga" type="number" name="harga" value="{{ old('harga', $produk->harga) }}" min="1" required placeholder="25000">
                        <span class="help">Angka tanpa titik atau koma.</span>
                        @error('harga') <span class="error">{{ $message }}</span> @enderror
                    </div>

                    <div class="field @error('kategori') has-error @enderror">
                        <label for="kategori">Kategori</label>
                        <select id="kategori" name="kategori" required>
                            @foreach ($pilihanKategori as $item)
                                <option value="{{ $item }}" @selected(old('kategori', $produk->kategori) === $item)>{{ $item }}</option>
                            @endforeach
                        </select>
                        @error('kategori') <span class="error">{{ $message }}</span> @enderror
                    </div>

                    <div class="field @error('stok') has-error @enderror">
                        <label for="stok">Stok</label>
                        <input id="stok" type="number" name="stok" value="{{ old('stok', $produk->stok ?? 10) }}" min="0" required>
                        @error('stok') <span class="error">{{ $message }}</span> @enderror
                    </div>

                    <div class="field @error('waktu_persiapan_menit') has-error @enderror">
                        <label for="waktu_persiapan_menit">Waktu persiapan (menit)</label>
                        <input id="waktu_persiapan_menit" type="number" name="waktu_persiapan_menit"
                               value="{{ old('waktu_persiapan_menit', $produk->waktu_persiapan_menit ?? 15) }}" min="0" required>
                        @error('waktu_persiapan_menit') <span class="error">{{ $message }}</span> @enderror
                    </div>

                    <div class="field full @error('deskripsi') has-error @enderror">
                        <label for="deskripsi">Deskripsi (opsional)</label>
                        <textarea id="deskripsi" name="deskripsi" placeholder="Ceritakan menu ini secara singkat">{{ old('deskripsi', $produk->deskripsi) }}</textarea>
                        @error('deskripsi') <span class="error">{{ $message }}</span> @enderror
                    </div>
                </div>

                <div class="form-actions">
                    <a class="btn btn-outline" href="{{ route('admin.produk.index') }}">Batal</a>
                    <button class="btn btn-primary" type="submit">{{ $isUbah ? 'Simpan Perubahan' : 'Tambah Menu' }}</button>
                </div>
            </section>

            <div class="stack">
                <section class="card">
                    <div class="card-header">
                        <div>
                            <h2 class="card-title">Ketersediaan</h2>
                            <p class="card-sub">Kendali tampilan menu di aplikasi pembeli.</p>
                        </div>
                    </div>

                    <div class="check-group">
                        <input type="hidden" name="tersedia" value="0">
                        <label class="check">
                            <input type="checkbox" name="tersedia" value="1"
                                   @checked((bool) old('tersedia', $produk->exists ? $produk->tersedia : true))>
                            <span>
                                Tersedia untuk dipesan
                                <small>Menu disembunyikan dari pembeli bila dimatikan.</small>
                            </span>
                        </label>

                        <input type="hidden" name="bisa_pedas" value="0">
                        <label class="check">
                            <input type="checkbox" name="bisa_pedas" value="1"
                                   @checked((bool) old('bisa_pedas', $produk->bisa_pedas ?? false))>
                            <span>
                                Bisa pedas
                                <small>Pembeli dapat memilih tingkat kepedasan.</small>
                            </span>
                        </label>
                    </div>

                    @error('tersedia') <span class="error">{{ $message }}</span> @enderror
                    @error('bisa_pedas') <span class="error">{{ $message }}</span> @enderror
                </section>

                @if ($isUbah)
                    <section class="card">
                        <div class="card-header">
                            <div>
                                <h2 class="card-title">Varian Porsi</h2>
                                <p class="card-sub">Dikelola oleh seeder, ditampilkan seperti di Flutter.</p>
                            </div>
                        </div>

                        @if ($produk->varian->isEmpty())
                            <p class="muted small mb-0">Belum ada varian untuk menu ini.</p>
                        @else
                            <div class="info-list">
                                @foreach ($produk->varian as $varian)
                                    <div class="info-row">
                                        <span>
                                            {{ $varian->nama }}
                                            @if (! $varian->aktif)
                                                <span class="badge badge-neutral">Nonaktif</span>
                                            @endif
                                        </span>
                                        <strong>+{{ \App\Support\Uang::rupiah($varian->tambahan_harga) }}</strong>
                                    </div>
                                @endforeach
                            </div>
                        @endif
                    </section>
                @endif
            </div>
        </div>
    </form>
@endsection
