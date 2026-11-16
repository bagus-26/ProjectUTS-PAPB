@extends('admin.layouts.app')

@section('judul', 'Chat '.$pelanggan->nama)

@section('konten')
    <div class="page-head">
        <div>
            <a class="btn btn-sm btn-outline" href="{{ route('admin.support.index') }}">← Semua Percakapan</a>
            <h1 style="margin-top: 10px;">Chat dengan {{ $pelanggan->nama }}</h1>
            <p>{{ $pelanggan->phone ?: 'Nomor WhatsApp belum diisi' }} · Pelanggan #{{ $pelanggan->id }}</p>
        </div>
        <span class="badge badge-success">Polling 5 detik</span>
    </div>

    <div class="grid support-grid">
        <div class="stack">
            <section class="card">
                <div class="card-header">
                    <div>
                        <h2 class="card-title">Info Pelanggan</h2>
                    </div>
                </div>
                <div class="info-list">
                    <div class="info-row"><span>Nama</span><strong>{{ $pelanggan->nama }}</strong></div>
                    <div class="info-row"><span>WhatsApp</span><strong>{{ $pelanggan->phone ?: '-' }}</strong></div>
                    <div class="info-row"><span>Email</span><strong>{{ $pelanggan->email ?: '-' }}</strong></div>
                    <div class="info-row"><span>Poin reward</span><strong>{{ number_format($pelanggan->poin, 0, ',', '.') }} poin</strong></div>
                </div>
            </section>

            <section class="card">
                <div class="card-header">
                    <div>
                        <h2 class="card-title">Tips CS</h2>
                    </div>
                </div>
                <p class="card-sub" style="margin-bottom: 0;">
                    Balasan admin akan tersimpan sebagai pesan belum dibaca dan memicu notifikasi
                    lonceng di HP pelanggan. Halaman ini menyegarkan pesan otomatis setiap 5 detik.
                </p>
            </section>
        </div>

        <section class="card chat-card">
            <div class="chat-head">
                <span class="conversation-avatar">{{ \Illuminate\Support\Str::upper(\Illuminate\Support\Str::substr($pelanggan->nama, 0, 1)) }}</span>
                <div>
                    <div class="cell-main">{{ $pelanggan->nama }}</div>
                    <div class="cell-sub">Percakapan pelanggan &amp; admin CS</div>
                </div>
            </div>

            <div class="chat-body" id="chat-body">
                @if ($pesan->isEmpty())
                    <div class="chat-empty" id="chat-empty">Belum ada pesan. Sapa pelanggan terlebih dahulu.</div>
                @else
                    @foreach ($pesan as $item)
                        <div class="chat-bubble {{ $item->sender_role === 'admin' ? 'admin' : 'user' }}">
                            {{ $item->message }}
                            <span class="chat-meta">
                                {{ $item->sender_role === 'admin' ? 'Admin' : 'Pelanggan' }} ·
                                {{ $item->created_at?->format('d/m H:i') }}
                            </span>
                        </div>
                    @endforeach
                @endif
            </div>

            <form class="chat-form" method="POST" action="{{ route('admin.support.store', $pelanggan) }}">
                @csrf
                <textarea name="message" placeholder="Tulis balasan untuk pelanggan..." maxlength="1000" required></textarea>
                <button class="btn btn-primary" type="submit">Kirim</button>
            </form>
        </section>
    </div>

    <script>
        (() => {
            const body = document.getElementById('chat-body');
            const url = @json(route('admin.support.messages', $pelanggan));

            const render = (items) => {
                body.innerHTML = '';

                if (!items.length) {
                    const kosong = document.createElement('div');
                    kosong.className = 'chat-empty';
                    kosong.textContent = 'Belum ada pesan. Sapa pelanggan terlebih dahulu.';
                    body.appendChild(kosong);
                    return;
                }

                items.forEach((item) => {
                    const bubble = document.createElement('div');
                    bubble.className = 'chat-bubble ' + (item.sender_role === 'admin' ? 'admin' : 'user');
                    bubble.textContent = item.message;

                    const meta = document.createElement('span');
                    meta.className = 'chat-meta';
                    meta.textContent = (item.sender_role === 'admin' ? 'Admin' : 'Pelanggan') + ' · ' + (item.waktu || '');
                    bubble.appendChild(meta);

                    body.appendChild(bubble);
                });

                body.scrollTop = body.scrollHeight;
            };

            const muatPesan = async () => {
                try {
                    const respons = await fetch(url, {
                        headers: { 'Accept': 'application/json' },
                        credentials: 'same-origin',
                    });

                    if (!respons.ok) {
                        return;
                    }

                    const hasil = await respons.json();
                    render(hasil.data || []);
                } catch (error) {
                    // Abaikan gangguan jaringan; polling berikutnya mencoba lagi.
                }
            };

            body.scrollTop = body.scrollHeight;
            setInterval(muatPesan, 5000);
        })();
    </script>
@endsection
