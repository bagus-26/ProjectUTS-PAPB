import 'package:flutter/material.dart';
import '../layanan/galat_api.dart';
import '../umum/tema_warna.dart';

/// Widget tampilan keadaan galat (Error State)
/// Sesuai Kriteria 6: Menangani 5 jenis galat dengan tampilan dan pesan berbeda
class TampilanGalat extends StatelessWidget {
  final GalatApi? galat;
  final String? pesanKustom;
  final VoidCallback? saatCobaLagi;

  const TampilanGalat({
    super.key,
    this.galat,
    this.pesanKustom,
    this.saatCobaLagi,
  });

  @override
  Widget build(BuildContext context) {
    final jenis = galat?.jenis ?? JenisGalat.umum;

    // Menentukan ikon dan judul spesifik berdasarkan jenis galat
    final (IconData ikon, String judul, String deskripsi) = switch (jenis) {
      JenisGalat.tidakAdaSambungan => (
          Icons.wifi_off_rounded,
          'Tidak Ada Sambungan',
          galat?.pesan ??
              'Koneksi ke server gagal. Pastikan jaringan aktif atau server Laravel telah dinyalakan.'
        ),
      JenisGalat.batasWaktu => (
          Icons.timer_off_outlined,
          'Batas Waktu Terlampaui',
          galat?.pesan ??
              'Server tidak membalas dalam 10 detik. Silakan periksa jaringan dan coba lagi.'
        ),
      JenisGalat.validasi => (
          Icons.error_outline_rounded,
          'Validasi Gagal',
          galat?.pesan ?? 'Data yang dikirim tidak lengkap atau tidak sesuai.'
        ),
      JenisGalat.bentrok => (
          Icons.warning_amber_rounded,
          'Permintaan Ditolak',
          galat?.pesan ??
              'Permintaan bertentangan dengan kondisi server (misalnya stok telah habis).'
        ),
      JenisGalat.galatServer => (
          Icons.dns_rounded,
          'Gangguan Server',
          'Terjadi masalah pada server. Tim kami sedang menanganinya, silakan coba beberapa saat lagi.'
        ),
      _ => (
          Icons.cloud_off_rounded,
          'Gagal Memuat Data',
          pesanKustom ?? galat?.pesan ?? 'Terjadi kesalahan sistem yang tidak terduga.'
        ),
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                ikon,
                size: 46,
                color: TemaWarna.merahHabis,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              judul,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: TemaWarna.teksUtama,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              deskripsi,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: TemaWarna.teksSekunder,
              ),
            ),
            if (saatCobaLagi != null) ...[
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: saatCobaLagi,
                style: OutlinedButton.styleFrom(
                  foregroundColor: TemaWarna.cokelatUtama,
                  side: const BorderSide(color: TemaWarna.cokelatUtama, width: 1.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text(
                  'Coba Lagi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

