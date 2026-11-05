import 'package:flutter/material.dart';
import '../umum/tema_warna.dart';
import '../widget/tombol_utama.dart';

/// Halaman Konfirmasi Pesanan Selesai
class HalamanKonfirmasiPesanan extends StatelessWidget {
  final String nomorPesanan;
  final int totalBayar;

  const HalamanKonfirmasiPesanan({
    super.key,
    required this.nomorPesanan,
    required this.totalBayar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: TemaWarna.hitamTombol,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pesanan Diterima!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Nomor Pesanan: $nomorPesanan\nTotal: ${TemaWarna.formatRupiah(totalBayar)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: TemaWarna.teksSekunder, height: 1.5),
              ),
              const SizedBox(height: 32),
              TombolUtama(
                teks: 'Kembali ke Katalog',
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

