import 'dart:async';
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
import 'halaman_keranjang.dart';
import 'halaman_menu_favorit.dart';
import 'halaman_rincian_produk.dart';

/// Halaman Semua Menu — padanan `all_menu_screen.dart` pada struktur proyek
/// yang memakai penamaan Bahasa Indonesia.
///
/// Mengikuti desain `semua menu.png`:
/// * AppBar dengan tombol kembali, judul "Semua Menu", dan keranjang.
/// * Search bar berdampingan dengan tombol filter.
/// * Tab kategori berbentuk pill beserta jumlah menu tersedia.
/// * Kartu menu lengkap: badge kategori, favorit, rating, nama, harga, `+`.
///
/// Stok: hanya produk `dapatDipesan` yang dimuat dan dihitung. Menu yang
/// stoknya habis tidak pernah dirender maupun dihitung pada tab.
class HalamanSemuaMenu extends StatefulWidget {
  /// Kategori yang langsung terpilih saat halaman dibuka.
  final String kategoriAwal;

  /// Callback opsional dari tab utama agar keranjang dibuka lewat shell
  /// navigasi yang sama dengan Home.
  final Future<void> Function()? saatBukaKeranjang;

  const HalamanSemuaMenu({
    super.key,
    this.kategoriAwal = 'Semua',
    this.saatBukaKeranjang,
  });

  @override
  State<HalamanSemuaMenu> createState() => _HalamanSemuaMenuState();
}

class _HalamanSemuaMenuState extends State<HalamanSemuaMenu> {
  static const List<String> _kategori = [
    'Semua',
    'Minuman',
    'Makanan',
    'Snack',
  ];

  static const List<String> _pilihanUrutan = [
    'Default',
    'Harga Termurah',
    'Harga Termahal',
    'Nama A-Z',
  ];

  final LayananApi _layanan = LayananApi();

  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  List<Produk> _semuaProduk = [];
  GalatApi? _galat;

  late String _kategoriTerpilih;
  String _kataKunciCari = '';
  String _urutan = 'Default';
  Timer? _debounceCari;

  int _totalItemKeranjang = 0;

  @override
  void initState() {
    super.initState();
    _kategoriTerpilih = _kategori
        .firstWhere(
          (kategori) =>
              kategori.toLowerCase() == widget.kategoriAwal.toLowerCase(),
          orElse: () => 'Semua',
        );
    _muatProduk();
    _muatStatusKeranjang();
  }

  @override
  void dispose() {
    _debounceCari?.cancel();
    super.dispose();
  }

  /// Produk tersedia pada kategori terpilih, sudah diurutkan sesuai filter.
  List<Produk> get _produkTampil {
    final kunci = _kategoriTerpilih.toLowerCase();
    final daftar = _semuaProduk
        .where(
          (produk) =>
              produk.dapatDipesan &&
              (kunci == 'semua' || produk.kategori.toLowerCase() == kunci),
        )
        .toList();

    switch (_urutan) {
      case 'Harga Termurah':
        daftar.sort((a, b) => a.harga.compareTo(b.harga));
      case 'Harga Termahal':
        daftar.sort((a, b) => b.harga.compareTo(a.harga));
      case 'Nama A-Z':
        daftar.sort(
          (a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()),
        );
      default:
        break;
    }

    return daftar;
  }

  /// Jumlah menu **tersedia** per kategori untuk isi tab, mis. "Minuman (8)".
  int _jumlahKategori(String kategori) {
    if (kategori == 'Semua') {
      return _semuaProduk.where((produk) => produk.dapatDipesan).length;
    }

    final kunci = kategori.toLowerCase();
    return _semuaProduk
        .where(
          (produk) =>
              produk.dapatDipesan && produk.kategori.toLowerCase() == kunci,
        )
        .length;
  }

  /// `GET /api/produk?cari=` — kategori disaring lokal agar hitungan tab
  /// selalu berasal dari seluruh menu tersedia, bukan hanya tab aktif.
  Future<void> _muatProduk({bool tampilkanMemuat = true}) async {
    if (tampilkanMemuat) {
      setState(() {
        _keadaan = KeadaanMuat.memuat;
        _galat = null;
      });
    }

    try {
      final hasil = await _layanan.ambilDaftarProduk(
        cari: _kataKunciCari.trim().isEmpty ? null : _kataKunciCari.trim(),
      );

      if (!mounted) return;

      final tersedia = hasil
          .where((produk) => produk.dapatDipesan)
          .toList(growable: false);

      setState(() {
        _semuaProduk = tersedia;
        _keadaan = _produkTampil.isEmpty
            ? KeadaanMuat.kosong
            : KeadaanMuat.berhasil;
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

  Future<void> _muatStatusKeranjang() async {
    try {
      final keranjang = await _layanan.ambilKeranjang();
      if (!mounted) return;
      setState(() {
        _totalItemKeranjang = keranjang.jumlahItem;
      });
    } on GalatApi {
      if (!mounted) return;
      setState(() {
        _totalItemKeranjang = 0;
      });
    }
  }

  void _ubahKategori(String kategori) {
    if (_kategoriTerpilih == kategori) return;
    setState(() {
      _kategoriTerpilih = kategori;
      _keadaan = _produkTampil.isEmpty
          ? KeadaanMuat.kosong
          : KeadaanMuat.berhasil;
    });
  }

  void _ubahKataKunci(String kataKunci) {
    _debounceCari?.cancel();
    _debounceCari = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _kataKunciCari = kataKunci;
      });
      _muatProduk(tampilkanMemuat: false);
    });
  }

  Future<void> _bukaFilter() async {
    final pilihan = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: TemaWarna.garisAbu,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Filter Menu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: TemaWarna.teksGelap,
                  ),
                ),
                const SizedBox(height: 8),
                for (final opsi in _pilihanUrutan)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      opsi,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _urutan == opsi
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _urutan == opsi
                            ? TemaWarna.cokelatPekat
                            : TemaWarna.teksGelap,
                      ),
                    ),
                    trailing: _urutan == opsi
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: TemaWarna.cokelatKaramel,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(opsi),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (pilihan == null || !mounted) return;
    setState(() {
      _urutan = pilihan;
      _keadaan = _produkTampil.isEmpty
          ? KeadaanMuat.kosong
          : KeadaanMuat.berhasil;
    });
  }

  Future<void> _bukaRincian(Produk produk) async {
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
        tingkatPedas: produk.bisaPedas ? 'tidak_pedas' : null,
      );

      _muatStatusKeranjang();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: TemaWarna.cokelatPekat,
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

  Future<void> _navigasiKeKeranjang() async {
    if (widget.saatBukaKeranjang != null) {
      await widget.saatBukaKeranjang!();
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => HalamanKeranjang(
            saatPilihMenu: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }

    if (mounted) {
      await _muatStatusKeranjang();
    }
  }

  void _resetFilter() {
    _debounceCari?.cancel();
    setState(() {
      _kataKunciCari = '';
      _kategoriTerpilih = 'Semua';
      _urutan = 'Default';
    });
    _muatProduk();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaWarna.latarPutih,
      appBar: AppBar(
        backgroundColor: TemaWarna.latarPutih,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 64,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: TemaWarna.cokelatPekat,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Semua Menu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: TemaWarna.cokelatPekat,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _bangunTombolKeranjang(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: TemaWarna.cokelatKaramel,
        onRefresh: () async {
          await Future.wait([
            _muatProduk(tampilkanMemuat: false),
            _muatStatusKeranjang(),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: BilahPencarian(
                  nilaiAwal: _kataKunciCari,
                  saatCari: _ubahKataKunci,
                  saatFilterDitekan: _bukaFilter,
                  petunjuk: 'Cari menu favoritmu...',
                ),
              ),
            ),
            SliverToBoxAdapter(child: _bangunTabKategori()),
            _bangunAreaKonten(),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _bangunTombolKeranjang() {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _navigasiKeKeranjang,
        customBorder: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: TemaWarna.garisAbu),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                size: 21,
                color: TemaWarna.cokelatPekat,
              ),
              if (_totalItemKeranjang > 0)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: TemaWarna.cokelatKaramel,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bangunTabKategori() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _kategori.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final kategori = _kategori[index];
          final terpilih = _kategoriTerpilih == kategori;
          final jumlah = _jumlahKategori(kategori);

          return InkWell(
            onTap: () => _ubahKategori(kategori),
            borderRadius: BorderRadius.circular(30),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: terpilih ? TemaWarna.cokelatPekat : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: terpilih
                      ? TemaWarna.cokelatPekat
                      : TemaWarna.garisAbu,
                ),
                boxShadow: terpilih
                    ? [
                        BoxShadow(
                          color: TemaWarna.cokelatPekat.withAlpha(30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '$kategori ($jumlah)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: terpilih ? FontWeight.w700 : FontWeight.w500,
                  color: terpilih ? Colors.white : TemaWarna.teksGelap,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _bangunAreaKonten() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: TampilanMuat(pesan: 'Memuat semua menu tersedia...'),
        );

      case KeadaanMuat.galat:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: TampilanGalat(
            galat: _galat,
            saatCobaLagi: _muatProduk,
          ),
        );

      case KeadaanMuat.kosong:
        final sedangMencari = _kataKunciCari.trim().isNotEmpty;
        return SliverFillRemaining(
          hasScrollBody: false,
          child: TampilanKosong(
            judul: 'Menu Tidak Ditemukan',
            pesan: sedangMencari
                ? 'Tidak ada menu tersedia dengan nama "$_kataKunciCari" pada kategori $_kategoriTerpilih.'
                : _kategoriTerpilih == 'Semua'
                    ? 'Belum ada menu yang tersedia saat ini. Silakan cek kembali nanti.'
                    : 'Belum ada menu $_kategoriTerpilih yang tersedia saat ini.',
            teksAksi: 'Reset Filter',
            saatAksiDitekan: _resetFilter,
          ),
        );

      case KeadaanMuat.berhasil:
        final daftar = _produkTampil;
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              mainAxisExtent: 266,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final produk = daftar[index];
                return KartuProduk(
                  produk: produk,
                  tampilkanBadgeKategori: true,
                  tampilkanFavorit: true,
                  tampilkanRating: true,
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
              childCount: daftar.length,
            ),
          ),
        );
    }
  }
}
