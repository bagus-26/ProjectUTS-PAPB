import 'package:flutter/material.dart';
import '../umum/tema_warna.dart';

/// Widget pengubah kuantitas item (Quantity Selector)
/// Digunakan di Halaman Rincian Produk dan Keranjang Belanja
class PemilihJumlah extends StatelessWidget {
  final int nilai;
  final int min;
  final int max;
  final ValueChanged<int> saatBerubah;
  final double tinggi;

  const PemilihJumlah({
    super.key,
    required this.nilai,
    required this.saatBerubah,
    this.min = 1,
    this.max = 99,
    this.tinggi = 46,
  });

  @override
  Widget build(BuildContext context) {
    final bool bisaKurang = nilai > min;
    final bool bisaTambah = nilai < max;

    return Container(
      height: tinggi,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: TemaWarna.abuMuda,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TemaWarna.garisAbu),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tombol Kurang (-)
          InkWell(
            onTap: bisaKurang ? () => saatBerubah(nilai - 1) : null,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 36,
              height: tinggi,
              child: Icon(
                Icons.remove_rounded,
                size: 20,
                color: bisaKurang ? TemaWarna.teksUtama : Colors.grey.shade400,
              ),
            ),
          ),
          // Angka Jumlah
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$nilai',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: TemaWarna.teksUtama,
              ),
            ),
          ),
          // Tombol Tambah (+)
          InkWell(
            onTap: bisaTambah ? () => saatBerubah(nilai + 1) : null,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 36,
              height: tinggi,
              child: Icon(
                Icons.add_rounded,
                size: 20,
                color: bisaTambah ? TemaWarna.teksUtama : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

