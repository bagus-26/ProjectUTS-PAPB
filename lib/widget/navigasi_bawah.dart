import 'package:flutter/material.dart';
import '../umum/tema_warna.dart';

/// Widget bilah navigasi bawah (Bottom Navigation Bar)
/// Menampilkan 4 tab utama: Home, Pesanan, Favorit, Profil sesuai UI rancangan
class NavigasiBawah extends StatelessWidget {
  final int indeks;
  final ValueChanged<int> onTap;

  const NavigasiBawah({
    super.key,
    required this.indeks,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: TemaWarna.garisAbu, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _itemNavigasi(
                posisi: 0,
                ikon: Icons.home_outlined,
                ikonAktif: Icons.home_rounded,
                label: 'Home',
              ),
              _itemNavigasi(
                posisi: 1,
                ikon: Icons.receipt_long_outlined,
                ikonAktif: Icons.receipt_long_rounded,
                label: 'Pesanan',
              ),
              _itemNavigasi(
                posisi: 2,
                ikon: Icons.favorite_border_rounded,
                ikonAktif: Icons.favorite_rounded,
                label: 'Favorit',
              ),
              _itemNavigasi(
                posisi: 3,
                ikon: Icons.person_outline_rounded,
                ikonAktif: Icons.person_rounded,
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemNavigasi({
    required int posisi,
    required IconData ikon,
    required IconData ikonAktif,
    required String label,
  }) {
    final bool aktif = indeks == posisi;

    return InkWell(
      onTap: () => onTap(posisi),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              aktif ? ikonAktif : ikon,
              color: aktif ? TemaWarna.cokelatUtama : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                color: aktif ? TemaWarna.cokelatUtama : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

