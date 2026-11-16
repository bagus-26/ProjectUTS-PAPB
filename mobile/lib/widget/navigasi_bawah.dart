import 'package:flutter/material.dart';
import '../umum/tema_warna.dart';

/// Widget bilah navigasi bawah (Bottom Navigation Bar)
/// Menampilkan 4 tab utama sesuai `home.png`:
/// Home, Riwayat Pesanan, Favorit, dan Profil.
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
      color: Colors.white,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: TemaWarna.garisAbu),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
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
                label: 'Riwayat Pesanan',
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

    return Expanded(
      child: InkWell(
        onTap: () => onTap(posisi),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                aktif ? ikonAktif : ikon,
                color: aktif
                    ? TemaWarna.cokelatPekat
                    : const Color(0xFF9A9A9A),
                size: 23,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: -0.1,
                  fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                  color: aktif
                      ? TemaWarna.cokelatPekat
                      : const Color(0xFF8A8A8A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
