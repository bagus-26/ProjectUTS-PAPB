import 'package:flutter/material.dart';

import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../model/produk.dart';
import '../umum/tema_warna.dart';
import '../widget/pemilih_jumlah.dart';
import '../widget/tombol_utama.dart';
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

  late String _porsiTerpilih;
  String _tingkatPedasTerpilih = 'tidak_pedas';
  int _jumlah = 1;
  bool _sedangMenambah = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi atribut khas domain kelompok 1
    _porsiTerpilih = widget.produk.varianPorsi.isNotEmpty
        ? widget.produk.varianPorsi.first
        : 'Reguler';
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  /// Menghitung harga per unit berdasarkan porsi yang dipilih
  int get _hargaPerUnit {
    return widget.produk.harga +
        widget.produk.tambahanHargaVarian(_porsiTerpilih);
  }

  /// Mengirim permintaan penambahan item ke server (POST /api/keranjang)
  Future<void> _tambahKeKeranjang() async {
    if (!widget.produk.dapatDipesan) return;

    setState(() {
      _sedangMenambah = true;
    });

    try {
      await _layanan.tambahKeKeranjang(
        produkId: widget.produk.id,
        jumlah: _jumlah,
        varianId: widget.produk.idVarian(_porsiTerpilih),
        varianNama: _porsiTerpilih,
        tingkatPedas: widget.produk.bisaPedas ? _tingkatPedasTerpilih : null,
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
                  '${widget.produk.nama} berhasil ditambahkan!',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: TemaWarna.merahHabis,
          content: Text(galat.pesan),
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
    final bool siapPesan = widget.produk.dapatDipesan;
    final bool isFavorit = FavoritLokal.berisi(widget.produk.id);
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
                        FavoritLokal.alihkan(widget.produk.toJson());
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
                  widget.produk.gambar != null &&
                          widget.produk.gambar!.isNotEmpty
                      ? Image.network(
                          widget.produk.gambar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _placeholderBesar(),
                        )
                      : _placeholderBesar(),
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
                  // Nama Produk & Harga
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.produk.nama,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: TemaWarna.teksUtama,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        TemaWarna.formatRupiah(_hargaPerUnit),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: TemaWarna.cokelatUtama,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Rating, Terjual & Status Stok
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: TemaWarna.kuningBintang,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.produk.rating}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${widget.produk.terjual} terjual)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: TemaWarna.teksSekunder,
                        ),
                      ),
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
                              ? 'Stok: ${widget.produk.stok}'
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
                    widget.produk.deskripsi ?? 'Sajian lezat dibuat dari bahan pilihan bermutu tinggi, siap menemani harimu.',
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
                    children: widget.produk.varianPorsi.map((porsi) {
                      final bool isDipilih = _porsiTerpilih == porsi;
                      final tambahanHarga = widget.produk.tambahanHargaVarian(
                        porsi,
                      );

                      return ChoiceChip(
                        label: Text(
                          tambahanHarga > 0
                              ? '$porsi +${TemaWarna.formatRupiah(tambahanHarga)}'
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
                        selectedColor: TemaWarna.hitamTombol,
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
                                ? TemaWarna.hitamTombol
                                : TemaWarna.garisAbu,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 2. Pilihan Tingkat Kepedasan / Rasa (Khas Domain 1)
                  if (widget.produk.bisaPedas) ...[
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
                              selectedColor: TemaWarna.hitamTombol,
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
                                      ? TemaWarna.hitamTombol
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
              PemilihJumlah(
                nilai: _jumlah,
                max: siapPesan ? widget.produk.stok : 1,
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
                  teks: siapPesan
                      ? 'Tambah ke Keranjang • ${TemaWarna.formatRupiah(_hargaPerUnit * _jumlah)}'
                      : 'Stok Habis',
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

  Widget _placeholderBesar() {
    return Container(
      color: TemaWarna.kremTua,
      child: Center(
        child: Icon(
          widget.produk.kategori.toLowerCase().contains('minum')
              ? Icons.local_cafe_rounded
              : Icons.restaurant_rounded,
          size: 72,
          color: TemaWarna.cokelatUtama.withAlpha(150),
        ),
      ),
    );
  }
}
