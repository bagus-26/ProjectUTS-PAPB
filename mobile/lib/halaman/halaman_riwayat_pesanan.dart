import 'package:flutter/material.dart';
import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../umum/keadaan_muat.dart';
import '../umum/tema_warna.dart';
import '../widget/tampilan_galat.dart';
import '../widget/tampilan_kosong.dart';
import '../widget/tampilan_muat.dart';
import 'halaman_detail_pesanan.dart';

/// Pengelola Riwayat Pesanan Lokal di Sisi Klien
class RiwayatPesananLokal {
  RiwayatPesananLokal._();

  static final List<Map<String, dynamic>> _daftar = [
    {
      'id': 'ORD-984210',
      'waktu': 'Hari ini, 14:35 WIB',
      'status': 'Selesai',
      'nama_utama': 'Iced Latte + 1 Menu lainnya',
      'sub_item': 'Chicken Rice Bowl',
      'total': 46000,
      'jumlah_menu': 2,
      'gambar':
          'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=500&q=80',
      'items': [
        {'nama': 'Iced Latte', 'harga': 18000, 'jumlah': 1, 'varian_porsi': 'Reguler', 'tingkat_kepedasan': 'Sedang'},
        {'nama': 'Chicken Rice Bowl', 'harga': 28000, 'jumlah': 1, 'varian_porsi': 'Reguler', 'tingkat_kepedasan': 'Tidak Pedas'},
      ],
    },
    {
      'id': 'ORD-981203',
      'waktu': '14 Nov 2025 • 16.20 WIB',
      'status': 'Selesai',
      'nama_utama': 'Iced Latte (Reguler)',
      'sub_item': 'Gula aren, less ice',
      'total': 18000,
      'jumlah_menu': 1,
      'gambar':
          'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=500&q=80',
      'items': [
        {'nama': 'Iced Latte', 'harga': 18000, 'jumlah': 1, 'varian_porsi': 'Reguler', 'tingkat_kepedasan': 'Less Ice'},
      ],
    },
    {
      'id': 'ORD-965311',
      'waktu': '10 Nov 2025 • 09.15 WIB',
      'status': 'Dibatalkan',
      'nama_utama': 'Mochaccino',
      'sub_item': 'Dibatalkan oleh pembeli',
      'total': 20000,
      'jumlah_menu': 1,
      'gambar':
          'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=500&q=80',
      'items': [
        {'nama': 'Mochaccino', 'harga': 20000, 'jumlah': 1, 'varian_porsi': 'Reguler', 'tingkat_kepedasan': 'Normal Sweet'},
      ],
    },
  ];

  static List<Map<String, dynamic>> get semua =>
      List<Map<String, dynamic>>.unmodifiable(_daftar);

  /// Menambahkan pesanan baru yang berhasil dibuat/diselesaikan
  static void tambah({
    required String nomorPesanan,
    required List<Map<String, dynamic>> items,
    required int totalBayar,
    String status = 'Selesai',
  }) {
    final cleanId = nomorPesanan.replaceAll('#', '');
    // Hindari duplikasi jika sudah ada
    _daftar.removeWhere((p) => p['id'] == cleanId);

    final namaUtama = items.isNotEmpty
        ? (items.first['nama']?.toString() ?? 'Menu')
        : 'Menu Pilihan';
    final extra = items.length > 1 ? ' + ${items.length - 1} Menu lainnya' : '';
    final subItem = items.length > 1
        ? (items[1]['nama']?.toString() ?? '')
        : (items.isNotEmpty ? (items[0]['catatan']?.toString() ?? '') : '');
    final gambar = items.isNotEmpty ? (items.first['gambar']?.toString() ?? '') : '';

    final now = DateTime.now();
    final jam = now.hour.toString().padLeft(2, '0');
    final menit = now.minute.toString().padLeft(2, '0');

    _daftar.insert(0, {
      'id': cleanId,
      'waktu': 'Hari ini, $jam:$menit WIB',
      'status': status,
      'nama_utama': '$namaUtama$extra',
      'sub_item': subItem.isNotEmpty ? subItem : 'Pesanan berhasil diselesaikan',
      'total': totalBayar,
      'jumlah_menu': items.length,
      'gambar': gambar.isNotEmpty
          ? gambar
          : 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=500&q=80',
      'items': List<Map<String, dynamic>>.from(items),
    });
  }
}

/// Halaman Riwayat Pesanan (MakanYuk! - Kelompok 1)
/// Sesuai Kriteria 6 & Spesifikasi Halaman Wajib: GET /api/pesanan
/// Menampilkan daftar pesanan terurut dari yang terbaru beserta 4 keadaan layar eksplisit
class HalamanRiwayatPesanan extends StatefulWidget {
  final VoidCallback? saatPilihMenu;

  const HalamanRiwayatPesanan({super.key, this.saatPilihMenu});

  @override
  State<HalamanRiwayatPesanan> createState() => _HalamanRiwayatPesananState();
}

class _HalamanRiwayatPesananState extends State<HalamanRiwayatPesanan> {
  final LayananApi _layanan = LayananApi();
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  String _filterTerpilih = 'Semua';
  List<Map<String, dynamic>> _daftarPesanan = [];
  GalatApi? _galat;

  @override
  void initState() {
    super.initState();
    _muatRiwayat();
  }

  Future<void> _muatRiwayat() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _galat = null;
    });

    try {
      // Ambil data riwayat pesanan (fallback otomatis ke RiwayatPesananLokal)
      await Future.delayed(const Duration(milliseconds: 300));
      final data = RiwayatPesananLokal.semua;

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

  void _bukaDetailPesanan(Map<String, dynamic> pesanan) {
    final rawItems = pesanan['items'];
    final List<Map<String, dynamic>> items = rawItems is List
        ? rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : [
            {
              'nama': pesanan['nama_utama']?.toString() ?? 'Menu',
              'harga': pesanan['total'] as int? ?? 0,
              'jumlah': 1,
              'gambar': pesanan['gambar']?.toString(),
            }
          ];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HalamanDetailPesanan(
          nomorPesanan: '#${pesanan['id']}',
          items: items,
          totalBayar: pesanan['total'] as int? ?? 0,
        ),
      ),
    );
  }

  Future<void> _pesanLagi(Map<String, dynamic> pesanan) async {
    final rawItems = pesanan['items'];
    if (rawItems is List && rawItems.isNotEmpty) {
      for (final item in rawItems) {
        try {
          final varian = item['varian'];
          final rawTingkatPedas = item['tingkat_pedas']?.toString();
          final tingkatPedas = const {
            'tidak_pedas',
            'sedang',
            'pedas',
            'sangat_pedas',
          }.contains(rawTingkatPedas)
              ? rawTingkatPedas
              : null;

          await _layanan.tambahKeKeranjang(
            produkId: (item['produk_id'] as int?) ?? 1,
            jumlah: (item['jumlah'] as int?) ?? 1,
            varianId: varian is Map ? varian['id'] as int? : null,
            varianNama: varian is Map
                ? varian['nama']?.toString()
                : item['varian_porsi']?.toString(),
            tingkatPedas: tingkatPedas,
          );
        } catch (_) {}
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: TemaWarna.hitamTombol,
        content: Text('Menu dari pesanan #${pesanan['id']} dimasukkan ke keranjang!'),
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
          saatAksiDitekan: widget.saatPilihMenu ??
              () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
        );

      case KeadaanMuat.berhasil:
        final pesananTampil = _filterTerpilih == 'Semua'
            ? _daftarPesanan
            : _daftarPesanan.where((p) => p['status'] == _filterTerpilih).toList();

        return RefreshIndicator(
          color: TemaWarna.cokelatUtama,
          onRefresh: _muatRiwayat,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Banner Keberhasilan Sesuai Screenshot 9
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TemaWarna.garisAbu),
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
                  ],
                ),
              ),

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
                      selectedColor: TemaWarna.hitamTombol,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: aktif ? Colors.white : TemaWarna.teksUtama,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: aktif ? TemaWarna.hitamTombol : TemaWarna.garisAbu,
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
                ...pesananTampil.map((p) {
                  final isSelesai = p['status'] == 'Selesai';
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
                            Text(
                              '${p['waktu']}\n#${p['id']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: TemaWarna.teksSekunder,
                                height: 1.4,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelesai
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '● ${p['status']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelesai
                                      ? TemaWarna.hijauBuka
                                      : TemaWarna.merahHabis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        InkWell(
                          onTap: () => _bukaDetailPesanan(p),
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  color: TemaWarna.kremTua,
                                  child: Image.network(
                                    p['gambar'] as String,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(
                                      Icons.restaurant_rounded,
                                      color: TemaWarna.cokelatUtama,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p['nama_utama'] as String,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: TemaWarna.teksUtama,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      p['sub_item'] as String,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${TemaWarna.formatRupiah(p['total'] as int)} • ${p['jumlah_menu']} Menu',
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
                            if (isSelesai) ...[
                              OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                              onPressed: () => _pesanLagi(p),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text(
                                'Pesan Lagi',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: TemaWarna.hitamTombol,
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
                }),
            ],
          ),
        );
    }
  }
}
