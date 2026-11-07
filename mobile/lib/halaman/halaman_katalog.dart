import 'dart:async';
import 'package:flutter/material.dart';

import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../model/produk.dart';
import '../umum/keadaan_muat.dart';
import '../umum/tema_warna.dart';
import '../widget/bilah_pencarian.dart';
import '../widget/chip_kategori.dart';
import '../widget/kartu_produk.dart';
import '../widget/tampilan_galat.dart';
import '../widget/tampilan_kosong.dart';
import '../widget/tampilan_muat.dart';
import 'halaman_keranjang.dart';
import 'halaman_menu_favorit.dart';
import 'halaman_rincian_produk.dart';

/// Halaman Katalog Produk (Kelompok 1: Makanan & Minuman)
/// Sesuai Kriteria 2: Menggunakan GridView.builder, filter server via ?kategori= & ?cari=,
/// serta 4 keadaan layar eksplisit (memuat, berhasil, kosong, galat).
class HalamanKatalog extends StatefulWidget {
  final VoidCallback? saatBukaKeranjang;

  const HalamanKatalog({
    super.key,
    this.saatBukaKeranjang,
  });

  @override
  State<HalamanKatalog> createState() => _HalamanKatalogState();
}

class _HalamanKatalogState extends State<HalamanKatalog> {
  final LayananApi _layanan = LayananApi();

  // Pengelolaan 4 Keadaan Layar Eksplisit
  KeadaanMuat _keadaan = KeadaanMuat.memuat;

  List<Produk> _daftarProduk = [];
  GalatApi? _galat;

  String _kategoriTerpilih = 'Semua';
  String _kataKunciCari = '';
  Timer? _debounceCari;

  final List<String> _kategoriList = const [
    'Semua',
    'Minuman',
    'Makanan',
    'Snack',
  ];

  Map<String, int> _jumlahPerKategori = {};

  // Status Keranjang Ringkas untuk Floating Bar
  int _totalItemKeranjang = 0;
  int _subtotalKeranjang = 0;

  @override
  void initState() {
    super.initState();
    // Pemanggilan awal API dilakukan di initState (Ketentuan Sisi Flutter butir 5)
    _muatDataProduk();
    _muatStatusKeranjang();
  }

  @override
  void dispose() {
    _debounceCari?.cancel();
    super.dispose();
  }

  /// Memanggil endpoint GET /api/produk?kategori=...&cari=...
  /// Seluruh penyaringan dan pencarian dikirimkan ke server
  Future<void> _muatDataProduk() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _galat = null;
    });

    try {
      final hasil = await _layanan.ambilDaftarProduk(
        kategori: _kategoriTerpilih == 'Semua' ? null : _kategoriTerpilih,
        cari: _kataKunciCari.isEmpty ? null : _kataKunciCari,
      );

      if (!mounted) return;

      // Hitung ringkasan jumlah kategori jika sedang menampilkan 'Semua' tanpa pencarian
      if (_kategoriTerpilih == 'Semua' && _kataKunciCari.isEmpty) {
        final Map<String, int> mapCount = {'Semua': hasil.length};
        for (final p in hasil) {
          mapCount[p.kategori] = (mapCount[p.kategori] ?? 0) + 1;
        }
        _jumlahPerKategori = mapCount;
      }

      setState(() {
        _daftarProduk = hasil;
        // Kriteria 7: Keadaan kosong dipisahkan secara eksplisit dari galat
        if (hasil.isEmpty) {
          _keadaan = KeadaanMuat.kosong;
        } else {
          _keadaan = KeadaanMuat.berhasil;
        }
      });
    } on GalatApi catch (galat) {
      if (!mounted) return;
      setState(() {
        _galat = galat;
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

  /// Mengambil data keranjang dari server untuk menampilkan lencana dan floating bar
  Future<void> _muatStatusKeranjang() async {
    try {
      final keranjang = await _layanan.ambilKeranjang();
      if (!mounted) return;
      final ringkasan = keranjang['ringkasan'];
      setState(() {
        _totalItemKeranjang = (keranjang['jumlah_item'] as int?) ?? 0;
        _subtotalKeranjang = ringkasan is Map
            ? (ringkasan['subtotal'] as int?) ?? 0
            : 0;
      });
    } catch (_) {
      // Diamkan jika keranjang belum aktif
    }
  }

  void _ubahKategori(String kategori) {
    if (_kategoriTerpilih == kategori) return;
    setState(() {
      _kategoriTerpilih = kategori;
    });
    // Kirim ulang permintaan ke server via ?kategori=
    _muatDataProduk();
  }

  void _ubahKataKunci(String kataKunci) {
    _debounceCari?.cancel();
    _debounceCari = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _kataKunciCari = kataKunci;
      });
      // Kirim ulang permintaan ke server via ?cari=
      _muatDataProduk();
    });
  }

  void _bukaRincian(Produk produk) async {
    final hasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => HalamanRincianProduk(produk: produk),
      ),
    );

    if (hasil == true) {
      _muatStatusKeranjang();
    }
    if (mounted) setState(() {});
  }

  Future<void> _tambahLangsung(Produk produk) async {
    if (!produk.dapatDipesan) return;

    try {
      await _layanan.tambahKeKeranjang(
        produkId: produk.id,
        jumlah: 1,
        varianId: produk.varianPorsi.isNotEmpty
            ? produk.idVarian(produk.varianPorsi.first)
            : null,
        varianNama:
            produk.varianPorsi.isNotEmpty ? produk.varianPorsi.first : 'Reguler',
        tingkatPedas: produk.bisaPedas ? 'tidak_pedas' : null,
      );

      _muatStatusKeranjang();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: TemaWarna.hitamTombol,
          content: Text('${produk.nama} ditambahkan ke keranjang'),
        ),
      );
    } on GalatApi catch (galat) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: TemaWarna.merahHabis,
          content: Text(galat.pesan),
        ),
      );
    }
  }

  void _navigasiKeKeranjang() {
    if (widget.saatBukaKeranjang != null) {
      widget.saatBukaKeranjang!();
    } else {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => const HalamanKeranjang(),
            ),
          )
          .then((_) => _muatStatusKeranjang());
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                const Icon(
                  Icons.local_cafe_rounded,
                  color: TemaWarna.cokelatUtama,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'MakanYuk!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: TemaWarna.teksUtama,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'Makanan & Minuman Sudah Tersedia',
              style: TextStyle(
                fontSize: 12,
                color: TemaWarna.teksSekunder,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Ikon Keranjang dengan Lencana Jumlah (Kriteria 6 Spesifikasi)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_bag_outlined,
                    color: TemaWarna.teksUtama,
                    size: 26,
                  ),
                  onPressed: _navigasiKeKeranjang,
                ),
                if (_totalItemKeranjang > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: TemaWarna.cokelatUtama,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$_totalItemKeranjang',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: TemaWarna.cokelatUtama,
            onRefresh: () async {
              await _muatDataProduk();
              await _muatStatusKeranjang();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Bilah Pencarian (?cari=)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: BilahPencarian(
                      nilaiAwal: _kataKunciCari,
                      saatCari: _ubahKataKunci,
                    ),
                  ),
                ),

                // 2. Filter Kategori (?kategori=)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ChipKategori(
                      daftarKategori: _kategoriList,
                      kategoriTerpilih: _kategoriTerpilih,
                      saatDipilih: _ubahKategori,
                      jumlahPerKategori: _jumlahPerKategori,
                    ),
                  ),
                ),

                // 3. Judul Menu
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _kataKunciCari.isNotEmpty
                              ? 'Hasil Pencarian "$_kataKunciCari"'
                              : (_kategoriTerpilih == 'Semua'
                                  ? 'Menu Terlaris'
                                  : 'Menu $_kategoriTerpilih'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: TemaWarna.teksUtama,
                          ),
                        ),
                        if (_keadaan == KeadaanMuat.berhasil)
                          Text(
                            '${_daftarProduk.length} menu',
                            style: const TextStyle(
                              fontSize: 13,
                              color: TemaWarna.teksSekunder,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // 4. Pengelolaan 4 Keadaan Layar Eksplisit
                _bangunAreaKonten(),

                // Padding ekstra di bawah agar tidak tertutup floating bar
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: _totalItemKeranjang > 0 ? 110 : 30,
                  ),
                ),
              ],
            ),
          ),

          // 5. Floating Cart Bar (Screenshot 11)
          if (_totalItemKeranjang > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _bangunFloatingCartBar(),
            ),
        ],
      ),
    );
  }

  /// Menampilkan widget sesuai keadaan layar
  Widget _bangunAreaKonten() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: TampilanMuat(pesan: 'Memuat menu favoritmu...'),
        );

      case KeadaanMuat.galat:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: TampilanGalat(
            galat: _galat,
            saatCobaLagi: _muatDataProduk,
          ),
        );

      case KeadaanMuat.kosong:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: TampilanKosong(
            judul: 'Menu Tidak Ditemukan',
            pesan: _kataKunciCari.isNotEmpty
                ? 'Tidak ada menu dengan nama "$_kataKunciCari". Coba cari kata kunci lain.'
                : 'Belum ada menu pada kategori $_kategoriTerpilih.',
            teksAksi: 'Reset Filter',
            saatAksiDitekan: () {
              setState(() {
                _kataKunciCari = '';
                _kategoriTerpilih = 'Semua';
              });
              _muatDataProduk();
            },
          ),
        );

      case KeadaanMuat.berhasil:
        // Kriteria 2 Butir 1: Dibangun dengan GridView.builder
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final produk = _daftarProduk[index];
                return KartuProduk(
                  produk: produk,
                  isFavorit: FavoritLokal.berisi(produk.id),
                  onTap: () => _bukaRincian(produk),
                  onTambah: () => _tambahLangsung(produk),
                  onFavorit: () {
                    setState(() {
                      FavoritLokal.alihkan(produk.toJson());
                    });
                  },
                );
              },
              childCount: _daftarProduk.length,
            ),
          ),
        );
    }
  }

  /// Floating Cart Bar sesuai rancangan UI MakanYuk!
  Widget _bangunFloatingCartBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TemaWarna.hitamTombol,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TemaWarna.cokelatUtama,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_totalItemKeranjang item di keranjang',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  TemaWarna.formatRupiah(_subtotalKeranjang),
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: _navigasiKeKeranjang,
            style: FilledButton.styleFrom(
              backgroundColor: TemaWarna.cokelatUtama,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text(
              'Checkout',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
