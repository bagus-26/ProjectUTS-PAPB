import 'package:flutter/material.dart';

import '../widget/navigasi_bawah.dart';
import 'halaman_katalog.dart';
import 'halaman_menu_favorit.dart';
import 'halaman_keranjang.dart';
import 'halaman_riwayat_pesanan.dart';
import 'halaman_akun.dart';

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

  Future<void> _bukaKeranjang() async {
    await Navigator.of(context).push(
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
      HalamanRiwayatPesanan(
        saatPilihMenu: () => _pindahKeTab(0),
      ),
      const HalamanMenuFavorit(),
      HalamanAkun(saatBukaRiwayat: () => _pindahKeTab(1)),
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
