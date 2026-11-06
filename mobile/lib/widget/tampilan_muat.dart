import 'package:flutter/material.dart';
import '../umum/tema_warna.dart';

/// Widget indikator keadaan muat (Loading State)
/// Sesuai Kriteria 7: Tampilan memuat eksplisit dan informatif
class TampilanMuat extends StatelessWidget {
  final String pesan;

  const TampilanMuat({
    super.key,
    this.pesan = 'Menyiapkan menu lezat untukmu...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TemaWarna.latarKrem,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: TemaWarna.cokelatUtama.withAlpha(25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(TemaWarna.cokelatUtama),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: TemaWarna.teksSekunder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

