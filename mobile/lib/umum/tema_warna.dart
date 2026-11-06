import 'package:flutter/material.dart';

/// Tema warna dan konstanta desain aplikasi MakanYuk! (Kelompok 1)
class TemaWarna {
  TemaWarna._();

  // Warna Utama
  static const Color cokelatUtama = Color(0xFF6D4C41);
  static const Color cokelatTua = Color(0xFF4E342E);
  static const Color cokelatMuda = Color(0xFF8D6E63);

  // Warna Latar & Netral
  static const Color latarKrem = Color(0xFFF9F6F0);
  static const Color latarPutih = Colors.white;
  static const Color kremTua = Color(0xFFEFE8DE);
  static const Color abuMuda = Color(0xFFF5F5F5);
  static const Color garisAbu = Color(0xFFEAEAEA);

  // Warna Teks
  static const Color teksUtama = Color(0xFF1E1E1E);
  static const Color teksSekunder = Color(0xFF757575);
  static const Color teksTerang = Colors.white;

  // Warna Aksen / Status
  static const Color hitamTombol = Color(0xFF191919);
  static const Color hijauBuka = Color(0xFF2E7D32);
  static const Color merahHabis = Color(0xFFD32F2F);
  static const Color kuningBintang = Color(0xFFFFA000);

  /// Helper pemformat rupiah tanpa pemisah ribuan aneh atau desimal
  /// Contoh: 18000 -> "Rp 18.000"
  static String formatRupiah(int nilai) {
    final teks = nilai.toString();
    final hasil = StringBuffer();
    for (var i = 0; i < teks.length; i++) {
      if (i > 0 && (teks.length - i) % 3 == 0) {
        hasil.write('.');
      }
      hasil.write(teks[i]);
    }
    return 'Rp $hasil';
  }
}

