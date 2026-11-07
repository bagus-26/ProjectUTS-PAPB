import 'package:flutter/material.dart';
import '../umum/tema_warna.dart';
import '../widget/tombol_utama.dart';

/// Halaman Detail Pesanan & Pelacakan Pengantaran Makanan (Kelompok 1)
/// Sesuai UI rancangan Screenshot 7 & 8
class HalamanDetailPesanan extends StatefulWidget {
  final String nomorPesanan;
  final List<Map<String, dynamic>> items;
  final int totalBayar;
  final String metodeBayar;

  const HalamanDetailPesanan({
    super.key,
    required this.nomorPesanan,
    required this.items,
    required this.totalBayar,
    this.metodeBayar = 'Tunai di Tempat (COD)',
  });

  @override
  State<HalamanDetailPesanan> createState() => _HalamanDetailPesananState();
}

class _HalamanDetailPesananState extends State<HalamanDetailPesanan> {
  String _status = 'Dalam Pengiriman';

  void _konfirmasiDiterima() {
    setState(() => _status = 'Selesai');

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: TemaWarna.hitamTombol,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pesanan Telah Diterima!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Terima kasih sudah memesan di Foodify. Selamat menikmati sajian kulinermu!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: TemaWarna.teksSekunder),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TemaWarna.latarKrem,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.nomorPesanan,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${widget.items.length} Menu Pilihan',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Text(
                    TemaWarna.formatRupiah(widget.totalBayar),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: TemaWarna.cokelatUtama,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TombolUtama(
              teks: 'Kembali ke Menu Utama',
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
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
          'Detail Pesanan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: TemaWarna.teksUtama,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // Banner Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '● $_status',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: TemaWarna.hijauBuka,
                        ),
                      ),
                    ),
                    Text(
                      widget.nomorPesanan,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pesanan Menuju Lokasimu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Driver kurir internal sedang membawa pesananmu.',
                  style: TextStyle(fontSize: 13, color: TemaWarna.teksSekunder),
                ),
                const SizedBox(height: 16),
                // Stepper sederhana
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StepItem(label: 'Dibuat', selesai: true),
                    _StepItem(label: 'Diracik', selesai: true),
                    _StepItem(label: 'Dikirim', selesai: true, aktif: true),
                    _StepItem(label: 'Selesai', selesai: false),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Info Kurir
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: TemaWarna.kremTua,
                  child: Text('BP', style: TextStyle(fontWeight: FontWeight.bold, color: TemaWarna.cokelatUtama)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Budi Pratama • Kurir Toko', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('Honda Vario • N 4921 AA', style: TextStyle(fontSize: 12, color: TemaWarna.teksSekunder)),
                    ],
                  ),
                ),
                Icon(Icons.phone_rounded, color: TemaWarna.cokelatUtama),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Rincian Item yang Dipesan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rincian Menu (${widget.items.length} Menu)',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 10),
                ...widget.items.map((item) {
                  final varian = item['varian'];
                  final namaVarian = varian is Map
                      ? varian['nama']?.toString()
                      : item['varian_porsi']?.toString();
                  final tingkatPedas = switch (item['tingkat_pedas']) {
                    'tidak_pedas' => 'Tidak Pedas',
                    'sedang' => 'Sedang',
                    'pedas' => 'Pedas',
                    'sangat_pedas' => 'Sangat Pedas',
                    _ => item['tingkat_kepedasan']?.toString(),
                  };
                  final subtotalItem = item['subtotal'] is int
                      ? item['subtotal'] as int
                      : (item['harga_satuan'] as int? ??
                              item['harga'] as int? ??
                              0) *
                          (item['jumlah'] as int? ?? 1);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['jumlah']}x ${item['nama']}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              if (namaVarian != null)
                                Text(
                                  tingkatPedas == null
                                      ? namaVarian
                                      : '$namaVarian • $tingkatPedas',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          TemaWarna.formatRupiah(subtotalItem),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      TemaWarna.formatRupiah(widget.totalBayar),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: TemaWarna.cokelatUtama,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        color: Colors.white,
        child: SafeArea(
          child: TombolUtama(
            teks: 'Konfirmasi Pesanan Diterima',
            warnaLatar: TemaWarna.hitamTombol,
            onPressed: _status == 'Selesai' ? null : _konfirmasiDiterima,
          ),
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String label;
  final bool selesai;
  final bool aktif;

  const _StepItem({
    required this.label,
    required this.selesai,
    this.aktif = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: selesai
              ? (aktif ? TemaWarna.cokelatUtama : Colors.green)
              : Colors.grey.shade300,
          child: Icon(
            selesai ? Icons.check : Icons.circle,
            size: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: aktif ? FontWeight.bold : FontWeight.normal,
            color: aktif ? TemaWarna.cokelatUtama : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
