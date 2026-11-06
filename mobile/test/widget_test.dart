import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projek_makanyuk/model/produk.dart';
import 'package:projek_makanyuk/widget/chip_kategori.dart';
import 'package:projek_makanyuk/widget/pemilih_jumlah.dart';

void main() {
  test('Model Produk parse JSON dengan atribut khas Domain 1', () {
    final json = {
      'id': 1,
      'nama': 'Iced Latte',
      'harga': 18000,
      'kategori': 'Minuman',
      'stok': 10,
      'tersedia': true,
      'deskripsi': 'Kopi susu dingin',
      'varian_porsi': ['Reguler', 'Large'],
      'tingkat_kepedasan': ['Normal Ice', 'Less Ice'],
    };

    final produk = Produk.fromJson(json);

    expect(produk.id, 1);
    expect(produk.nama, 'Iced Latte');
    expect(produk.harga, 18000);
    expect(produk.dapatDipesan, true);
    expect(produk.varianPorsi, contains('Large'));
    expect(produk.tingkatKepedasan, contains('Less Ice'));
  });

  testWidgets('PemilihJumlah menaikkan dan menurunkan angka secara benar',
      (WidgetTester tester) async {
    int nilai = 2;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return PemilihJumlah(
                nilai: nilai,
                min: 1,
                max: 5,
                saatBerubah: (baru) {
                  setState(() => nilai = baru);
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('2'), findsOneWidget);

    // Tekan tombol tambah (+)
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(nilai, 3);
  });

  testWidgets('ChipKategori menampilkan daftar kategori',
      (WidgetTester tester) async {
    String terpilih = 'Semua';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChipKategori(
            daftarKategori: const ['Semua', 'Minuman', 'Makanan'],
            kategoriTerpilih: terpilih,
            saatDipilih: (kat) => terpilih = kat,
          ),
        ),
      ),
    );

    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Minuman'), findsOneWidget);
    expect(find.text('Makanan'), findsOneWidget);
  });
}
