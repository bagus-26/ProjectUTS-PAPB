import 'dart:async';
import 'package:flutter/material.dart';

import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../layanan/layanan_lokasi.dart';
import '../model/produk.dart';
import '../umum/keadaan_muat.dart';
import '../umum/tema_warna.dart';
import '../umum/format_rupiah.dart';
import '../widget/bilah_pencarian.dart';
import '../widget/kartu_produk.dart';
import '../widget/tampilan_galat.dart';
import '../widget/tampilan_kosong.dart';
import '../widget/tampilan_muat.dart';
import 'halaman_keranjang.dart';
import 'halaman_menu_favorit.dart';
import 'halaman_notifikasi.dart';
import 'halaman_rincian_produk.dart';
import 'halaman_semua_menu.dart';

/// Halaman Home / Katalog Produk (Kelompok 1: Makanan & Minuman).
///
/// Struktur tampilan mengikuti `home.png` dengan bagian atas personal:
/// top bar, sapaan besar, search bar pill, banner promo, empat kategori bulat,
/// lalu daftar "Menu Terlaris".
///
/// Aturan stok: hanya produk `dapatDipesan` (tersedia **dan** `stok > 0`)
/// yang dirender. Menu habis disembunyikan sepenuhnya karena visibilitasnya
/// diatur dari panel admin.
class HalamanKatalog extends StatefulWidget {
  /// Membuka keranjang dari tab utama. Mengembalikan `Future` agar Home
  /// bisa menyegarkan lencana `jumlah_item` setelah halaman keranjang ditutup.
  final Future<void> Function()? saatBukaKeranjang;

  const HalamanKatalog({
    super.key,
    this.saatBukaKeranjang,
  });

  @override
  State<HalamanKatalog> createState() => _HalamanKatalogState();
}

class _HalamanKatalogState extends State<HalamanKatalog> {
  static const List<({String nama, IconData ikon})> _kategoriHome = [
    (nama: 'Semua', ikon: Icons.local_cafe_outlined),
    (nama: 'Minuman', ikon: Icons.local_drink_outlined),
    (nama: 'Makanan', ikon: Icons.restaurant_outlined),
    (nama: 'Snack', ikon: Icons.cookie_outlined),
  ];

  final LayananApi _layanan = LayananApi();

  // Pengelolaan 4 Keadaan Layar Eksplisit
  KeadaanMuat _keadaan = KeadaanMuat.memuat;

  List<Produk> _daftarProduk = [];
  GalatApi? _galat;

  String _kataKunciCari = '';
  Timer? _debounceCari;

  // Data ringkas pengguna untuk top bar personal
  String _namaPengguna = 'Pelanggan';
  String? _lokasiPengguna;

  // Status Keranjang Ringkas untuk lencana & floating bar
  int _totalItemKeranjang = 0;
  int _subtotalKeranjang = 0;

  // Jumlah notifikasi lonceng yang belum dibaca
  int _jumlahNotifikasi = 0;

  @override
  void initState() {
    super.initState();
    _muatDataProduk();
    _muatStatusKeranjang();
    _muatProfilRingkas();
    _muatJumlahNotifikasi();
  }

  @override
  void dispose() {
    _debounceCari?.cancel();
    super.dispose();
  }

  /// Mengambil nama penerima dan alamat dari data yang sudah dipakai
  /// halaman Akun/Checkout. Bila belum ada, top bar memakai sapaan default.
  Future<void> _muatProfilRingkas() async {
    try {
      final pesanan = await _layanan.ambilDaftarPesanan();
      if (!mounted) return;
      final terakhir = pesanan.isEmpty ? null : pesanan.first;
      setState(() {
        final nama = terakhir?.namaPenerima.trim() ?? '';
        if (nama.isNotEmpty) _namaPengguna = nama;
        final alamat =
            LayananLokasi.alamatPengirimanPilihan ?? terakhir?.alamatPenerima;
        if (alamat != null && alamat.trim().isNotEmpty) {
          _lokasiPengguna = alamat.trim();
        }
      });
    } catch (_) {
      // Top bar tetap tampil dengan sapaan default bila data belum tersedia.
      if (!mounted) return;
      final alamat = LayananLokasi.alamatPengirimanPilihan;
      if (alamat != null && alamat.trim().isNotEmpty) {
        setState(() => _lokasiPengguna = alamat.trim());
      }
    }
  }

  /// Mengambil jumlah notifikasi belum dibaca untuk lencana lonceng.
  Future<void> _muatJumlahNotifikasi() async {
    try {
      final daftar = await _layanan.ambilNotifikasi();
      if (!mounted) return;
      setState(() => _jumlahNotifikasi = daftar.jumlahBelumDibaca);
    } catch (_) {
      // Lencana tetap kosong bila server belum dapat dihubungi.
    }
  }

  Future<void> _bukaNotifikasi() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const HalamanNotifikasi()),
    );

    if (mounted) await _muatJumlahNotifikasi();
  }

  /// Produk yang boleh tampil di layar pelanggan: hanya yang stoknya tersedia.
  /// Favorit diletakkan paling atas, lalu menu terbaru.
  List<Produk> get _produkTersedia {
    final daftar = _daftarProduk
        .where((p) => p.dapatDipesan)
        .toList(growable: false);

    final hasil = List<Produk>.of(daftar);
    hasil.sort((a, b) {
      final aFavorit = FavoritLokal.berisi(a.id) ? 1 : 0;
      final bFavorit = FavoritLokal.berisi(b.id) ? 1 : 0;
      final urutanFavorit = bFavorit.compareTo(aFavorit);
      if (urutanFavorit != 0) return urutanFavorit;
      return b.id.compareTo(a.id);
    });
    return hasil;
  }

  /// Saat mencari, tampilkan seluruh hasil; selain itu cukup 4 menu terlaris
  /// seperti komposisi 2×2 pada `home.png`.
  List<Produk> get _daftarProdukTampil {
    final daftar = _produkTersedia;
    if (_kataKunciCari.trim().isNotEmpty) return daftar;
    return daftar.take(4).toList(growable: false);
  }

  /// `GET /api/produk?cari=` — pencarian tetap dikerjakan server.
  /// Hasil disaring lagi di klien agar menu stok habis tidak pernah dirender.
  Future<void> _muatDataProduk({bool tampilkanMemuat = true}) async {
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
        _daftarProduk = tersedia;
        // Keadaan kosong dipisahkan secara eksplisit dari galat.
        _keadaan =
            tersedia.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
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

  /// Mengambil data keranjang dari server untuk lencana dan floating bar.
  Future<void> _muatStatusKeranjang() async {
    try {
      final keranjang = await _layanan.ambilKeranjang();
      if (!mounted) return;
      setState(() {
        _totalItemKeranjang = keranjang.jumlahItem;
        _subtotalKeranjang = keranjang.ringkasan.subtotal;
      });
    } on GalatApi {
      if (!mounted) return;
      setState(() {
        _totalItemKeranjang = 0;
        _subtotalKeranjang = 0;
      });
    }
  }

  void _ubahKataKunci(String kataKunci) {
    _debounceCari?.cancel();
    // Debounce ±400 ms
    _debounceCari = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _kataKunciCari = kataKunci;
      });
      _muatDataProduk(tampilkanMemuat: false);
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
          builder: (context) => const HalamanKeranjang(),
        ),
      );
    }

    if (mounted) await _muatStatusKeranjang();
  }

  /// Membuka halaman Semua Menu dengan tab kategori yang langsung terpilih.
  Future<void> _bukaSemuaMenu({String kategori = 'Semua'}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HalamanSemuaMenu(
          kategoriAwal: kategori,
          saatBukaKeranjang: widget.saatBukaKeranjang,
        ),
      ),
    );

    if (!mounted) return;
    await _muatStatusKeranjang();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaWarna.latarPutih,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: TemaWarna.cokelatKaramel,
              onRefresh: () async {
                await Future.wait([
                  _muatDataProduk(tampilkanMemuat: false),
                  _muatStatusKeranjang(),
                  _muatProfilRingkas(),
                  _muatJumlahNotifikasi(),
                ]);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _bangunHeaderAtas()),
                  SliverToBoxAdapter(child: _bangunKategori()),
                  SliverToBoxAdapter(child: _bangunJudulSeksi()),
                  _bangunAreaKonten(),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: _totalItemKeranjang > 0 ? 120 : 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating cart bar tetap dipertahankan agar alur keranjang utuh.
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

  // ---------------------------------------------------------------
  // Bagian atas Home: top bar, sapaan, pencarian, banner promo
  // ---------------------------------------------------------------
  Widget _bangunHeaderAtas() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bangunTopBar(),
          const SizedBox(height: 22),
          _bangunSapaan(),
          const SizedBox(height: 18),
          _bangunPencarian(),
          const SizedBox(height: 16),
          _bangunBannerPromo(),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _bangunTopBar() {
    return Row(
      children: [
        _bangunAvatarPengguna(),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 17,
                color: TemaWarna.cokelatKaramel,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _lokasiPengguna ?? 'Antar ke Lokasi Saya',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: TemaWarna.teksGelap,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: TemaWarna.cokelatPekat,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _bangunTombolNotifikasi(),
        const SizedBox(width: 8),
        _bangunTombolKeranjang(),
      ],
    );
  }

  Widget _bangunAvatarPengguna() {
    final nama = _namaPengguna.trim();
    final inisial =
        nama.isEmpty ? 'P' : nama.characters.first.toUpperCase();

    return CircleAvatar(
      radius: 22,
      backgroundColor: TemaWarna.kremLembut,
      child: Text(
        inisial,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: TemaWarna.cokelatPekat,
        ),
      ),
    );
  }

  /// Tombol lonceng dengan lencana jumlah notifikasi belum dibaca.
  Widget _bangunTombolNotifikasi() {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _bukaNotifikasi,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: TemaWarna.garisAbu),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 22,
                color: TemaWarna.cokelatPekat,
              ),
              if (_jumlahNotifikasi > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(minWidth: 15),
                    decoration: BoxDecoration(
                      color: TemaWarna.merahHabis,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Text(
                      _jumlahNotifikasi > 9 ? '9+' : '$_jumlahNotifikasi',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tombol keranjang bulat berbingkai tipis dengan titik indikator.
  Widget _bangunTombolKeranjang() {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _navigasiKeKeranjang,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: TemaWarna.garisAbu),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                size: 22,
                color: TemaWarna.cokelatPekat,
              ),
              if (_totalItemKeranjang > 0)
                Positioned(
                  top: 10,
                  right: 10,
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

  Widget _bangunSapaan() {
    const gaya = TextStyle(
      fontSize: 31,
      height: 1.08,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Klik, Pesan, Masuk,',
          style: gaya.copyWith(color: TemaWarna.teksGelap),
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Saatnya ',
                style: gaya.copyWith(color: TemaWarna.teksGelap),
              ),
              TextSpan(
                text: 'Makan Yuk!',
                style: gaya.copyWith(color: TemaWarna.cokelatKaramel),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bangunPencarian() {
    return BilahPencarian(
      nilaiAwal: _kataKunciCari,
      saatCari: _ubahKataKunci,
      saatFilterDitekan: () => _bukaSemuaMenu(),
      petunjuk: 'Cari menu favoritmu...',
      radius: 30,
      filterDiDalam: true,
      ikonFilter: Icons.tune,
    );
  }

  Widget _bangunBannerPromo() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFBE9D7), Color(0xFFF4D3B3)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x145D3A1A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PENAWARAN SPESIAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: TemaWarna.cokelatKaramel,
                  ),
                ),
                const SizedBox(height: 6),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'DISKON 40%',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 26,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: TemaWarna.cokelatPekat,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Untuk pesanan pertamamu',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7A5A40),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _bukaSemuaMenu(),
                  style: FilledButton.styleFrom(
                    backgroundColor: TemaWarna.cokelatPekat,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Pesan Sekarang'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 124,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/menu/Nasi Goreng Spesial.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFF3D9C0),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.restaurant_rounded,
                      size: 40,
                      color: TemaWarna.cokelatKaramel,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Bagian bawah Home: kategori bulat & judul section
  // ---------------------------------------------------------------
  Widget _bangunKategori() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Row(
        children: [
          for (final kategori in _kategoriHome)
            Expanded(
              child: InkWell(
                onTap: () => _bukaSemuaMenu(kategori: kategori.nama),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: TemaWarna.kremLembut,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          kategori.ikon,
                          size: 22,
                          color: TemaWarna.cokelatPekat,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        kategori.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: TemaWarna.teksGelap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bangunJudulSeksi() {
    final sedangMencari = _kataKunciCari.trim().isNotEmpty;
    final judul = sedangMencari
        ? 'Hasil Pencarian "$_kataKunciCari"'
        : 'Menu Terlaris';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              judul,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: TemaWarna.teksGelap,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _bukaSemuaMenu(),
            style: TextButton.styleFrom(
              foregroundColor: TemaWarna.cokelatPekat,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TemaWarna.cokelatKaramel,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: TemaWarna.cokelatKaramel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Menampilkan widget sesuai keadaan layar.
  Widget _bangunAreaKonten() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: TampilanMuat(pesan: 'Menyiapkan menu terlaris...'),
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
            pesan: _kataKunciCari.trim().isNotEmpty
                ? 'Tidak ada menu tersedia dengan nama "$_kataKunciCari". Coba kata kunci lain.'
                : 'Belum ada menu yang tersedia saat ini. Silakan cek kembali nanti.',
            teksAksi: _kataKunciCari.trim().isNotEmpty
                ? 'Reset Pencarian'
                : 'Muat Ulang',
            saatAksiDitekan: () {
              _debounceCari?.cancel();
              setState(() {
                _kataKunciCari = '';
              });
              _muatDataProduk();
            },
          ),
        );

      case KeadaanMuat.berhasil:
        final daftar = _daftarProdukTampil;
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              mainAxisExtent: 236,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final produk = daftar[index];
                return KartuProduk(
                  produk: produk,
                  onTap: () => _bukaRincian(produk),
                  onTambah: () => _tambahLangsung(produk),
                );
              },
              childCount: daftar.length,
            ),
          ),
        );
    }
  }

  /// Floating Cart Bar sesuai rancangan UI MakanYuk!.
  Widget _bangunFloatingCartBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TemaWarna.cokelatPekat,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(45),
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
              color: TemaWarna.cokelatKaramel,
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
                  formatRupiah(_subtotalKeranjang),
                  style: TextStyle(
                    color: Colors.white.withAlpha(210),
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
              backgroundColor: TemaWarna.cokelatKaramel,
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
