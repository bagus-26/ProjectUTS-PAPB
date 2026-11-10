import 'package:flutter/material.dart';

import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../model/item_keranjang.dart';
import '../umum/keadaan_muat.dart';
import '../umum/tema_warna.dart';
import '../umum/format_rupiah.dart';
import '../widget/pemilih_jumlah.dart';
import '../widget/tampilan_galat.dart';
import '../widget/tampilan_kosong.dart';
import '../widget/tampilan_muat.dart';
import '../widget/tombol_utama.dart';
import '../widget/gambar_menu.dart';
import 'halaman_checkout.dart';

/// Halaman Keranjang Belanja (Kelompok 1: MakanYuk!)
///
/// Seluruh perubahan dikerjakan oleh server (PRD 7.1 & A5-02):
/// `GET/PUT/DELETE /api/keranjang`. Subtotal **selalu** berasal dari
/// `ringkasan.subtotal` respons server — tidak pernah dihitung di Dart
/// (pagar pengaman PRD Bagian 4.3 butir 1).
class HalamanKeranjang extends StatefulWidget {
  final VoidCallback? saatPilihMenu;

  const HalamanKeranjang({super.key, this.saatPilihMenu});

  @override
  State<HalamanKeranjang> createState() => _HalamanKeranjangState();
}

class _HalamanKeranjangState extends State<HalamanKeranjang> {
  final LayananApi _layanan = LayananApi();

  // Empat keadaan layar eksplisit (PRD 7.2)
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  List<ItemKeranjang> _daftarItem = [];
  int _subtotal = 0;
  GalatApi? _galat;

  /// Id item yang sedang diproses server (PUT/DELETE) — tombolnya dimatikan
  /// agar permintaan ganda tidak terkirim.
  final Set<int> _sedangDiproses = {};

  @override
  void initState() {
    super.initState();
    _muatKeranjang();
  }

  /// `GET /api/keranjang` — daftar item, jumlah item, dan subtotal dari server.
  /// [tampilkanMemuat] dimatikan saat penyegaran senyap setelah PUT/DELETE,
  /// agar daftar tidak berkedip ke layar muat setiap tombol +/- ditekan.
  Future<void> _muatKeranjang({bool tampilkanMemuat = true}) async {
    if (tampilkanMemuat && mounted) {
      setState(() {
        _keadaan = KeadaanMuat.memuat;
        _galat = null;
      });
    }

    try {
      final isi = await _layanan.ambilKeranjang();
      if (!mounted) return;

      setState(() {
        _daftarItem = isi.items;
        _subtotal = isi.ringkasan.subtotal;
        _keadaan = isi.kosong ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
        _galat = null;
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

  /// `PUT /api/keranjang/{id}` — ubah jumlah lalu muat ulang (A5-02).
  /// 409 stok kurang / 422 tampil inline tanpa pindah halaman (PRD 7.3).
  Future<void> _ubahJumlah(ItemKeranjang item, int jumlahBaru) async {
    if (_sedangDiproses.contains(item.id) || jumlahBaru == item.jumlah) return;

    setState(() => _sedangDiproses.add(item.id));
    try {
      await _layanan.ubahJumlahKeranjang(id: item.id, jumlah: jumlahBaru);
    } on GalatApi catch (g) {
      _tampilkanGalat(g);
    } catch (_) {
      _tampilkanGalat(GalatApi.umum());
    } finally {
      // Sumber kebenaran tetap server: segarkan daftar + subtotal.
      await _muatKeranjang(tampilkanMemuat: false);
      if (mounted) setState(() => _sedangDiproses.remove(item.id));
    }
  }

  /// `DELETE /api/keranjang/{id}` — hapus item lalu muat ulang (A5-02).
  Future<void> _hapusItem(ItemKeranjang item) async {
    if (_sedangDiproses.contains(item.id)) return;

    setState(() => _sedangDiproses.add(item.id));
    try {
      await _layanan.hapusItemKeranjang(item.id);
    } on GalatApi catch (g) {
      _tampilkanGalat(g);
    } catch (_) {
      _tampilkanGalat(GalatApi.umum());
    } finally {
      await _muatKeranjang(tampilkanMemuat: false);
      if (mounted) setState(() => _sedangDiproses.remove(item.id));
    }
  }

  /// Menampilkan galat aksi (409/422/404) di layar yang sama.
  void _tampilkanGalat(GalatApi galat) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: TemaWarna.merahHabis,
          duration: const Duration(seconds: 4),
          content: Text(_pesanGalat(galat)),
        ),
      );
  }

  /// 422 menampilkan daftar galat per kolom, galat lain memakai pesan server.
  String _pesanGalat(GalatApi galat) {
    if (galat.jenis == JenisGalat.validasi &&
        galat.errors != null &&
        galat.errors!.isNotEmpty) {
      final rincian = galat.errors!.values.expand((baris) => baris).join('\n');
      if (rincian.isNotEmpty) return rincian;
    }

    return galat.pesan;
  }

  void _menujuCheckout() {
    // Checkout memuat ulang `GET /keranjang?kurir_id=` sendiri dari server
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const HalamanCheckout()));
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
        return TampilanGalat(galat: _galat, saatCobaLagi: _muatKeranjang);

      case KeadaanMuat.kosong:
        // Keadaan kosong ramah + tombol kembali ke katalog (PRD 7.1)
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
        return RefreshIndicator(
          color: TemaWarna.cokelatUtama,
          onRefresh: () => _muatKeranjang(tampilkanMemuat: false),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              for (final item in _daftarItem) _kartuItemKeranjang(item),
              const SizedBox(height: 12),
              // Voucher Promo Banner (design Figma)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: TemaWarna.kremPeach,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.discount_outlined,
                      color: TemaWarna.cokelatUtama,
                    ),
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
          ),
        );
    }
  }

  Widget _kartuItemKeranjang(ItemKeranjang item) {
    final bool diproses = _sedangDiproses.contains(item.id);
    final namaPorsi = item.varian?.nama ?? 'Reguler';
    final label = item.labelPedas;
    final catatan = item.catatan?.trim();

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
            child: SizedBox(
              width: 70,
              height: 70,
              child: GambarMenu(nama: item.nama, kategori: 'Makanan'),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nama,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: TemaWarna.teksUtama,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label == null ? namaPorsi : '$namaPorsi • $label',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TemaWarna.teksSekunder,
                  ),
                ),
                if (catatan != null && catatan.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Catatan: $catatan',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: TemaWarna.teksSekunder,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  formatRupiah(item.hargaSatuan),
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
                tooltip: 'Hapus item',
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: Colors.grey.shade500,
                onPressed: diproses ? null : () => _hapusItem(item),
              ),
              if (diproses)
                const SizedBox(
                  width: 92,
                  height: 36,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: TemaWarna.cokelatUtama,
                      ),
                    ),
                  ),
                )
              else
                PemilihJumlah(
                  nilai: item.jumlah,
                  tinggi: 36,
                  saatBerubah: (val) => _ubahJumlah(item, val),
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
                  // Subtotal dari `ringkasan.subtotal` server (D-06)
                  formatRupiah(_subtotal),
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
