import 'package:flutter/material.dart';
import '../umum/tema_warna.dart';

/// Widget tampilan keadaan kosong (Empty State)
/// Sesuai Kriteria 7: Keadaan kosong dipisahkan secara eksplisit dari galat
class TampilanKosong extends StatelessWidget {
  final String judul;
  final String pesan;
  final IconData ikon;
  final String? teksAksi;
  final VoidCallback? saatAksiDitekan;

  const TampilanKosong({
    super.key,
    this.judul = 'Menu Belum Ditemukan',
    this.pesan =
        'Menu yang kamu cari belum tersedia. Coba gunakan kata kunci lain atau ubah filter kategori.',
    this.ikon = Icons.search_off_rounded,
    this.teksAksi,
    this.saatAksiDitekan,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: TemaWarna.kremTua,
                shape: BoxShape.circle,
              ),
              child: Icon(
                ikon,
                size: 48,
                color: TemaWarna.cokelatUtama,
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
              pesan,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: TemaWarna.teksSekunder,
              ),
            ),
            if (teksAksi != null && saatAksiDitekan != null) ...[
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: saatAksiDitekan,
                style: FilledButton.styleFrom(
                  backgroundColor: TemaWarna.hitamTombol,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  teksAksi!,
                  style: const TextStyle(
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

