import 'package:flutter/material.dart';
import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../model/produk.dart';
import '../umum/keadaan_muat.dart';
import '../umum/tema_warna.dart';
import '../umum/format_rupiah.dart';
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

  Future<void> _tambahProduk() async {
    final hasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const FormProduk()),
    );
    if (hasil == true) _muatData();
  }

  Future<void> _ubahProduk(Produk produk) async {
    final hasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => FormProduk(produk: produk)),
    );
    if (hasil == true) _muatData();
  }

  /// Dialog konfirmasi, lalu **kirim** `DELETE /api/produk/{id}` ke server.
  /// 409 (produk masih dipakai pesanan aktif) tampil dari server dan daftar
  /// tidak diubah; 404 → daftar disegarkan; sukses → item hilang dari daftar.
  Future<void> _konfirmasiHapus(Produk produk) async {
    final bool? setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool sedangHapus = false;
        String? galatServer;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> kirimHapus() async {
              if (sedangHapus) return;
              setDialogState(() {
                sedangHapus = true;
                galatServer = null;
              });

              try {
                await _layanan.hapusProduk(produk.id);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(true);
                }
              } on GalatApi catch (g) {
                if (!dialogContext.mounted) return;
                if (g.jenis == JenisGalat.tidakDitemukan) {
                  // Sudah tidak ada di server — anggap berhasil, segarkan daftar
                  Navigator.of(dialogContext).pop(true);
                } else {
                  // 409 & galat lain: pesan server tampil, item tetap di daftar
                  setDialogState(() {
                    sedangHapus = false;
                    galatServer = g.pesan;
                  });
                }
              } catch (_) {
                if (!dialogContext.mounted) return;
                setDialogState(() {
                  sedangHapus = false;
                  galatServer = GalatApi.umum().pesan;
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Konfirmasi Hapus'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yakin ingin menghapus menu "${produk.nama}"?'),
                  if (galatServer != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      galatServer!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TemaWarna.merahHabis,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: sedangHapus
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: TemaWarna.merahHabis,
                  ),
                  onPressed: sedangHapus ? null : kirimHapus,
                  child: sedangHapus
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Hapus'),
                ),
              ],
            );
          },
        );
      },
    );

    if (setuju != true || !mounted) return;

    setState(() {
      _daftarProduk.removeWhere((p) => p.id == produk.id);
      if (_daftarProduk.isEmpty) _keadaan = KeadaanMuat.kosong;
    });

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Menu "${produk.nama}" berhasil dihapus.'),
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
        return RefreshIndicator(
          color: TemaWarna.cokelatUtama,
          onRefresh: _muatData,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
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
                  title: Text(p.nama,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${formatRupiah(p.harga)} • Stok: ${p.stok}'
                      '${p.tersedia ? '' : ' • Tidak tersedia'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: Colors.blue),
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
          ),
        );
    }
  }
}

