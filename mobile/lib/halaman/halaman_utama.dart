import 'package:flutter/material.dart';

import '../widget/navigasi_bawah.dart';
import 'halaman_katalog.dart';
import 'halaman_keranjang.dart';
import 'halaman_menu_favorit.dart';
import 'halaman_profil.dart';
import 'halaman_riwayat_pesanan.dart';

/// Halaman Kontainer Utama Aplikasi MakanYuk!
/// Mengelola perpindahan 4 tab navigasi bawah secara responsif
class HalamanUtama extends StatefulWidget {
  const HalamanUtama({super.key});

  @override
  State<HalamanUtama> createState() => _HalamanUtamaState();
}

class _HalamanUtamaState extends State<HalamanUtama> {
  int _indeks = 0;

  void _pindahKeTab(int indeks) {
    setState(() {
      _indeks = indeks;
    });
  }

  void _bukaKeranjang() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HalamanKeranjang(
          saatPilihMenu: () {
            Navigator.of(context).pop();
            _pindahKeTab(0);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> halaman = [
      HalamanKatalog(
        saatBukaKeranjang: _bukaKeranjang,
      ),
      const HalamanRiwayatPesanan(),
      HalamanMenuFavorit(
        saatPilihMenu: () => _pindahKeTab(0),
      ),
      const HalamanProfil(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _indeks,
        children: halaman,
      ),
      bottomNavigationBar: NavigasiBawah(
        indeks: _indeks,
        onTap: _pindahKeTab,
      ),
    );
  }
}
