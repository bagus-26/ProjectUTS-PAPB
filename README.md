# Toko Online Kelompok 1 — Makanan dan Minuman Siap Saji (MakanYuk!)

Repositori tugas pengganti UTS mata kuliah Pemrograman Aplikasi Perangkat Bergerak (PAPB) dan Sistem Terdistribusi. Sesuai PRD Bagian 12.1, proyek terdiri atas REST API Laravel + MySQL di `backend/`, aplikasi Flutter di `mobile/`, dokumentasi di `docs/`, dan README ini.

Dokumen acuan utama: [`docs/PRD.md`](docs/PRD.md). Kontrak API v1 diringkas di [`docs/kontrak-api-v1.md`](docs/kontrak-api-v1.md).

## 1. Identitas Kelompok

| Kode | Nama | NIM | Peran |
|---|---|---|---|
| PM | Bagus Artandyo Witjaksono | 24102029 | Project Manager (Ketua Kelompok), fondasi backend & Flutter, integrasi, README |
| A1 | Adhiyatma Pandu Hermansyah | 24102002 | Backend: basis data, seeder, Produk |
| A2 | Nurul Maghfiroh | 24102051 | Backend: Keranjang, Checkout, transaksi |
| A3 | Alifia Az-Zahrah Murtidewi | 24102004 | UI/UX Flutter |
| A4 | Erika Salsabila Intania | 24102009 | Flutter: Katalog, Rincian Produk, Kelola Produk, Riwayat |
| A5 | Mir'atus Sani Fadillah | 24102047 | Flutter: Keranjang, Checkout, Rincian Pesanan, Widget |

## 2. Domain dan Aturan Khas

Domain: makanan dan minuman siap saji. Atribut khas yang wajib ada:

- Varian porsi (`varian_produk`: Reguler/Jumbo/Large dengan tambahan harga).
- Tingkat kepedasan per item (`tidak_pedas`, `sedang`, `pedas`, `sangat_pedas`) hanya untuk produk `bisa_pedas = true`.
- Catatan per item (maksimal 200 karakter).
- Jam buka toko pada tabel `toko`.

Aturan bisnis: **checkout ditolak server dengan 409 `toko_tutup` bila waktu WIB di luar `jam_buka`–`jam_tutup`.** Flutter tidak boleh mematikan tombol checkout berdasarkan jam.

## 3. Menjalankan Backend

Prasyarat: PHP 8.3+, Composer, MySQL 8 (Laragon), dan ekstensi `pdo_mysql`.

```bash
cd backend
composer install
copy .env.example .env
php artisan key:generate
```

Buat basis data di MySQL (Laragon) bila belum ada:

```sql
CREATE DATABASE FastFoodUTS CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Sesuaikan `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, dan `DB_PASSWORD` pada `.env`. Default proyek: MySQL Laragon, `root`, tanpa kata sandi, basis data `FastFoodUTS`.

Migrasi dan seeder domain (produk, varian, kurir, metode pembayaran, toko, pelanggan, dan pesanan contoh) sudah tersedia dan dijalankan sekali:

```bash
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

Alamat lokal: `http://127.0.0.1:8000`. Zona waktu aplikasi: `Asia/Jakarta`.

## 4. Menjalankan Flutter

Jalankan Flutter dari direktori `mobile/`:

```bash
cd mobile
flutter pub get
flutter run
```

Untuk langkah lengkap menjalankan aplikasi di HP Android fisik melalui USB dan Wi-Fi pada Windows, lihat [mobile/PANDUAN-RUN-HP.md](mobile/PANDUAN-RUN-HP.md). Alamat backend dapat diatur saat menjalankan Flutter dengan `--dart-define=API_BASE_URL=http://<IPv4-laptop>:8000/api`; gunakan alamat IPv4 laptop yang menjalankan backend, bukan `localhost`. Backend harus listen pada semua interface:

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

Untuk MuMu Player, sambungkan perangkat lewat ADB, jalankan `adb reverse tcp:8000 tcp:8000`, lalu gunakan alamat loopback saat menjalankan Flutter:

```bash
flutter run -d <id-perangkat> --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

PRD mensyaratkan izin `INTERNET` dan `android:usesCleartextTraffic="true"` pada manifest Android utama agar koneksi HTTP lokal dapat digunakan. Pastikan konfigurasi ini ada di `mobile/android/app/src/main/AndroidManifest.xml`.

Fitur alamat meminta lokasi hanya setelah pengguna menekan tombol lokasi. Aplikasi menggunakan koordinat perangkat untuk membantu mengisi alamat; lengkapi nama jalan dan patokan secara manual. Lokasi tidak dikirim ke layanan geocoding pihak ketiga. Profil tetap memakai pelanggan demo dan data alamat pesanan yang sudah ada—tidak menambah endpoint atau skema akun di luar PRD.

## 5. Token Statis

Kontrak API menetapkan header `Authorization: Bearer <token>`. Nilai untuk data seed tercantum di bawah.

| Pelanggan | Token |
|---|---|
| Pelanggan Uji 1 | diatur per deploy (`.env` / seeder, tidak dipublikasikan) |
| Pelanggan Uji 2 | diatur per deploy (`.env` / seeder, tidak dipublikasikan) |

Token salah atau kosong dibalas `401` dengan pembungkus yang sama.

## 6. Daftar Endpoint

Daftar berikut adalah kontrak dalam PRD Bagian 6; endpoint yang terdaftar sudah diimplementasikan. Pembungkus respons: `status`, `code` (string), `message`, `data`, dan `errors` (khusus 422).

| Metode | Jalur | Fungsi | PIC |
|---|---|---|---|
| GET | `/api/produk` | Daftar produk (`?kategori=`, `?cari=`) | A1 |
| GET | `/api/produk/{id}` | Rincian produk + varian | A1 |
| POST | `/api/produk` | Tambah produk | A1 |
| PUT | `/api/produk/{id}` | Ubah produk | A1 |
| DELETE | `/api/produk/{id}` | Soft delete produk | A1 |
| GET | `/api/keranjang` | Isi keranjang + ringkasan (`?kurir_id=`) | A2 |
| POST | `/api/keranjang` | Tambah item keranjang | A2 |
| PUT | `/api/keranjang/{id}` | Ubah jumlah item | A2 |
| DELETE | `/api/keranjang/{id}` | Hapus item keranjang | A2 |
| GET | `/api/kurir` | Daftar kurir dan tarif | A3 |
| POST | `/api/checkout` | Buat pesanan (wajib `X-Kunci-Idempoten`) | A2 |
| GET | `/api/pesanan` | Riwayat pesanan | A3 |
| GET | `/api/pesanan/{id}` | Rincian pesanan | A3 |
| PATCH | `/api/pesanan/{id}/status` | Ubah status pesanan | A3 |
| GET | `/api/kategori` | Daftar kategori untuk filter | A1 |
| GET | `/api/metode-pembayaran` | Daftar metode pembayaran simulasi | A3 |

Dokumentasi endpoint API dalam format PDF tersedia di [`docs/PAPB-UTS_Kelompok-01_Makanan.pdf`](docs/PAPB-UTS_Kelompok-01_Makanan.pdf) (10 halaman: ERD, tabel endpoint, contoh request/response nyata, perhitungan, aturan bisnis, idempotensi, dan transisi status). Ekspor Postman belum dibuat.

### Panel Admin

Panel admin berbasis sesi tersedia di `http://127.0.0.1:8000/admin` (akun seed: `admin@makanyuk.test` / `admin12345`). Panel ini melengkapi backend tanpa mengubah kode Flutter dan memakai `StatusPesanan`, `PesananService`, `AturanProduk`, serta `ProdukService` yang sama dengan API, sehingga transisi status dan validasi produk konsisten.

- Login/logout admin dengan middleware `PastikanAdmin`; pengguna non-admin tidak dapat membuka `/admin`.
- Dasbor ringkas, daftar dan rincian pesanan, aksi ACC pembayaran, penolakan, pemrosesan, pengiriman, dan penyelesaian pesanan.
- Pembatalan pesanan mengembalikan stok produk secara otomatis.
- CRUD produk (soft delete) dan pengaturan jam buka/tutup toko termasuk tutup manual sementara.
- Halaman referensi berisi daftar status, transisi sah, dan aturan domain.

Akses panel memerlukan `php artisan migrate --seed` agar `users.is_admin`, `toko.tutup_manual`, dan akun admin tersedia. Perilaku panel dicakup oleh `backend/tests/Feature/AdminPanelTest.php` (bagian dari `php artisan test`).

## 7. Simulasi Galat dan Jam Buka saat Demo

Gangguan hanya aktif bila `APP_ENV=local` (D-12). Tidak ada route tambahan.

- `SIMULASI_GALAT_500=true` membuat `GET /api/produk` membalas `500`.
- `SIMULASI_LAMBAT_DETIK=12` menunda respons agar batas waktu 10 detik di Flutter terpicu.
- Kembalikan kedua nilai ke `false` dan `0` setelah demo.

Mengubah jam buka lewat tinker (bukan mengubah jam laptop):

```bash
php artisan tinker --execute 'DB::table("toko")->update(["jam_buka" => "08:00", "jam_tutup" => "21:00"]);'
```

Lembar persiapan demo langsung (tanpa video): [`docs/lembar-demo-langsung.md`](docs/lembar-demo-langsung.md). Langkah demo baru dapat dijalankan setelah backend dan integrasi Flutter selesai.

## 8. Struktur Repositori

```text
.
|-- backend/                 # proyek Laravel 12 (REST API)
|   |-- database/migrations/
|   |-- database/seeders/
|   `-- .env.example
|-- mobile/                  # proyek Flutter
|   |-- lib/
|   |-- test/
|   `-- pubspec.yaml
|-- docs/                    # PRD, kontrak API, catatan Flutter, lembar demo, PDF dokumentasi API
|-- README.md
```

## 9. Alur Kerja

- `main` dilindungi: tanpa push langsung, PR wajib dengan minimal 1 approval dari pasangan review.
- Cabang: `be/<modul>-<ringkas>`, `fe/<halaman>-<ringkas>`, `docs/<ringkas>`, `fix/<ringkas>`.
- Format commit: `tipe(area): apa yang berubah`, contoh `feat(checkout): tolak pesanan di luar jam buka dengan 409`.
- Jangan memakai squash merge. Target minimal 6 commit bermakna per anggota pada minimal 4 hari berbeda.
- Ubah kontrak API hanya lewat PR ke `docs/PRD.md` yang disetujui pemilik endpoint dan pemakai Flutter.

## 10. Bantuan AI dan Pustaka Pihak Ketiga

Bantuan AI: fondasi awal PM-01/PM-02/PM-03/PM-05 (struktur repo, skeleton Laravel, inti `LayananApi`, middleware simulasi) disusun dengan bantuan opencode. Setiap baris wajib ditinjau dan dapat dijelaskan oleh PM; bantuan AI pada PR lain dicatat di template PR dan diperbarui di bagian ini.

Pustaka produksi:

- Laravel 12 dan ekosistemnya (`laravel/framework`, `laravel/tinker`).
- Flutter dengan paket `http` (permintaan HTTP) dan `uuid` (kunci idempoten checkout, terdaftar di `mobile/pubspec.yaml`).

Pustaka pengembangan: PHPUnit, Laravel Pint, Laravel Pail, Laravel Boost. Tidak ada payment gateway maupun API ekspedisi.

## 11. Status Implementasi Saat Ini

- Backend sudah memiliki pembungkus respons, middleware, handler exception, seluruh endpoint kontrak Bagian 6, serta migrasi dan seeder domain.
- Flutter mengimplementasikan alur katalog, produk, keranjang, checkout, riwayat/status pesanan, profil demo, pemilihan koordinat lokasi secara manual, dan splash screen.
- PRD mensyaratkan 7 halaman Flutter, migration dan seeder domain, serta endpoint berfungsi. Semua itu masih menjadi pekerjaan implementasi; status terkini dapat berubah seiring pengerjaan.
- PDF dokumentasi API tersedia di `docs/` dan panel admin tersedia di `/admin`. Ekspor Postman belum dibuat. Video demo tidak dibuat; rencana pembuktian menggunakan demo langsung sesuai PRD.
