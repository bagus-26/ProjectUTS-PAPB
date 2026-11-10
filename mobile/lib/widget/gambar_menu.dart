import 'package:flutter/material.dart';

import '../umum/tema_warna.dart';

class GambarMenu extends StatelessWidget {
  const GambarMenu({
    super.key,
    required this.nama,
    required this.kategori,
    this.fit = BoxFit.cover,
  });

  final String nama;
  final String kategori;
  final BoxFit fit;

  static const Map<String, String> _asetMenu = {
    'ayambakarmadu': 'Ayam Bakar Madu.jpg',
    'ayamgeprek': 'Ayam geprek.jpg',
    'ayampenyetsambalijo': 'ayam penyet sambel.jpg',
    'baksomalang': 'Bakso Malang.jpg',
    'escendol': 'Es Cendol.jpg',
    'esjeruk': 'Es jeruk.jpg',
    'esteh': 'Es Teh.jpg',
    'estehleci': 'es leci.jpg',
    'estehmanis': 'es_teh_manis.jpg',
    'jusalpukat': 'Jus alpukat.jpg',
    'kopisusugulaaren': 'Kopi Susu Gula Aren.jpg',
    'matchalatte': 'macha latte.jpg',
    'miegorengjawa': 'mie_goreng_jawa.jpg',
    'nasigorengspesial': 'Nasi Goreng Spesial.jpg',
    'nasigorengkampung': 'nasi goreng kampung.jpg',
    'nasipecel': 'Nasi Pecel.jpg',
    'pisanggorangcokelat': 'pisang goreng coklat.jpg',
    'rawondaging': 'Rawon Daging.jpg',
    'sateayammadura': 'sate ayam mdr.jpg',
    'sotoayamlamongan': 'Soto Lamongan.jpg',
    'sotolamongan': 'Soto Lamongan.jpg',
    'wedangjahe': 'Wedang Jahe.jpg',
  };

  @override
  Widget build(BuildContext context) {
    final namaNormal = _normalisasiNama(nama);
    final namaAset = _asetMenu[namaNormal];
    final ikon = kategori.toLowerCase().contains('minum')
        ? Icons.local_cafe_rounded
        : (kategori.toLowerCase().contains('snack')
              ? Icons.cookie_rounded
              : Icons.restaurant_rounded);

    return ColoredBox(
      color: TemaWarna.kremTua,
      child: namaAset == null
          ? _ikonCadangan(ikon)
          : Image.asset(
              'assets/images/menu/$namaAset',
              fit: fit,
              errorBuilder: (context, error, stackTrace) => _ikonCadangan(ikon),
            ),
    );
  }

  Widget _ikonCadangan(IconData ikon) {
    return Center(
      child: Icon(
        ikon,
        size: 38,
        color: TemaWarna.cokelatMuda,
      ),
    );
  }

  String _normalisasiNama(String nilai) =>
      nilai.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}
