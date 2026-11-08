import 'package:flutter/foundation.dart';

/// Konfigurasi aplikasi MakanYuk! (Kelompok 1)
///
/// Berkas ini menjadi satu-satunya tempat alamat server diatur,
/// sesuai PRD Bagian 7.5 (`konfigurasi/konfigurasi.dart`).
class Konfigurasi {
  Konfigurasi._();

  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Alamat server pengembangan. Bisa dioverride dengan `--dart-define`.
  ///
  /// Android Emulator menggunakan alamat khusus untuk mengakses komputer host.
  /// Untuk perangkat fisik atau emulator lain, gunakan `API_BASE_URL`.
  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:8000/api',
      _ => 'http://localhost:8000/api',
    };
  }

  /// Batas waktu setiap permintaan: 10 detik (PRD Bagian 4.3 butir 7).
  /// Bila lewat, pengguna memperoleh galat `GalatBatasWaktu` + tombol coba lagi.
  static const Duration batasWaktu = Duration(seconds: 10);
}
