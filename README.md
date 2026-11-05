# Toko Online Kelompok 1 — Makanan dan Minuman Siap Saji

Repositori tugas pengganti UTS mata kuliah Pemrograman Aplikasi Perangkat Bergerak (PAPB) dan Sistem Terdistribusi. Aplikasi terdiri atas REST API Laravel + MySQL (`backend/`) dan aplikasi Flutter di root repositori (`lib/`).

Dokumen sumber: [`docs/PRD.md`](docs/PRD.md). Kontrak API ada di Bagian 6 dan sudah dibekukan sebagai Kontrak API v1.

## 1. Identitas Kelompok

| Kode | Nama | NIM | Peran |
|---|---|---|---|
| PM | `Bagus Artandyo Witjaksono` | `24102029` | Project Manager(Ketua Kelompok), fondasi backend & Flutter, integrasi, README |
| A1 | `Adhiyatma Pandu Hermansyah` | `24102002` | Backend: basis data, seeder, Produk |
| A2 | `Nurul Maghfiroh ` | `24102051` | Backend: Keranjang, Checkout, transaksi |
| A3 | `Alifia Az-Zahrah Murtidewi` | `24102004` | UI/UX Flutter: Desain UI/UX Slicing Bagian Halaman Makanan Dan Minuman|
| A4 | `Erika Salsabila Intania` | `24102009` | Flutter: Katalog, Rincian Produk, Kelola Produk, Riwayat FIx Halaman Config |
| A5 | `Mir'atus Sani Fadillah` | `24102047` | Flutter: Keranjang, Checkout, Rincian Pesanan , Widget|

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

Setelah migrasi dan seeder tersedia (A1-01 dan A1-03):

```bash
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

Alamat lokal: `http://127.0.0.1:8000`. Zona waktu aplikasi: `Asia/Jakarta`.

## 4. Menjalankan Flutter

```bash
flutter pub get
flutter run
```

Alamat server diatur di satu tempat: `lib/layanan/layanan_api.dart`.

- Emulator Android: `http://10.0.2.2:8000/api`
- Perangkat fisik: ganti dengan IP LAN laptop, misalnya `http://192.168.1.10:8000/api`, lalu jalankan `php artisan serve --host=0.0.0.0`.

Manifest Android utama sudah memuat izin `INTERNET` dan `android:usesCleartextTraffic="true"` agar HTTP lokal tidak diblokir.

## 5. Token Statis

Semua permintaan API memakai header `Authorization: Bearer <token>`.

| Pelanggan | Token |
|---|---|
| Pelanggan Uji 1 | `kelompok1-token-statis` |
| Pelanggan Uji 2 | `kelompok1-token-statis-2` |

Token salah atau kosong dibalas `401` dengan pembungkus yang sama.

## 6. Daftar Endpoint

Pembungkus respons: `status`, `code` (string), `message`, `data`, dan `errors` (khusus 422). Detail lengkap ada di [`docs/PRD.md`](docs/PRD.md) Bagian 6.

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

Dokumentasi API PDF disusun A3. Koleksi Postman diletakkan di `docs/`.

## 7. Simulasi Galat dan Jam Buka saat Demo

Gangguan hanya aktif bila `APP_ENV=local` (D-12). Tidak ada route tambahan.

- `SIMULASI_GALAT_500=true` membuat `GET /api/produk` membalas `500`.
- `SIMULASI_LAMBAT_DETIK=12` menunda respons agar batas waktu 10 detik di Flutter terpicu.
- Kembalikan kedua nilai ke `false` dan `0` setelah demo.

Mengubah jam buka lewat tinker (bukan mengubah jam laptop):

```bash
php artisan tinker --execute 'DB::table("toko")->update(["jam_buka" => "08:00", "jam_tutup" => "21:00"]);'
```

Lembar demo lengkap: [`docs/lembar-demo-langsung.md`](docs/lembar-demo-langsung.md).

## 8. Struktur Repositori

```text
.
|-- backend/     # Laravel 13 (REST API)
|-- lib/         # Flutter
|-- docs/        # PRD, lembar demo, koleksi Postman, PDF
|-- .github/     # template PR dan Issue
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

- Laravel 13 dan ekosistemnya (`laravel/framework`, `laravel/tinker`).
- Flutter 3.x dengan paket `http` (permintaan HTTP) dan `uuid` (kunci idempoten checkout).

Pustaka pengembangan: PHPUnit, Laravel Pint, Laravel Pail, Laravel Boost. Tidak ada payment gateway maupun API ekspedisi.

## 11. Status Kerangka

- Skeleton Laravel sudah memuat pembungkus respons, middleware `ForceJson` dan `PelangganStatis`, handler exception global, dan 16 route dengan controller stub (membalas 501 sampai pemiliknya mengisi).
- Inti Flutter sudah memuat `Konfigurasi`, `LayananApi` bertimeout 10 detik, exception bertipe, dan enum `KeadaanMuat`. Halaman uji sambung sementara di `main.dart` akan diganti `HalamanKatalog` oleh A4-02.
- Migrasi domain, seeder, dan seluruh endpoint diisi A1–A3. Model Dart dan halaman diisi A4–A5.
