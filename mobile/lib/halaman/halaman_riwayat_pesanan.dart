import 'dart:async';

import 'package:flutter/material.dart';

import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../model/pesanan.dart';
import '../umum/keadaan_muat.dart';
import '../umum/tema_warna.dart';
import '../umum/format_rupiah.dart';
import '../widget/tampilan_galat.dart';
import '../widget/tampilan_kosong.dart';
import '../widget/tampilan_muat.dart';
import '../widget/gambar_menu.dart';
import 'halaman_detail_pesanan.dart';
import 'halaman_utama.dart';

/// Halaman Riwayat Pesanan (MakanYuk! - Kelompok 1)
///
/// Sesuai PRD 7.1 & A4-05: `GET /api/pesanan` (terbaru dahulu, diatur server),
/// daftar + status, keadaan kosong, dan navigasi ke Rincian Pesanan.
/// Tidak ada fixture lokal — seluruh data berasal dari server.
class HalamanRiwayatPesanan extends StatefulWidget {
  final VoidCallback? saatPilihMenu;

  const HalamanRiwayatPesanan({super.key, this.saatPilihMenu});

  @override
  State<HalamanRiwayatPesanan> createState() => _HalamanRiwayatPesananState();
}

class _HalamanRiwayatPesananState extends State<HalamanRiwayatPesanan> {
  final LayananApi _layanan = LayananApi();

  // Empat keadaan layar eksplisit (PRD 7.2)
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  List<Pesanan> _daftarPesanan = [];
  GalatApi? _galat;

  String _filterTerpilih = 'Semua';
  bool _bannerTampil = true;
  bool _sedangPesanLagi = false;
  Timer? _timerPembaruan;

  @override
  void initState() {
    super.initState();
    _muatRiwayat();
    _timerPembaruan = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _muatRiwayatSenyap(),
    );
  }

  @override
  void dispose() {
    _timerPembaruan?.cancel();
    super.dispose();
  }

  /// Pembaruan senyap tiap 3 detik.
  Future<void> _muatRiwayatSenyap() async {
    if (_sedangPesanLagi) return;
    try {
      final data = await _layanan.ambilDaftarPesanan();
      if (!mounted) return;
      setState(() {
        _daftarPesanan = data;
        _keadaan = data.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
      });
    } catch (_) {
      // Abaikan galat polling.
    }
  }
  Future<void> _muatRiwayat() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _galat = null;
    });

    try {
      final data = await _layanan.ambilDaftarPesanan();
      if (!mounted) return;

      setState(() {
        _daftarPesanan = data;
        _keadaan = data.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
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

  void _bukaDetailPesanan(Pesanan pesanan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HalamanDetailPesanan(pesananId: pesanan.id),
      ),
    );
  }

  /// Kembali ke Katalog (dipakai saat halaman ini berdiri sendiri).
  void _keKatalog() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HalamanUtama()),
      (route) => false,
    );
  }

  /// "Pesan Lagi" — menambahkan item pesanan lama ke keranjang lewat
  /// `POST /api/keranjang`. Galat per item dilaporkan, tidak ditelan diam-diam.
  Future<void> _pesanLagi(Pesanan pesanan) async {
    if (_sedangPesanLagi || pesanan.items.isEmpty) return;

    setState(() => _sedangPesanLagi = true);

    int berhasil = 0;
    int dilewati = 0;
    String? galatTerakhir;

    for (final item in pesanan.items) {
      if (item.produkId == null) {
        dilewati++;
        continue;
      }

      try {
        await _layanan.tambahKeKeranjang(
          produkId: item.produkId!,
          jumlah: item.jumlah,
          tingkatPedas: item.tingkatPedas,
        );
        berhasil++;
      } on GalatApi catch (g) {
        dilewati++;
        galatTerakhir = g.pesan;
      } catch (_) {
        dilewati++;
      }
    }

    if (!mounted) return;
    setState(() => _sedangPesanLagi = false);

    final pesan = switch ((berhasil, dilewati)) {
      (0, _) => galatTerakhir ?? 'Menu tidak dapat ditambahkan ke keranjang.',
      (_, 0) => '$berhasil menu dimasukkan ke keranjang.',
      _ => '$berhasil menu masuk keranjang, $dilewati dilewati. '
            '${galatTerakhir ?? ''}',
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: berhasil > 0
              ? TemaWarna.hitamTombol
              : TemaWarna.merahHabis,
          content: Text(pesan.trim()),
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: TemaWarna.teksUtama,
          ),
          onPressed: () {
            if (widget.saatPilihMenu != null) {
              widget.saatPilihMenu!();
            } else {
              _keKatalog();
            }
          },
        ),
        title: const Text(
          'Riwayat Pesanan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: TemaWarna.teksUtama,
          ),
        ),
      ),
      body: _bangunKonten(),
    );
  }

  Widget _bangunKonten() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const TampilanMuat(pesan: 'Memuat riwayat pesanan...');

      case KeadaanMuat.galat:
        return TampilanGalat(
          galat: _galat,
          saatCobaLagi: _muatRiwayat,
        );

      case KeadaanMuat.kosong:
        return TampilanKosong(
          ikon: Icons.receipt_long_outlined,
          judul: 'Belum Ada Pesanan',
          pesan: 'Kamu belum pernah membuat pesanan makanan atau minuman.',
          teksAksi: 'Pesan Menu Sekarang',
          saatAksiDitekan: widget.saatPilihMenu ?? _keKatalog,
        );

      case KeadaanMuat.berhasil:
        return _bangunDaftar();
    }
  }

  Widget _bangunDaftar() {
    final List<String> statusFilter = switch (_filterTerpilih) {
      'Selesai' => const ['selesai'],
      'Dibatalkan' => const ['dibatalkan'],
      _ => const [],
    };
    final pesananTampil = statusFilter.isEmpty
        ? _daftarPesanan
        : _daftarPesanan
            .where((p) => statusFilter.contains(p.status))
            .toList();

    return RefreshIndicator(
      color: TemaWarna.cokelatUtama,
      onRefresh: _muatRiwayat,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Banner keberhasilan (design Figma, bisa ditutup)
          if (_bannerTampil) _bannerSelesai(),

          // Filter status: Semua, Selesai, Dibatalkan
          Row(
            children: ['Semua', 'Selesai', 'Dibatalkan'].map((f) {
              final aktif = _filterTerpilih == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f),
                  selected: aktif,
                  onSelected: (val) {
                    if (val) setState(() => _filterTerpilih = f);
                  },
                  selectedColor: TemaWarna.cokelatUtama,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: aktif ? Colors.white : TemaWarna.teksUtama,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: aktif
                          ? TemaWarna.cokelatUtama
                          : TemaWarna.garisAbu,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          if (pesananTampil.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Tidak ada pesanan berstatus $_filterTerpilih.',
                  style: const TextStyle(color: TemaWarna.teksSekunder),
                ),
              ),
            )
          else
            ...pesananTampil.map(_kartuPesanan),
        ],
      ),
    );
  }

  Widget _bannerSelesai() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: TemaWarna.kremPeach,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: TemaWarna.hijauBuka,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesanan Berhasil Diselesaikan!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TemaWarna.teksUtama,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Terima kasih telah menikmati sajian MakanYuk!.',
                  style: TextStyle(
                    fontSize: 11,
                    color: TemaWarna.teksSekunder,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Tutup',
            icon: const Icon(Icons.close_rounded, size: 18),
            color: TemaWarna.teksSekunder,
            onPressed: () => setState(() => _bannerTampil = false),
          ),
        ],
      ),
    );
  }

  Widget _kartuPesanan(Pesanan pesanan) {
    final bool selesai = pesanan.status == 'selesai';
    final bool batal = pesanan.status == 'dibatalkan';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${_formatWaktu(pesanan.dibuatPada)}\n${pesanan.nomorPesanan}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TemaWarna.teksSekunder,
                    height: 1.4,
                  ),
                ),
              ),
              _lencanaStatus(pesanan, selesai: selesai, batal: batal),
            ],
          ),
          const Divider(height: 20),
          InkWell(
            onTap: () => _bukaDetailPesanan(pesanan),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: GambarMenu(
                      nama: pesanan.items.isEmpty
                          ? ''
                          : pesanan.items.first.namaProduk,
                      kategori: 'Makanan',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ringkasanMenu(pesanan),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: TemaWarna.teksUtama,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subItem(pesanan),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatRupiah(pesanan.total)} • ${pesanan.items.length} Menu',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: TemaWarna.cokelatUtama,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (selesai) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text('Terima kasih atas ulasanmu!'),
                        ),
                      );
                  },
                  icon: const Icon(Icons.star_outline_rounded, size: 16),
                  label: const Text(
                    'Beri Ulasan',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TemaWarna.teksUtama,
                    side: const BorderSide(color: TemaWarna.garisAbu),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton.icon(
                onPressed:
                    _sedangPesanLagi ? null : () => _pesanLagi(pesanan),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'Pesan Lagi',
                  style: TextStyle(fontSize: 12),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: TemaWarna.cokelatUtama,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lencanaStatus(
    Pesanan pesanan, {
    required bool selesai,
    required bool batal,
  }) {
    final (warnaLatar, warnaTeks) = selesai
        ? (Colors.green.shade50, TemaWarna.hijauBuka)
        : batal
            ? (Colors.red.shade50, TemaWarna.merahHabis)
            : (Colors.orange.shade50, const Color(0xFFE67E22));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: warnaLatar,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '● ${pesanan.labelStatus}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: warnaTeks,
        ),
      ),
    );
  }

  /// Nama menu utama, mis. `Iced Latte + 1 Menu lainnya`.
  String _ringkasanMenu(Pesanan pesanan) {
    if (pesanan.items.isEmpty) return 'Pesanan ${pesanan.nomorPesanan}';

    final pertama = pesanan.items.first.namaProduk;
    final sisa = pesanan.items.length - 1;

    return sisa > 0 ? '$pertama + $sisa Menu lainnya' : pertama;
  }

  String _subItem(Pesanan pesanan) {
    if (pesanan.items.length > 1) return pesanan.items[1].namaProduk;

    final catatan = pesanan.items.isEmpty
        ? null
        : pesanan.items.first.catatan?.trim();
    if (catatan != null && catatan.isNotEmpty) return catatan;

    return pesanan.namaMetode ?? pesanan.labelStatus;
  }

  /// Menampilkan `created_at` server tanpa bagian milidetik/zona.
  String _formatWaktu(String? raw) {
    if (raw == null || raw.isEmpty) return '-';

    return raw.replaceFirst('T', ' ').split('.').first;
  }
}
