@extends('admin.layouts.app')

@section('judul', 'Pesan & Feedback Pelanggan')

@section('konten')
    <div class="page-head">
        <div>
            <h1>Pesan &amp; Feedback Pelanggan</h1>
            <p>Balas chat pelanggan. Balasan admin otomatis muncul sebagai notifikasi lonceng di aplikasi Flutter.</p>
        </div>
        <span class="badge badge-{{ $totalBelumDibaca > 0 ? 'danger' : 'success' }}">
            {{ $totalBelumDibaca }} pesan belum dibaca
        </span>
    </div>

    <section class="card">
        @if ($percakapan->isEmpty())
            <div class="empty">
                <div class="empty-icon">💬</div>
                <h3>Belum ada pesan pelanggan</h3>
                <p>Pesan dari halaman Pusat Bantuan di aplikasi Flutter akan muncul di sini.</p>
            </div>
        @else
            <div class="conversation-list">
                @foreach ($percakapan as $item)
                    @php
                        $terakhir = $item->supportMessages->first();
                    @endphp
                    <a class="conversation-item" href="{{ route('admin.support.show', $item) }}">
                        <span class="conversation-avatar">{{ \Illuminate\Support\Str::upper(\Illuminate\Support\Str::substr($item->nama, 0, 1)) }}</span>
                        <span class="conversation-body">
                            <span class="conversation-name">{{ $item->nama }}</span>
                            <span class="conversation-preview">
                                {{ $terakhir?->sender_role === 'admin' ? 'Kamu: ' : '' }}{{ \Illuminate\Support\Str::limit($terakhir?->message ?? '', 70) }}
                            </span>
                        </span>
                        <span class="conversation-meta">
                            <span>{{ $terakhir?->created_at?->format('d/m H:i') }}</span>
                            @if ($item->belum_dibaca > 0)
                                <span class="unread-pill">{{ $item->belum_dibaca }}</span>
                            @endif
                        </span>
                    </a>
                @endforeach
            </div>
        @endif
    </section>
@endsection
