/// Konfigurasi aplikasi MakanYuk! (Kelompok 1)
///
/// Berkas ini menjadi satu-satunya tempat alamat server diatur,
/// sesuai PRD Bagian 7.5 (`konfigurasi/konfigurasi.dart`).
class Konfigurasi {
  Konfigurasi._();

  /// Alamat server pengembangan.
  ///
  /// * Emulator Android: `http://10.0.2.2:8000/api` (menuju `localhost` di mesin host)
  /// * Perangkat fisik: ganti dengan IP LAN laptop, lalu jalankan
  ///   `php artisan serve --host=0.0.0.0`
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  /// Batas waktu setiap permintaan: 10 detik (PRD Bagian 4.3 butir 7).
  /// Bila lewat, pengguna memperoleh galat `GalatBatasWaktu` + tombol coba lagi.
  static const Duration batasWaktu = Duration(seconds: 10);
}
