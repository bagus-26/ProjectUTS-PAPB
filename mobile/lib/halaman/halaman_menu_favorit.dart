import 'package:flutter/material.dart';

import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../model/produk.dart';
import '../umum/keadaan_muat.dart';
import '../umum/tema_warna.dart';
import '../widget/bilah_pencarian.dart';
import '../widget/kartu_produk.dart';
import '../widget/tampilan_galat.dart';
import '../widget/tampilan_kosong.dart';
import '../widget/tampilan_muat.dart';
import 'halaman_rincian_produk.dart';

/// Penyimpanan Favorit Lokal di Memori Klien
class FavoritLokal {
  FavoritLokal._();

  static final Map<int, Map<String, dynamic>> _tersimpan = {};

  static List<Map<String, dynamic>> get semua =>
      _tersimpan.values.toList(growable: false);

  static bool berisi(int id) => _tersimpan.containsKey(id);

  static void alihkan(Map<String, dynamic> produk) {
    final idRaw = produk['id'];
    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');

    if (id == null) return;

    if (_tersimpan.containsKey(id)) {
      _tersimpan.remove(id);
    } else {
      _tersimpan[id] = Map<String, dynamic>.from(produk);
    }
  }

  static void hapus(int id) {
    _tersimpan.remove(id);
  }
}

/// Halaman Menu Favorit (MakanYuk! - Kelompok 1)
/// Sesuai UI rancangan Screenshot 10: Tampilan Grid menu yang disimpan disukai
class HalamanMenuFavorit extends StatefulWidget {
  final VoidCallback? saatPilihMenu;

  const HalamanMenuFavorit({
    super.key,
    this.saatPilihMenu,
  });

  @override
  State<HalamanMenuFavorit> createState() => _HalamanMenuFavoritState();
}

class _HalamanMenuFavoritState extends State<HalamanMenuFavorit> {
  String _kataKunci = '';

  void _bukaModalPilihFavorit() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.9,
          child: _LembarPilihFavorit(
            saatBerubah: () {
              if (mounted) setState(() {});
            },
          ),
        );
      },
    );

    if (mounted) setState(() {});
  }

  void _hapusFavorit(int id) {
    setState(() {
      FavoritLokal.hapus(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final semuaFavoritRaw = FavoritLokal.semua;
    final semuaFavorit = semuaFavoritRaw.map((p) => Produk.fromJson(p)).toList();

    // Saring dengan kata kunci pencarian
    final daftarTampil = _kataKunci.isEmpty
        ? semuaFavorit
        : semuaFavorit.where((p) {
            final kw = _kataKunci.toLowerCase();
            return p.nama.toLowerCase().contains(kw) ||
                (p.deskripsi?.toLowerCase().contains(kw) ?? false);
          }).toList();

    return Scaffold(
      backgroundColor: TemaWarna.latarKrem,
      appBar: AppBar(
        backgroundColor: TemaWarna.latarKrem,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Menu Favorit',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: TemaWarna.teksUtama,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${semuaFavorit.length} Menu tersimpan disukai',
              style: const TextStyle(
                fontSize: 12,
                color: TemaWarna.teksSekunder,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: TemaWarna.teksUtama,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: semuaFavorit.isEmpty
          ? TampilanKosong(
              ikon: Icons.favorite_border_rounded,
              judul: 'Belum Ada Menu Favorit',
              pesan:
                  'Tandai menu kesukaanmu dengan ikon hati agar lebih mudah ditemukan dan dipesan lagi.',
              teksAksi: 'Pilih Menu Sekarang',
              saatAksiDitekan: widget.saatPilihMenu ?? _bukaModalPilihFavorit,
            )
          : CustomScrollView(
              slivers: [
                // Bilah Pencarian Menu Favorit
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: BilahPencarian(
                      nilaiAwal: _kataKunci,
                      petunjuk: 'Cari menu favoritmu...',
                      saatCari: (kw) {
                        setState(() => _kataKunci = kw.trim());
                      },
                    ),
                  ),
                ),

                // Grid Menu Favorit
                if (daftarTampil.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: TampilanKosong(
                      judul: 'Tidak Ditemukan',
                      pesan: 'Tidak ada menu favorit yang cocok dengan pencarian.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.68,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final produk = daftarTampil[index];
                          return KartuProduk(
                            produk: produk,
                            isFavorit: true,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      HalamanRincianProduk(produk: produk),
                                ),
                              );
                            },
                            onFavorit: () => _hapusFavorit(produk.id),
                            onTambah: () async {
                              final layanan = LayananApi();
                              try {
                                await layanan.tambahKeKeranjang(
                                  produkId: produk.id,
                                  jumlah: 1,
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${produk.nama} ditambahkan ke keranjang'),
                                  ),
                                );
                              } catch (_) {}
                            },
                          );
                        },
                        childCount: daftarTampil.length,
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: semuaFavorit.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _bukaModalPilihFavorit,
              backgroundColor: TemaWarna.cokelatUtama,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Tambah Favorit',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }
}

/// Modal Bottom Sheet untuk memilih dan menandai menu favorit dari API
class _LembarPilihFavorit extends StatefulWidget {
  final VoidCallback saatBerubah;

  const _LembarPilihFavorit({required this.saatBerubah});

  @override
  State<_LembarPilihFavorit> createState() => _LembarPilihFavoritState();
}

class _LembarPilihFavoritState extends State<_LembarPilihFavorit> {
  final LayananApi _layanan = LayananApi();
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  List<Produk> _daftarProduk = [];
  GalatApi? _galat;

  @override
  void initState() {
    super.initState();
    _muatProduk();
  }

  Future<void> _muatProduk() async {
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

  void _alihkan(Produk produk) {
    setState(() {
      FavoritLokal.alihkan(produk.toJson());
    });
    widget.saatBerubah();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TemaWarna.latarKrem,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pilih Menu Favorit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: TemaWarna.teksUtama,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(child: _bangunKonten()),
          ],
        ),
      ),
    );
  }

  Widget _bangunKonten() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const TampilanMuat(pesan: 'Memuat daftar menu...');
      case KeadaanMuat.galat:
        return TampilanGalat(galat: _galat, saatCobaLagi: _muatProduk);
      case KeadaanMuat.kosong:
        return const TampilanKosong(
          judul: 'Belum Ada Menu',
          pesan: 'Tidak ada produk yang dapat dipilih.',
        );
      case KeadaanMuat.berhasil:
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: _daftarProduk.length,
          itemBuilder: (context, index) {
            final produk = _daftarProduk[index];
            final bool dipilih = FavoritLokal.berisi(produk.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: TemaWarna.garisAbu),
              ),
              color: Colors.white,
              child: ListTile(
                onTap: () => _alihkan(produk),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: TemaWarna.kremTua,
                    child: produk.gambar != null
                        ? Image.network(
                            produk.gambar!,
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
                title: Text(
                  produk.nama,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${TemaWarna.formatRupiah(produk.harga)} • ${produk.kategori}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TemaWarna.teksSekunder,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    dipilih ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: dipilih ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => _alihkan(produk),
                ),
              ),
            );
          },
        );
    }
  }
}
