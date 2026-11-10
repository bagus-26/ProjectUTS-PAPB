import 'package:flutter/material.dart';

import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../model/produk.dart';
import '../umum/keadaan_muat.dart';
import '../umum/tema_warna.dart';
import '../umum/format_rupiah.dart';
import '../widget/pemilih_jumlah.dart';
import '../widget/tombol_utama.dart';
import '../widget/gambar_menu.dart';
import '../widget/tampilan_galat.dart';
import '../widget/tampilan_kosong.dart';
import '../widget/tampilan_muat.dart';
import 'halaman_menu_favorit.dart';

/// Halaman Rincian Produk (Kelompok 1: Makanan & Minuman Siap Saji)
/// Menampilkan detail produk lengkap, varian porsi, tingkat kepedasan,
/// catatan per item, dan pemilih kuantitas sesuai UI MakanYuk!.
class HalamanRincianProduk extends StatefulWidget {
  final Produk produk;

  const HalamanRincianProduk({super.key, required this.produk});

  @override
  State<HalamanRincianProduk> createState() => _HalamanRincianProdukState();
}

class _HalamanRincianProdukState extends State<HalamanRincianProduk> {
  final LayananApi _layanan = LayananApi();
  final TextEditingController _catatanController = TextEditingController();

  /// Data produk. Bisa diperbarui dari `GET /api/produk/{id}` (PRD 7.1).
  late Produk _produk;

  /// 4 keadaan layar eksplisit (PRD 7.2).
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  GalatApi? _galat;

  late String _porsiTerpilih;
  String _tingkatPedasTerpilih = 'tidak_pedas';
  int _jumlah = 1;
  bool _sedangMenambah = false;

  @override
  void initState() {
    super.initState();
    _produk = widget.produk;
    // Inisialisasi atribut khas domain kelompok 1
    _porsiTerpilih = _produk.varianPorsi.isNotEmpty
        ? _produk.varianPorsi.first
        : 'Reguler';

    // Sumber data resmi halaman ini adalah server (PRD 7.1: GET /produk/{id}),
    // objek dari Katalog hanya dipakai agar layar tidak kosong saat memuat.
    _muatRincian();
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  /// `GET /api/produk/{id}` — menyegarkan atribut, varian, stok, dan status.
  /// 404 dipetakan ke keadaan `kosong`, galat lain ke `galat` + coba lagi
  /// (matriks penanganan galat PRD Bagian 7.3).
  Future<void> _muatRincian() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _galat = null;
    });

    try {
      final hasil = await _layanan.ambilRincianProduk(_produk.id);
      if (!mounted) return;

      setState(() {
        _produk = hasil;
        // Pilihan porsi bisa saja tidak ada lagi pada data terbaru
        if (hasil.varianPorsi.isNotEmpty &&
            !hasil.varianPorsi.contains(_porsiTerpilih)) {
          _porsiTerpilih = hasil.varianPorsi.first;
        }
        _keadaan = KeadaanMuat.berhasil;
      });
    } on GalatApi catch (galat) {
      if (!mounted) return;
      setState(() {
        _galat = galat;
        _keadaan = galat.jenis == JenisGalat.tidakDitemukan
            ? KeadaanMuat.kosong
            : KeadaanMuat.galat;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _galat = GalatApi.umum();
        _keadaan = KeadaanMuat.galat;
      });
    }
  }

  /// Tambahan harga varian yang sedang dipilih (lookup, **bukan** aritmetika
  /// uang — penjumlahan `harga + tambahan` dilakukan server, PRD Bagian 6
  /// langkah 2f & PM-10).
  int get _tambahanTerpilih =>
      _produk.tambahanHargaVarian(_porsiTerpilih);

  /// Pesan galat untuk ditampilkan inline (PRD 7.3).
  /// 422 menampilkan daftar galat per kolom, 409 memakai pesan dari server.
  String _pesanGalat(GalatApi galat) {
    if (galat.jenis == JenisGalat.validasi &&
        galat.errors != null &&
        galat.errors!.isNotEmpty) {
      final rincian = galat.errors!.values.expand((baris) => baris).join('\n');
      if (rincian.isNotEmpty) return rincian;
    }

    return galat.pesan;
  }

  /// Mengirim permintaan penambahan item ke server (POST /api/keranjang)
  Future<void> _tambahKeKeranjang() async {
    if (!_produk.dapatDipesan) return;

    setState(() {
      _sedangMenambah = true;
    });

    try {
      await _layanan.tambahKeKeranjang(
        produkId: _produk.id,
        jumlah: _jumlah,
        varianId: _produk.idVarian(_porsiTerpilih),
        tingkatPedas: _produk.bisaPedas ? _tingkatPedasTerpilih : null,
        catatan: _catatanController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: TemaWarna.hitamTombol,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_produk.nama} berhasil ditambahkan!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } on GalatApi catch (galat) {
      if (!mounted) return;
      // 409/422 tampil inline di layar yang sama, tanpa pindah halaman (PRD 7.3)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: TemaWarna.merahHabis,
          duration: const Duration(seconds: 4),
          content: Text(_pesanGalat(galat)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal menambahkan item ke keranjang. Silakan coba lagi.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sedangMenambah = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Empat keadaan layar eksplisit (PRD 7.2)
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return _layarPendukung(
          const TampilanMuat(pesan: 'Memuat rincian menu...'),
        );

      case KeadaanMuat.galat:
        return _layarPendukung(
          TampilanGalat(galat: _galat, saatCobaLagi: _muatRincian),
        );

      case KeadaanMuat.kosong:
        // 404 dipetakan ke keadaan kosong, bukan galat (PRD 7.3)
        return _layarPendukung(
          TampilanKosong(
            judul: 'Menu Tidak Ditemukan',
            pesan: _galat?.pesan ??
                'Menu yang kamu cari tidak tersedia atau sudah dihapus.',
            teksAksi: 'Kembali',
            saatAksiDitekan: () => Navigator.of(context).pop(),
          ),
        );

      case KeadaanMuat.berhasil:
        return _bangunIsi(context);
    }
  }

  /// Layar sederhana (app bar + body) untuk keadaan memuat, galat, dan kosong.
  Widget _layarPendukung(Widget isi) {
    return Scaffold(
      backgroundColor: TemaWarna.latarPutih,
      appBar: AppBar(
        backgroundColor: TemaWarna.latarPutih,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: TemaWarna.teksUtama,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isi,
    );
  }

  Widget _bangunIsi(BuildContext context) {
    final bool siapPesan = _produk.dapatDipesan;
    final bool isFavorit = FavoritLokal.berisi(_produk.id);
    return Scaffold(
      backgroundColor: TemaWarna.latarPutih,
      body: CustomScrollView(
        slivers: [
          // AppBar dengan gambar besar produk dan tombol kembali + favorit
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: TemaWarna.kremTua,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withAlpha(220),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: TemaWarna.teksUtama,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withAlpha(220),
                  child: IconButton(
                    icon: Icon(
                      isFavorit ? Icons.favorite : Icons.favorite_border,
                      color: isFavorit ? Colors.red : TemaWarna.teksUtama,
                    ),
                    onPressed: () {
                      setState(() {
                        FavoritLokal.alihkan(_produk.toJson());
                      });
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  GambarMenu(
                    nama: _produk.nama,
                    kategori: _produk.kategori,
                  ),
                  if (!siapPesan)
                    Container(
                      color: Colors.black.withAlpha(140),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(200),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Text(
                          'STOK HABIS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Konten Rincian
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Produk & Harga (design Figma: nama di atas, harga di bawahnya)
                  Text(
                    _produk.nama,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: TemaWarna.teksUtama,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _jumlah > 1
                        ? '${formatRupiah(_produk.harga)} × $_jumlah'
                        : formatRupiah(_produk.harga),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: TemaWarna.cokelatUtama,
                    ),
                  ),
                  // Tambahan varian ditampilkan terpisah, TANPA dijumlahkan
                  // ke harga dasar (aritmetika uang dilarang di Dart — PM-10;
                  // subtotal resmi dibaca dari ringkasan server)
                  if (_tambahanTerpilih > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '+ ${formatRupiah(_tambahanTerpilih)} — varian '
                      '$_porsiTerpilih'
                      '${_jumlah > 1 ? ' × $_jumlah' : ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TemaWarna.cokelatMuda,
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Waktu Persiapan (atribut khas domain) & Status Stok
                  Row(
                    children: [
                      if (_produk.waktuPersiapanMenit > 0) ...[
                        const Icon(
                          Icons.schedule_rounded,
                          color: TemaWarna.teksSekunder,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Disiapkan ${_produk.waktuPersiapanMenit} menit',
                          style: const TextStyle(
                            fontSize: 13,
                            color: TemaWarna.teksSekunder,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: siapPesan
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          siapPesan
                              ? 'Stok: ${_produk.stok}'
                              : 'Tidak Tersedia',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: siapPesan
                                ? TemaWarna.hijauBuka
                                : TemaWarna.merahHabis,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Deskripsi Produk (Boleh null sesuai spesifikasi)
                  Text(
                    _produk.deskripsi ?? 'Sajian lezat dibuat dari bahan pilihan bermutu tinggi, siap menemani harimu.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: TemaWarna.teksSekunder,
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(color: TemaWarna.garisAbu),
                  ),

                  // 1. Pilihan Ukuran / Varian Porsi (Khas Domain 1)
                  const Text(
                    'Ukuran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: TemaWarna.teksUtama,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: _produk.varianPorsi.map((porsi) {
                      final bool isDipilih = _porsiTerpilih == porsi;
                      final tambahanHarga = _produk.tambahanHargaVarian(
                        porsi,
                      );

                      return ChoiceChip(
                        label: Text(
                          tambahanHarga > 0
                              ? '$porsi +${formatRupiah(tambahanHarga)}'
                              : porsi,
                        ),
                        selected: isDipilih,
                        onSelected: siapPesan
                            ? (selected) {
                                if (selected) {
                                  setState(() => _porsiTerpilih = porsi);
                                }
                              }
                            : null,
                        selectedColor: TemaWarna.cokelatUtama,
                        backgroundColor: TemaWarna.abuMuda,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDipilih ? Colors.white : TemaWarna.teksUtama,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDipilih
                                ? TemaWarna.cokelatUtama
                                : TemaWarna.garisAbu,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 2. Pilihan Tingkat Kepedasan / Rasa (Khas Domain 1)
                  if (_produk.bisaPedas) ...[
                    const Text(
                      'Tingkat Kepedasan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: TemaWarna.teksUtama,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children:
                          const {
                            'tidak_pedas': 'Tidak Pedas',
                            'sedang': 'Sedang',
                            'pedas': 'Pedas',
                            'sangat_pedas': 'Sangat Pedas',
                          }.entries.map((opsi) {
                            final isDipilih = _tingkatPedasTerpilih == opsi.key;

                            return ChoiceChip(
                              label: Text(opsi.value),
                              selected: isDipilih,
                              onSelected: siapPesan
                                  ? (selected) {
                                      if (selected) {
                                        setState(() {
                                          _tingkatPedasTerpilih = opsi.key;
                                        });
                                      }
                                    }
                                  : null,
                              selectedColor: TemaWarna.cokelatUtama,
                              backgroundColor: TemaWarna.abuMuda,
                              labelStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDipilih
                                    ? Colors.white
                                    : TemaWarna.teksUtama,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDipilih
                                      ? TemaWarna.cokelatUtama
                                      : TemaWarna.garisAbu,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 3. Catatan Pesanan Per Item (Khas Domain 1)
                  const Text(
                    'Catatan Tambahan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: TemaWarna.teksUtama,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: TemaWarna.latarPutih,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: TemaWarna.garisAbu),
                    ),
                    child: TextField(
                      controller: _catatanController,
                      maxLines: 3,
                      maxLength: 120,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: tanpa es, gula pisah, atau sambal jangan terlalu pedas...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                        contentPadding: EdgeInsets.all(14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bilah Aksi Bawah: Pemilih Jumlah & Tombol Tambah ke Keranjang
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
          child: Row(
            children: [
              // Pemilih Jumlah (-) 1 (+)
              // Sengaja TIDAK dibatasi stok dari sisi Flutter: server yang
              // memutuskan, sehingga 409 `stok_kurang` bisa didemokan (PRD 7.1).
              PemilihJumlah(
                nilai: _jumlah,
                max: 99,
                saatBerubah: siapPesan
                    ? (baru) {
                        setState(() => _jumlah = baru);
                      }
                    : (_) {},
              ),
              const SizedBox(width: 14),
              // Tombol Tambah ke Keranjang
              Expanded(
                child: TombolUtama(
                  teks: siapPesan ? 'Tambah ke Keranjang' : 'Stok Habis',
                  warnaLatar: siapPesan
                      ? TemaWarna.cokelatUtama
                      : Colors.grey.shade400,
                  sedangMemuat: _sedangMenambah,
                  onPressed: siapPesan ? _tambahKeKeranjang : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
