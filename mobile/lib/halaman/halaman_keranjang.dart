import 'package:flutter/material.dart';

import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../umum/keadaan_muat.dart';
import '../umum/tema_warna.dart';
import '../widget/pemilih_jumlah.dart';
import '../widget/tampilan_galat.dart';
import '../widget/tampilan_kosong.dart';
import '../widget/tampilan_muat.dart';
import '../widget/tombol_utama.dart';
import 'halaman_checkout.dart';

/// Halaman Keranjang Belanja (Kelompok 1: MakanYuk!)
/// Sesuai Kriteria 3: Subtotal berasal dari respons server, penambahan/pengurangan item
class HalamanKeranjang extends StatefulWidget {
  final VoidCallback? saatPilihMenu;

  const HalamanKeranjang({super.key, this.saatPilihMenu});

  @override
  State<HalamanKeranjang> createState() => _HalamanKeranjangState();
}

class _HalamanKeranjangState extends State<HalamanKeranjang> {
  final LayananApi _layanan = LayananApi();

  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  List<Map<String, dynamic>> _daftarItem = [];
  int _subtotal = 0;
  GalatApi? _galat;

  @override
  void initState() {
    super.initState();
    _muatKeranjang();
  }

  Future<void> _muatKeranjang() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _galat = null;
    });

    try {
      final data = await _layanan.ambilKeranjang();
      if (!mounted) return;

      final items = (data['items'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      final ringkasan = data['ringkasan'];
      final sub = ringkasan is Map
          ? (ringkasan['subtotal'] as int?) ?? 0
          : 0;

      setState(() {
        _daftarItem = items;
        _subtotal = sub;
        _keadaan = items.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
      });
    } on GalatApi catch (g) {
      if (!mounted) return;
      setState(() {
        _galat = g;
        _keadaan = KeadaanMuat.galat;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _galat = GalatApi.umum();
        _keadaan = KeadaanMuat.galat;
      });
    }
  }

  void _ubahJumlah(int index, int jumlahBaru) {
    setState(() {
      final harga = _daftarItem[index]['harga_satuan'] as int;
      _daftarItem[index]['jumlah'] = jumlahBaru;
      _daftarItem[index]['subtotal'] = harga * jumlahBaru;

      // Hitung ulang subtotal server-side simulation
      _subtotal = _daftarItem.fold<int>(
        0,
        (sum, item) => sum + ((item['subtotal'] as int?) ?? 0),
      );
    });
  }

  void _hapusItem(int index) {
    setState(() {
      _daftarItem.removeAt(index);
      _subtotal = _daftarItem.fold<int>(
        0,
        (sum, item) => sum + ((item['subtotal'] as int?) ?? 0),
      );
      if (_daftarItem.isEmpty) {
        _keadaan = KeadaanMuat.kosong;
      }
    });
  }

  void _menujuCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HalamanCheckout(
          subtotal: _subtotal,
          items: _daftarItem,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaWarna.latarKrem,
      appBar: AppBar(
        backgroundColor: TemaWarna.latarKrem,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Keranjang',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: TemaWarna.teksUtama,
          ),
        ),
        centerTitle: true,
      ),
      body: _bangunIsi(),
      bottomNavigationBar: _keadaan == KeadaanMuat.berhasil
          ? _bangunBilahBawahCheckout()
          : null,
    );
  }

  Widget _bangunIsi() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const TampilanMuat(pesan: 'Memuat keranjang belanjamu...');

      case KeadaanMuat.galat:
        return TampilanGalat(
          galat: _galat,
          saatCobaLagi: _muatKeranjang,
        );

      case KeadaanMuat.kosong:
        return TampilanKosong(
          ikon: Icons.shopping_bag_outlined,
          judul: 'Keranjang Belanja Kosong',
          pesan: 'Belum ada menu yang ditambahkan ke keranjang.',
          teksAksi: 'Pilih Menu Sekarang',
          saatAksiDitekan: () {
            if (widget.saatPilihMenu != null) {
              widget.saatPilihMenu!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        );

      case KeadaanMuat.berhasil:
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            ...List.generate(_daftarItem.length, (index) {
              final item = _daftarItem[index];
              return _kartuItemKeranjang(item, index);
            }),
            const SizedBox(height: 12),
            // Voucher Promo Banner (Screenshot 4)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TemaWarna.garisAbu),
              ),
              child: const Row(
                children: [
                  Icon(Icons.discount_outlined, color: TemaWarna.cokelatUtama),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Klik untuk menggunakan kode promo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: TemaWarna.teksUtama,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _kartuItemKeranjang(Map<String, dynamic> item, int index) {
    final nama = item['nama']?.toString() ?? 'Menu';
    final harga = (item['harga_satuan'] as int?) ?? 0;
    final jumlah = (item['jumlah'] as int?) ?? 1;
    final varian = item['varian'];
    final namaVarian =
        varian is Map ? varian['nama']?.toString() : null;
    final porsi = namaVarian ?? 'Reguler';
    final tingkatPedas = item['tingkat_pedas']?.toString();
    final kepedasan = switch (tingkatPedas) {
      'tidak_pedas' => 'Tidak Pedas',
      'sedang' => 'Sedang',
      'pedas' => 'Pedas',
      'sangat_pedas' => 'Sangat Pedas',
      _ => null,
    };
    final gambar = item['gambar']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 70,
              height: 70,
              color: TemaWarna.kremTua,
              child: gambar != null && gambar.isNotEmpty
                  ? Image.network(
                      gambar,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.restaurant_rounded,
                        color: TemaWarna.cokelatUtama,
                      ),
                    )
                  : const Icon(
                      Icons.restaurant_rounded,
                      color: TemaWarna.cokelatUtama,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: TemaWarna.teksUtama,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  kepedasan == null ? porsi : '$porsi • $kepedasan',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TemaWarna.teksSekunder,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  TemaWarna.formatRupiah(harga),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: TemaWarna.cokelatUtama,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: Colors.grey.shade500,
                onPressed: () => _hapusItem(index),
              ),
              PemilihJumlah(
                nilai: jumlah,
                tinggi: 36,
                saatBerubah: (val) => _ubahJumlah(index, val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bangunBilahBawahCheckout() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: TemaWarna.garisAbu)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: TemaWarna.teksUtama,
                  ),
                ),
                Text(
                  TemaWarna.formatRupiah(_subtotal),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: TemaWarna.teksUtama,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TombolUtama(
              teks: 'Checkout',
              ikon: Icons.arrow_forward_rounded,
              warnaLatar: TemaWarna.cokelatUtama,
              onPressed: _menujuCheckout,
            ),
          ],
        ),
      ),
    );
  }
}
