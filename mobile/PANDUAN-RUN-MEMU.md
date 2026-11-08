# Menjalankan MakanYuk! di MEmu Player

Panduan ini untuk menjalankan aplikasi Flutter dan backend Laravel di laptop Windows yang sama, lalu membuka aplikasi Android-nya lewat MEmu Player.

## 1. Persiapan laptop

Pasang dan siapkan:

- Flutter SDK dengan Dart minimal 3.13.3 (sesuai `environment.sdk` di `pubspec.yaml`).
- Android Studio / Android SDK, termasuk Android SDK Platform-Tools.
- MEmu Player.
- PHP 8.3+, Composer, dan MySQL.

Buka PowerShell di folder proyek dan periksa Flutter:

```powershell
flutter --version
flutter doctor
```

Pastikan folder `mobile` tetap berisi `pubspec.yaml` dan `pubspec.lock`. Jangan menghapus atau mengubah versi dependensi hanya untuk memilih emulator: `pubspec.yaml` mengatur paket dan versi SDK Flutter, bukan alamat backend.

## 2. Siapkan backend

Jalankan MySQL, lalu siapkan Laravel satu kali:

```powershell
cd backend
composer install
Copy-Item .env.example .env
php artisan key:generate
```

Buat basis data `FastFoodUTS` di MySQL, lalu sesuaikan konfigurasi `DB_*` di `backend/.env`. Jalankan migrasi dan seeder:

```powershell
php artisan migrate --seed
```

Biarkan terminal backend tetap terbuka:

```powershell
php artisan serve --host=0.0.0.0 --port=8000
```

Opsi `--host=0.0.0.0` membuat server dapat dijangkau dari jaringan virtual MEmu. Jika Windows Firewall menampilkan permintaan izin untuk PHP, izinkan akses pada jaringan privat.

## 3. Hubungkan MEmu ke Flutter

1. Buka MEmu Player dan tunggu Android selesai menyala.
2. Pastikan Android debugging/ADB aktif pada pengaturan MEmu.
3. Buka PowerShell di folder proyek dan cek apakah Flutter melihat emulator:

```powershell
cd mobile
flutter devices
```

Jika perangkat belum muncul, gunakan `adb.exe` dari folder Android SDK `platform-tools`. MEmu sering menggunakan port ADB `21503`; periksa port yang ditampilkan pada pengaturan MEmu jika berbeda:

```powershell
adb connect 127.0.0.1:21503
flutter devices
```

Jika `adb` tidak dikenali, jalankan dengan path lengkap, misalnya:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" connect 127.0.0.1:21503
```

Ganti path di atas jika Android SDK terpasang di lokasi lain.

## 4. Jalankan aplikasi dan arahkan ke backend

Gunakan alamat IP LAN laptop yang menjalankan backend sebagai `API_BASE_URL`. Cari alamat IPv4 laptop dengan:

```powershell
ipconfig
```

Pilih IPv4 pada adaptor jaringan yang sedang dipakai, lalu jalankan dari folder `mobile`:

```powershell
flutter pub get
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

Ganti `192.168.1.10` dengan IPv4 laptop yang sebenarnya dan `emulator-5554` dengan ID yang ditampilkan oleh `flutter devices`. Jika hanya ada satu perangkat, cukup jalankan:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

Laptop dan MEmu harus dapat menjangkau alamat tersebut. Jika MEmu tidak dapat mengakses IP LAN laptop, sambungkan lewat ADB reverse sebagai alternatif:

```powershell
adb reverse tcp:8000 tcp:8000
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Saat sesi `flutter run` aktif, tekan `r` untuk hot reload dan `R` untuk hot restart.

## 5. Koneksi dan kendala umum

- Tes server dari laptop dengan membuka `http://127.0.0.1:8000/up`; respons yang berhasil menandakan Laravel berjalan.
- Jangan gunakan `localhost` atau `127.0.0.1` sebagai alamat backend di MEmu kecuali memakai `adb reverse`. Tanpa reverse, alamat itu menunjuk ke Android virtual, bukan laptop.
- Jika koneksi timeout, pastikan Laravel masih berjalan, alamat IP dan port benar, MEmu dapat menjangkau laptop, serta Windows Firewall mengizinkan koneksi TCP port 8000.
- Android sudah memerlukan izin `INTERNET` dan `android:usesCleartextTraffic="true"` untuk HTTP lokal; pengaturannya ada di `android/app/src/main/AndroidManifest.xml`.
- API proyek masih memiliki controller yang belum diimplementasikan. Endpoint tersebut dapat mengembalikan HTTP 501 walaupun koneksi aplikasi ke server sudah benar.
