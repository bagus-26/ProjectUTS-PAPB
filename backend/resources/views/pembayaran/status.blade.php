<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $berhasil ? 'Pembayaran Selesai' : 'Pembayaran Belum Selesai' }}</title>
    <style>
        * { box-sizing: border-box; }
        body {
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;
            background: #FDF6EC;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            color: #3B2A20;
        }
        .kartu {
            width: 100%;
            max-width: 420px;
            background: #FFFFFF;
            border-radius: 24px;
            padding: 32px 24px;
            text-align: center;
            box-shadow: 0 18px 40px rgba(59, 42, 32, 0.12);
        }
        .ikon {
            width: 72px;
            height: 72px;
            margin: 0 auto 18px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 34px;
            color: #FFFFFF;
            background: {{ $berhasil ? '#4CAF50' : '#E67E22' }};
        }
        h1 { font-size: 20px; margin: 0 0 8px; }
        p { font-size: 14px; line-height: 1.6; color: #7A6A5F; margin: 0 0 24px; }
        .tombol {
            display: inline-block;
            padding: 13px 22px;
            border-radius: 14px;
            background: #6F4E37;
            color: #FFFFFF;
            font-weight: 700;
            font-size: 14px;
            text-decoration: none;
        }
        .catatan { font-size: 12px; color: #9C8B7F; margin-top: 18px; }
    </style>
</head>
<body>
    <main class="kartu">
        <div class="ikon">{{ $berhasil ? '✓' : '!' }}</div>
        <h1>{{ $berhasil ? 'Pembayaran Berhasil' : 'Pembayaran Belum Selesai' }}</h1>
        <p>
            @if ($berhasil)
                Terima kasih! Pembayaran kamu sudah kami terima. Kembali ke aplikasi
                MakanYuk! untuk melihat status pesanan terbaru.
            @else
                Pembayaran belum diselesaikan. Kamu masih bisa membuka kembali
                halaman pembayaran dari rincian pesanan di aplikasi.
            @endif
        </p>
        <p class="catatan">
            Aplikasi memperbarui status pesanan secara otomatis setiap beberapa detik.
            Tutup halaman ini lalu kembali ke aplikasi.
        </p>
    </main>
</body>
</html>
