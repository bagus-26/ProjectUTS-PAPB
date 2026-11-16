@extends('admin.layouts.app')

@section('judul', $promo->exists ? 'Ubah Promo' : 'Tambah Promo')

@section('konten')
    @php
        $aksi = $promo->exists ? route('admin.promo.update', $promo) : route('admin.promo.store');
    @endphp

    <div class="page-head">
        <div>
            <a class="btn btn-sm btn-outline" href="{{ route('admin.promo.index') }}">← Kembali</a>
            <h1 style="margin-top: 10px;">{{ $promo->exists ? 'Ubah Promo' : 'Tambah Promo' }}</h1>
            <p>Atur diskon, minimal belanja, dan biaya poin untuk voucher pelanggan.</p>
        </div>
    </div>

    <form method="POST" action="{{ $aksi }}">
        @csrf
        @if ($promo->exists)
            @method('PUT')
        @endif

        <div class="grid two-col">
            <section class="card">
                <div class="card-header">
                    <div>
                        <h2 class="card-title">Informasi Promo</h2>
                        <p class="card-sub">Tampil di halaman Promo &amp; Tukar Poin Flutter.</p>
                    </div>
                </div>

                <div class="form-grid">
                    <div class="field">
                        <label for="title">Judul Promo</label>
                        <input id="title" type="text" name="title" value="{{ old('title', $promo->title) }}" placeholder="Contoh: Diskon 20% Makanan" required>
                        @error('title') <span class="error">{{ $message }}</span> @enderror
                    </div>

                    <div class="field">
                        <label for="code">Kode Promo</label>
                        <input id="code" type="text" name="code" value="{{ old('code', $promo->code) }}" placeholder="MAKAN20" required>
                        <span class="help">Dipakai pelanggan pada menu Klaim Kode Promo.</span>
                        @error('code') <span class="error">{{ $message }}</span> @enderror
                    </div>

                    <div class="field full">
                        <label for="description">Deskripsi</label>
                        <textarea id="description" name="description" placeholder="Jelaskan syarat dan ketentuan singkat promo...">{{ old('description', $promo->description) }}</textarea>
                        @error('description') <span class="error">{{ $message }}</span> @enderror
                    </div>

                    <div class="field">
                        <label for="discount_type">Tipe Diskon</label>
                        <select id="discount_type" name="discount_type" required>
                            <option value="fixed" @selected(old('discount_type', $promo->discount_type) === 'fixed')>Potongan nominal (Rp)</option>
                            <option value="percent" @selected(old('discount_type', $promo->discount_type) === 'percent')>Persentase (%)</option>
                        </select>
                        @error('discount_type') <span class="error">{{ $message }}</span> @enderror
                    </div>

                    <div class="field">
                        <label for="discount_value">Nilai Diskon</label>
                        <input id="discount_value" type="number" name="discount_value" min="1" value="{{ old('discount_value', $promo->discount_value) }}" placeholder="Contoh: 20000 atau 20" required>
                        <span class="help">Nominal rupiah atau persen sesuai tipe diskon.</span>
                        @error('discount_value') <span class="error">{{ $message }}</span> @enderror
                    </div>
                </div>
            </section>

            <div class="stack">
                <section class="card">
                    <div class="card-header">
                        <div>
                            <h2 class="card-title">Syarat &amp; Penukaran</h2>
                            <p class="card-sub">Atur minimal belanja dan biaya poin.</p>
                        </div>
                    </div>

                    <div class="stack">
                        <div class="field">
                            <label for="min_order">Minimal Belanja (Rp)</label>
                            <input id="min_order" type="number" name="min_order" min="0" value="{{ old('min_order', $promo->min_order ?? 0) }}" required>
                            @error('min_order') <span class="error">{{ $message }}</span> @enderror
                        </div>

                        <div class="field">
                            <label for="point_cost">Biaya Poin</label>
                            <input id="point_cost" type="number" name="point_cost" min="0" value="{{ old('point_cost', $promo->point_cost ?? 0) }}" required>
                            <span class="help">Isi 0 bila promo hanya bisa diklaim lewat kode.</span>
                            @error('point_cost') <span class="error">{{ $message }}</span> @enderror
                        </div>

                        <label class="check">
                            <input type="checkbox" name="is_active" value="1" @checked(old('is_active', $promo->is_active ?? true))>
                            <span>
                                Aktifkan promo
                                <small>Promo nonaktif tidak muncul di aplikasi pelanggan.</small>
                            </span>
                        </label>
                    </div>
                </section>

                <section class="card">
                    <div class="card-header">
                        <div>
                            <h2 class="card-title">Ringkasan</h2>
                        </div>
                    </div>
                    <div class="info-list">
                        <div class="info-row"><span>Kode</span><strong>{{ $promo->code ?: '—' }}</strong></div>
                        <div class="info-row"><span>Diskon</span><strong>{{ $promo->discount_value ? $promo->labelDiskon() : '—' }}</strong></div>
                        <div class="info-row"><span>Biaya poin</span><strong>{{ number_format($promo->point_cost ?? 0, 0, ',', '.') }} poin</strong></div>
                    </div>

                    <div class="form-actions">
                        <a class="btn btn-outline" href="{{ route('admin.promo.index') }}">Batal</a>
                        <button class="btn btn-primary" type="submit">{{ $promo->exists ? 'Simpan Perubahan' : 'Tambah Promo' }}</button>
                    </div>
                </section>
            </div>
        </div>
    </form>
@endsection
