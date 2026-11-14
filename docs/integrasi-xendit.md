# Integrasi Payment Gateway Xendit

Panduan ini menjelaskan cara mengaktifkan pembayaran Xendit pada proyek MakanYuk! dari nol: mendaftar akun, mengambil kunci mode Test, mengatur webhook, sampai menguji pembayaran dari aplikasi Flutter.

Alur yang dipakai adalah **Xendit Invoice**: server membuat invoice, aplikasi membuka halaman pembayaran Xendit, lalu status pesanan diperbarui otomatis lewat webhook (dan sinkronisasi cadangan saat rincian pesanan dibuka). Pelanggan dapat memilih QRIS, e-wallet, virtual account, atau kartu saat checkout. Server mengirim `payment_methods` sesuai kategori pilihan; halaman hosted checkout Xendit tetap memakai tampilan standar, tetapi hanya menampilkan kanal dari kategori tersebut.

## 1. Daftar akun Xendit (mode Test)

1. Buka <https://dashboard.xendit.co/register>.
2. Daftar dengan email dan kata sandi, lalu verifikasi email.
3. Setelah masuk, pastikan sakelar **Test Mode** aktif. Mode Test tidak memotong uang sungguhan dan tidak memerlukan verifikasi bisnis.
4. Lengkapi nama bisnis bila diminta; data boleh berupa data uji coba.

> Untuk menerima pembayaran sungguhan, akun harus melalui verifikasi bisnis (KYC) dan mode Live diaktifkan. Langkah tersebut tidak diperlukan untuk UTS.

## 2. Ambil Secret Key dan Callback Token

1. Di dashboard, buka **Settings → Developers → API Keys**.
2. Salin **Secret Key** mode Test. Nilainya diawali `xnd_development_`.
3. Buka **Settings → Developers → Webhooks**.
4. Salin **Verification Token** (dipakai sebagai Callback Token).
5. Daftarkan URL webhook Invoice:

   ```text
   https://<domain-atau-tunnel-anda>/api/xendit/callback
   ```

   Saat mengembangkan di laptop, gunakan terowongan seperti ngrok:

   ```bash
   ngrok http 8000
   ```

   Lalu pakai alamat HTTPS yang diberikan ngrok. Tanpa webhook pun aplikasi tetap dapat mendeteksi pembayaran karena status invoice ikut disinkronkan saat rincian pesanan dibuka, tetapi webhook membuat pembaruan berjalan seketika.

## 3. Isi berkas `.env` backend

Buka `backend/.env` lalu isi:

```dotenv
XENDIT_SECRET_KEY=xnd_development_xxxxxxxxxxxxxxxx
XENDIT_CALLBACK_TOKEN=token-dari-dashboard
XENDIT_BASE_URL=https://api.xendit.co
XENDIT_INVOICE_DURATION=86400
XENDIT_TIMEOUT=15
XENDIT_SUCCESS_REDIRECT_URL=
XENDIT_FAILURE_REDIRECT_URL=
```

Catatan:

- Biarkan dua URL redirect kosong agar aplikasi memakai host permintaan saat checkout (mis. `http://192.168.1.10:8000`). Ini membuat halaman "Pembayaran selesai" tetap bisa dibuka dari HP pada jaringan lokal. Isi manual bila memakai domain tetap.
- Jangan pernah menaruh Secret Key di aplikasi Flutter. Seluruh panggilan Xendit dilakukan server.
- Setelah mengubah `.env`, jalankan `php artisan config:clear` bila konfigurasi pernah di-cache.

## 4. Siapkan basis data

```bash
cd backend
php artisan migrate
php artisan db:seed --class=MetodePembayaranSeeder
```

Perintah kedua menambahkan metode pembayaran berikut (selain tunai dan transfer manual):

| Kode | Nama | Kanal Xendit |
|---|---|---|
| `xendit_qris` | QRIS (GoPay, OVO, DANA, ShopeePay) | QRIS |
| `xendit_ewallet` | E-Wallet (OVO, DANA, ShopeePay, LinkAja) | E-wallet |
| `xendit_va` | Virtual Account Bank | BCA, BNI, BRI, Mandiri, Permata |
| `xendit_kartu` | Kartu Kredit / Debit | Kartu |

## 5. Jalankan aplikasi

Backend:

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

Flutter (dari folder `mobile/`), gunakan alamat IPv4 laptop:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

## 6. Alur pembayaran di aplikasi

1. Pelanggan menekan **Buat Pesanan** pada halaman Checkout.
2. Server menyimpan pesanan, lalu membuat invoice Xendit (`POST https://api.xendit.co/v2/invoices`) dengan `payment_methods` sesuai kategori pilihan. Nomor pesanan dipakai sebagai `external_id`.
3. Respons checkout berisi `pembayaran.invoice_url`.
4. Pada halaman Rincian Pesanan, tombol **Bayar Sekarang** membuka halaman Xendit di browser.
5. Setelah pelanggan membayar, Xendit mengirim webhook ke `/api/xendit/callback`. Pesanan berpindah dari `menunggu_pembayaran` ke `menunggu_konfirmasi`.
6. Selama status masih `menunggu_pembayaran`, pelanggan dapat menekan **Batalkan Pesanan** pada Rincian Pesanan. Server mengembalikan stok dan mengedaluwarsakan invoice Xendit (`POST /invoices/{id}/expire!`) agar tautan bayar tidak dapat dipakai lagi. Setelah pembayaran masuk (`menunggu_konfirmasi`), pembatalan ditangani admin lewat tombol **Tolak Pesanan**.
7. Aplikasi menyegarkan rincian pesanan setiap 3 detik, sehingga status berubah tanpa perlu menekan tombol apa pun.
8. Admin meng-ACC pembayaran di `/admin` (`menunggu_konfirmasi` → `dibayar`), lalu memproses pesanan seperti biasa.

## 7. Menguji pembayaran di mode Test

1. Checkout dengan salah satu metode `xendit_*`.
2. Tekan **Bayar Sekarang**; halaman Xendit terbuka.
3. Selesaikan pembayaran memakai simulasi yang disediakan Xendit. Pada mode Test, Xendit menyediakan simulator pembayaran (mis. melalui menu **Invoices/Payments** di dashboard atau tautan simulasi pada halaman invoice). Ikuti petunjuk yang tampil pada halaman pembayaran.
4. Kembali ke aplikasi. Dalam beberapa detik status berubah menjadi **Menunggu Konfirmasi**.
5. Di panel admin, buka pesanan lalu tekan **ACC Pembayaran**.

Bila webhook belum terhubung (mis. belum ada ngrok), buka rincian pesanan di aplikasi; server akan menanyakan status invoice langsung ke Xendit dan memperbarui pesanan.

## 8. Endpoint terkait

| Metode | Jalur | Keterangan |
|---|---|---|
| POST | `/api/checkout` | Pesanan dengan metode `xendit_*` otomatis dibuatkan invoice. |
| POST | `/api/pesanan/{id}/pembayaran` | Membuat atau memakai ulang tautan pembayaran. |
| POST | `/api/xendit/callback` | Webhook Xendit; diverifikasi lewat header `x-callback-token`. |
| GET | `/api/pesanan/{id}` | Menyertakan objek `pembayaran` dan menyinkronkan status invoice. |

Contoh objek `pembayaran` pada respons:

```json
{
  "kanal": "xendit_qris",
  "invoice_id": "66f1c2e4a9b8c7001a2b3c4d",
  "invoice_url": "https://checkout.xendit.co/web/66f1c2e4a9b8c7001a2b3c4d",
  "status": "PENDING",
  "dibayar_pada": null
}
```

## 9. Pengujian otomatis

```bash
cd backend
php artisan test --compact tests/Feature/XenditPembayaranTest.php
```

Tes memakai `Http::fake()` sehingga tidak memanggil Xendit sungguhan dan tidak memerlukan kunci API.

## 10. Pemecahan masalah

| Gejala | Penyebab umum | Tindakan |
|---|---|---|
| Checkout 201 tetapi `pembayaran` bernilai `null` | `XENDIT_SECRET_KEY` kosong atau invoice gagal dibuat | Isi `.env`, jalankan `php artisan config:clear`, cek `storage/logs/laravel.log`. |
| Tekan **Bayar Sekarang** muncul galat 502 | Kredensial salah atau kanal belum aktif di akun Xendit | Pastikan memakai Secret Key mode Test dan kanal pembayaran aktif di dashboard. |
| Log berisi "Tidak dapat terhubung ke Xendit" dengan cURL errno 60 | PHP tidak menemukan CA bundle untuk verifikasi TLS | Unduh `https://curl.se/ca/cacert.pem`, lalu isi `curl.cainfo` dan `openssl.cafile` di `php.ini` dengan path file tersebut, kemudian restart server. |
| Pembayaran berhasil tetapi status tidak berubah | Webhook belum terdaftar/terjangkau | Buka rincian pesanan (sinkronisasi cadangan) atau perbaiki URL webhook. |
| Webhook 401 | Callback Token berbeda | Samakan `XENDIT_CALLBACK_TOKEN` dengan Verification Token di dashboard. |
| Semua metode muncul pada halaman invoice | Invoice lama dibuat sebelum pembatasan kanal atau kanal belum terbatasi | Buat pesanan baru setelah pembaruan; tautan invoice yang sudah ada tidak berubah. Pastikan metode yang diperlukan aktif di dashboard Xendit. |
| Halaman "Pembayaran selesai" tidak terbuka di HP | URL redirect memakai `localhost` | Kosongkan `XENDIT_SUCCESS_REDIRECT_URL`, atau isi dengan alamat IP laptop/domain. |
| Tautan pembayaran kedaluwarsa | Melewati `invoice_duration` | Tekan **Bayar Sekarang** lagi; server membuat invoice baru. |

## 11. Checklist sebelum demo

- [ ] `XENDIT_SECRET_KEY` dan `XENDIT_CALLBACK_TOKEN` terisi.
- [ ] `php artisan migrate` sudah dijalankan (kolom `xendit_*` tersedia).
- [ ] `MetodePembayaranSeeder` sudah dijalankan.
- [ ] Webhook `/api/xendit/callback` terdaftar dan dapat dijangkau (bila memakai webhook).
- [ ] `php artisan test` lulus.
- [ ] Uji satu pembayaran QRIS mode Test dari HP.
- [ ] Tunjukkan status berubah otomatis dan ACC admin.
