import 'package:flutter/material.dart';

import '../layanan/galat_api.dart';
import '../umum/tema_warna.dart';

/// Pesan galat yang ditampilkan pengguna: validasi 422 dipecah per kolom,
/// 409 `toko_tutup` menampilkan jam operasional dari server (PRD Bagian 7.3).
String pesanGalat(GalatApi g) {
  if (g.jenis == JenisGalat.validasi &&
      g.errors != null &&
      g.errors!.isNotEmpty) {
    final rincian = g.errors!.values.expand((baris) => baris).join('\n');
    if (rincian.isNotEmpty) return rincian;
  }

  if (g.jenis == JenisGalat.bentrok && g.data?['alasan'] == 'toko_tutup') {
    final buka = g.data?['jam_buka']?.toString() ?? '08:00';
    final tutup = g.data?['jam_tutup']?.toString() ?? '22:00';
    return 'Toko sedang tutup. Pesanan hanya diproses pukul $buka – $tutup WIB.';
  }

  return g.pesan;
}

/// Tampilkan galat sebagai SnackBar merah konsisten di seluruh aplikasi.
///
/// Caller bertanggung jawab memastikan `mounted` sebelum memanggil (sama
/// seperti perilaku lama di setiap halaman).
void tampilkanGalat(BuildContext context, GalatApi g) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: TemaWarna.merahHabis,
        duration: const Duration(seconds: 4),
        content: Text(pesanGalat(g)),
      ),
    );
}
