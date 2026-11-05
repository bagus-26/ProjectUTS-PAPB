import 'package:flutter/material.dart';
import 'package:mobile/halaman/halaman_utama.dart';

import '../widget/navigasi_bawah.dart
import 'halaman_menu_favorit.dart';
import 'halaman_keranjang.dart';
import 'halaman_riwayat_pesanan.dart';
import 'halaman_profil.dart';

class HalamanUtama extends StatefulWidget {
  const HalamanUtama({super.key});

  @override
  State<HalamanUtama> createState() => _HalamanUtamaState()=> _HalamanUtamaState();

}

class _HalamanUtamaState extends State<HalamanUtama> {
  int _indeks = 0;

  final List<Widget> _-halaman = <widget>[
  HalamanDashboard();
  HalamanMenuFavorit();
  HalamanKeranjang();
  HalamanRiwayatPesanan();
  HalamanProfil();
  ];


@overide
widget build(BuildContext context) {
return Scaffold(
body: IndexedStack(
index: _indeks,
childeren: _halaman,
bottomNavigationBar: NavigasiBawah(
indeks: _indeks,
onTap: (int indeks) {
setState(() {
_indeks = indeks;
});
},  

)
}