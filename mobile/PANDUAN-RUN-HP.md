# Menjalankan MakanYuk! di HP Android (Windows)

Panduan ini untuk menjalankan aplikasi Flutter di HP Android fisik yang tersambung
ke laptop lewat kabel USB. HP dan laptop harus berada di jaringan Wi-Fi yang sama
agar aplikasi di HP dapat mengakses backend Laravel di laptop.

## 1. Persiapan

Pasang dan siapkan:

- Flutter yang menyertakan Dart 3.13.3 atau lebih baru.
- Android Studio dan Android SDK Platform-Tools (`adb`).
- PHP 8.3 atau lebih baru, Composer, dan MySQL 8.
- HP Android, kabel data USB, dan akses ke jaringan Wi-Fi yang sama dengan laptop.

Periksa Flutter dan Android sebelum mulai:

```powershell
flutter --version
flutter doctor
```

Di HP, aktifkan **Opsi developer** dan **USB debugging**, sambungkan kabel,
lalu setujui permintaan debugging yang muncul di layar HP. Pastikan perangkat
terdeteksi:

```powershell
flutter devices
```

Catat ID HP yang ditampilkan. Jika belum muncul, periksa kabel data, pengaturan
USB debugging, dan status perangkat dengan `adb devices`.

## 2. Siapkan backend Laravel

Buka PowerShell pertama di folder proyek. Perintah berikut menyiapkan dependensi
satu kali:

```powershell
cd backend
composer install
if (-not (Test-Path .env)) {
    Copy-Item .env.example .env
    php artisan key:generate
}
```

Buat database MySQL bernama `FastFoodUTS`, lalu sesuaikan `DB_HOST`, `DB_PORT`,
`DB_DATABASE`, `DB_USERNAME`, dan `DB_PASSWORD` di `backend/.env` dengan MySQL
di laptop tersebut. Jika `backend/.env` sudah ada tetapi `APP_KEY` masih kosong,
buat app key satu kali dengan `php artisan key:generate`. Isi database dengan
migrasi serta data demo:

```powershell
php artisan migrate --seed
```

Jalankan server Laravel dan biarkan terminal ini tetap terbuka:

```powershell
php artisan serve --host=0.0.0.0 --port=8000
```

Opsi `--host=0.0.0.0` diperlukan agar HP dapat mengakses server melalui Wi-Fi.
Jangan gunakan `php artisan migrate:fresh`, karena perintah itu menghapus isi
database.

## 3. Cari alamat Wi-Fi laptop

Di PowerShell kedua, cari IPv4 laptop:

```powershell
ipconfig
```

Pilih **IPv4 Address** pada bagian adaptor Wi-Fi yang aktif. Jangan gunakan
alamat `127.0.0.1`, alamat adaptor virtual seperti VMware, atau alamat dari contoh
di panduan ini. IP laptop dapat berubah saat tersambung ke jaringan lain.

Tes server dari laptop dengan mengganti `192.168.1.10` di bawah memakai IPv4
laptop yang sebenarnya:

```powershell
Invoke-WebRequest http://192.168.1.10:8000/up
```

Respons HTTP 200 berarti backend aktif. Jika HP tidak dapat membuka
`http://192.168.1.10:8000/up` di browser HP, periksa bahwa kedua perangkat
menggunakan Wi-Fi yang sama. Pada Windows Firewall, izinkan koneksi PHP pada
jaringan **Private** atau tambahkan aturan masuk TCP port 8000 yang dibatasi ke
**Local subnet**. Hindari mengizinkan akses dari jaringan **Public**.

## 4. Jalankan aplikasi di HP

Di PowerShell kedua, dari folder proyek:

```powershell
cd mobile
flutter pub get
flutter run -d e43b9732 --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

Ganti `e43b9732` dengan ID HP dari `flutter devices` dan ganti IP contoh dengan
IPv4 laptop yang ditemukan sebelumnya. Perintah ini mengompilasi, memasang, dan
membuka aplikasi di HP. Terminal `flutter run` dapat dibiarkan aktif: tekan `r`
untuk hot reload dan `R` untuk hot restart.

## 5. Buat APK debug

Untuk membuat APK yang bisa dipasang di HP, jalankan perintah berikut dari folder
`mobile` dengan IP laptop yang benar:

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

APK berada di:

```text
mobile\build\app\outputs\flutter-apk\app-debug.apk
```

APK menyimpan alamat backend yang diberikan ketika build. Jika IP laptop berubah,
build ulang APK dengan alamat yang baru. HP yang menjalankan APK juga harus
berada di Wi-Fi yang sama dengan laptop server, dan backend harus tetap aktif.
APK debug ditujukan untuk pengujian, bukan distribusi produksi.

## 6. Kendala umum

- **Perangkat tidak terdeteksi:** aktifkan USB debugging, setujui dialog di HP,
  coba kabel USB lain yang mendukung transfer data, lalu jalankan `flutter devices`.
- **Koneksi timeout:** pastikan backend masih berjalan, alamat IP terbaru sudah
  digunakan, kedua perangkat berada di jaringan yang sama, dan Firewall Windows
  mengizinkan TCP port 8000 pada jaringan Private.
- **Jangan gunakan `localhost` atau `127.0.0.1` pada HP.** Alamat tersebut
  menunjuk ke HP itu sendiri, bukan laptop backend.
- **Respons 401 pada endpoint API:** endpoint dilindungi autentikasi; kode 401
  saat diuji tanpa autentikasi berarti server dapat dijangkau. Untuk memastikan
  data demo tersedia, jalankan `php artisan migrate --seed`.
- **Build pertama lebih lama:** Gradle perlu mengompilasi plugin Android.
  Proyek ini menonaktifkan cache incremental Kotlin di
  `android/gradle.properties` untuk menghindari kegagalan cache lintas drive
  pada Windows; build berikutnya biasanya lebih cepat.

Jangan membagikan `backend/.env`; file tersebut memuat konfigurasi lokal dan app
key untuk backend masing-masing.
