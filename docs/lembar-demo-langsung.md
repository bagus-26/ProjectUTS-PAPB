# Lembar Demo Langsung — Pertemuan 8

Pengganti video demo. Pertemuan 8 meminta demonstrasi satu alur yang diundi penguji, jadi seluruh alur harus siap kapan saja.

## Persiapan sebelum sesi

> **Peringatan:** `migrate:fresh --seed` menghapus seluruh tabel dan data pada database yang dipilih sebelum menjalankan migrasi ulang. Jalankan hanya pada database lokal/demo yang boleh dihapus. Pastikan konfigurasi `.env` menunjuk ke database demo yang benar dan cadangkan data penting terlebih dahulu.

- [ ] `php artisan migrate:fresh --seed` agar data bersih, lalu `php artisan serve`.
- [ ] Emulator hidup dan aplikasi sudah tersambung.
- [ ] `SIMULASI_GALAT_500=false` dan `SIMULASI_LAMBAT_DETIK=0`.
- [ ] `toko.jam_buka`–`toko.jam_tutup` mencakup waktu sesi (08.00–21.00 WIB).
- [ ] Postman terbuka dengan koleksi dan variabel lingkungan yang benar.
- [ ] Klien SQL (phpMyAdmin/MySQL Workbench) terbuka untuk memeriksa stok.

## Alur yang mungkin diminta

| Alur | Langkah singkat |
|---|---|
| Katalog | Daftar tampil, filter kategori, cari nama (permintaan lewat server), produk habis ditandai dan tombol mati |
| Keranjang | Rincian produk, pilih Jumbo + pedas + catatan, tambah, ubah jumlah, hapus; subtotal dari server |
| Checkout sukses | Isi formulir, ganti kurir (ongkir berubah), 201, rincian pesanan, Bayar (simulasi), status berubah, riwayat |
| Aturan jam buka | Ubah `toko.jam_tutup` ke jam yang sudah lewat, checkout ditolak 409, kembalikan jam |
| Kelola produk | Tambah, ubah, hapus (dialog konfirmasi), daftar menyegarkan diri |
| Konsistensi | Tekan checkout dua kali, satu pesanan; cek stok di basis data |
| Lima galat | Matikan server (sambungan), `SIMULASI_LAMBAT_DETIK=12` (timeout), alamat kosong (422), jumlah melebihi stok (409), `SIMULASI_GALAT_500=true` (500) |

## Perintah bantu

```bash
# Jalankan hanya setelah memastikan database aktif adalah database demo yang boleh dihapus.
php artisan migrate:fresh --seed
php artisan serve --host=0.0.0.0
```

Sebelum menguji aturan jam buka, catat nilai awal `jam_buka` dan `jam_tutup` pada tabel `toko`. Setelah pengujian, pulihkan nilai yang dicatat; jangan mengasumsikan jam tutup awal selalu `21:00`.

```bash
php artisan tinker --execute 'DB::table("toko")->update(["jam_tutup" => "00:00"]);'
# Ganti JAM_TUTUP_AWAL dengan nilai yang dicatat sebelum pengujian.
php artisan tinker --execute 'DB::table("toko")->update(["jam_tutup" => "JAM_TUTUP_AWAL"]);'
```

## Setelah demo

- Kembalikan `SIMULASI_*` ke nilai normal.
- Kembalikan jam buka toko.
- Catat alur yang diminta penguji dan kendala yang muncul.
