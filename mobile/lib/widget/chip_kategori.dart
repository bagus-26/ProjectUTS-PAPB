import 'package:flutter/material.dart';
import '../umum/tema_warna.dart';

/// Widget pemilih kategori produk yang menyaring data via query parameter ?kategori=
/// Mendukung tampilan Pill (Semua Menu) dan Mode Ikon Lingkaran (Dashboard Utama)
class ChipKategori extends StatelessWidget {
  final List<String> daftarKategori;
  final String kategoriTerpilih;
  final ValueChanged<String> saatDipilih;
  final Map<String, int>? jumlahPerKategori;
  final bool modeIkon;

  const ChipKategori({
    super.key,
    required this.daftarKategori,
    required this.kategoriTerpilih,
    required this.saatDipilih,
    this.jumlahPerKategori,
    this.modeIkon = false,
  });

  IconData _ikonKategori(String nama) {
    final lower = nama.toLowerCase();
    if (lower.contains('minum')) {
      return Icons.local_cafe_outlined;
    } else if (lower.contains('makan')) {
      return Icons.restaurant_outlined;
    } else if (lower.contains('snack')) {
      return Icons.cookie_outlined;
    }
    return Icons.grid_view_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (modeIkon) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: daftarKategori.map((kategori) {
          final isTerpilih = kategoriTerpilih.toLowerCase() == kategori.toLowerCase();
          return InkWell(
            onTap: () => saatDipilih(kategori),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: isTerpilih ? TemaWarna.hitamTombol : TemaWarna.kremTua,
                      shape: BoxShape.circle,
                      boxShadow: isTerpilih
                          ? [
                              BoxShadow(
                                color: Colors.black.withAlpha(30),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Icon(
                      _ikonKategori(kategori),
                      color: isTerpilih ? Colors.white : TemaWarna.cokelatUtama,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kategori,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isTerpilih ? FontWeight.w700 : FontWeight.w500,
                      color: isTerpilih ? TemaWarna.teksUtama : TemaWarna.teksSekunder,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    // Default: Tampilan horizontal pill (Screenshot 2: Semua 16, Minuman 8, Makanan 5, Snack 3)
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: daftarKategori.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final kategori = daftarKategori[index];
          final isTerpilih = kategoriTerpilih.toLowerCase() == kategori.toLowerCase();
          final int? total = jumlahPerKategori?[kategori];

          return InkWell(
            onTap: () => saatDipilih(kategori),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isTerpilih ? TemaWarna.hitamTombol : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isTerpilih ? TemaWarna.hitamTombol : TemaWarna.garisAbu,
                ),
                boxShadow: isTerpilih
                    ? [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    kategori,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isTerpilih ? FontWeight.w700 : FontWeight.w500,
                      color: isTerpilih ? Colors.white : TemaWarna.teksUtama,
                    ),
                  ),
                  if (total != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '$total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isTerpilih
                            ? Colors.white.withAlpha(180)
                            : TemaWarna.teksSekunder,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
