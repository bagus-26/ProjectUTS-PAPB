import 'package:flutter/material.dart';
import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../model/produk.dart';
import '../umum/keadaan_muat.dart';
import '../umum/tema_warna.dart';
import '../widget/tampilan_galat.dart';
import '../widget/tampilan_kosong.dart';
import '../widget/tampilan_muat.dart';
import 'form_produk.dart';

/// Halaman Kelola Produk (CRUD Produk - Kriteria 2 Butir 4 & 5)
class HalamanKelolaProduk extends StatefulWidget {
  const HalamanKelolaProduk({super.key});

  @override
  State<HalamanKelolaProduk> createState() => _HalamanKelolaProdukState();
}

class _HalamanKelolaProdukState extends State<HalamanKelolaProduk> {
  final LayananApi _layanan = LayananApi();
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  List<Produk> _daftarProduk = [];
  GalatApi? _galat;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _galat = null;
    });

    try {
      final hasil = await _layanan.ambilDaftarProduk();
      if (!mounted) return;
      setState(() {
        _daftarProduk = hasil;
        _keadaan = hasil.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
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

  void _tambahProduk() async {
    final hasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const FormProduk()),
    );
    if (hasil == true) _muatData();
  }

  void _ubahProduk(Produk produk) async {
    final hasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => FormProduk(produk: produk)),
    );
    if (hasil == true) _muatData();
  }

  void _konfirmasiHapus(Produk produk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus menu "${produk.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: TemaWarna.merahHabis),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _daftarProduk.removeWhere((p) => p.id == produk.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Menu "${produk.nama}" berhasil dihapus.')),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaWarna.latarKrem,
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _tambahProduk,
          ),
        ],
      ),
      body: _bangunKonten(),
    );
  }

  Widget _bangunKonten() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const TampilanMuat(pesan: 'Memuat data produk...');
      case KeadaanMuat.galat:
        return TampilanGalat(galat: _galat, saatCobaLagi: _muatData);
      case KeadaanMuat.kosong:
        return TampilanKosong(
          judul: 'Belum Ada Produk',
          pesan: 'Silakan tambah produk baru untuk ditampilkan di katalog.',
          teksAksi: 'Tambah Produk',
          saatAksiDitekan: _tambahProduk,
        );
      case KeadaanMuat.berhasil:
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _daftarProduk.length,
          itemBuilder: (context, index) {
            final p = _daftarProduk[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: TemaWarna.garisAbu),
              ),
              color: Colors.white,
              child: ListTile(
                title: Text(p.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${TemaWarna.formatRupiah(p.harga)} • Stok: ${p.stok}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: () => _ubahProduk(p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _konfirmasiHapus(p),
                    ),
                  ],
                ),
              ),
            );
          },
        );
    }
  }
}

