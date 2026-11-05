import 'package:flutter/material.dart';
import '../umum/tema_warna.dart';

/// Halaman Riwayat Pesanan (Kelompok 1)
/// Menampilkan daftar pesanan dengan filter status Selesai & Dibatalkan
class HalamanRiwayatPesanan extends StatefulWidget {
  const HalamanRiwayatPesanan({super.key});

  @override
  State<HalamanRiwayatPesanan> createState() => _HalamanRiwayatPesananState();
}

class _HalamanRiwayatPesananState extends State<HalamanRiwayatPesanan> {
  String _filterTerpilih = 'Semua';

  final List<Map<String, dynamic>> _dataPesanan = [
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
    },
  ];

  @override
  Widget build(BuildContext context) {
    final pesananTampil = _filterTerpilih == 'Semua'
        ? _dataPesanan
        : _dataPesanan.where((p) => p['status'] == _filterTerpilih).toList();

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Filter status
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
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ...pesananTampil.map((p) {
            final isSelesai = p['status'] == 'Selesai';
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
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
                            horizontal: 10, vertical: 4),
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
                  Row(
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
                            errorBuilder: (context, error, stackTrace) => const Icon(
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
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isSelesai) ...[
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Beri Ulasan',
                              style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: TemaWarna.hitamTombol,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Pesan Lagi',
                            style: TextStyle(fontSize: 12)),
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
