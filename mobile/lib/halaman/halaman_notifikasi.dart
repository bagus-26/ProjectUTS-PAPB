import 'package:flutter/material.dart';

import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../model/notifikasi.dart';
import '../umum/tema_warna.dart';
import '../widget/tampilan_galat.dart';
import '../widget/tampilan_muat.dart';

/// Daftar notifikasi lonceng pelanggan (`GET /api/notifications`).
///
/// Saat halaman dibuka, semua notifikasi ditandai terbaca sehingga lencana
/// lonceng di Home ikut bersih.
class HalamanNotifikasi extends StatefulWidget {
  const HalamanNotifikasi({super.key});

  @override
  State<HalamanNotifikasi> createState() => _HalamanNotifikasiState();
}

class _HalamanNotifikasiState extends State<HalamanNotifikasi> {
  final LayananApi _api = LayananApi();

  DaftarNotifikasi _daftar = const DaftarNotifikasi();
  String? _galat;
  bool _memuat = true;

  @override
  void initState() {
    super.initState();
    _muatNotifikasi();
  }

  Future<void> _muatNotifikasi({bool tampilkanMemuat = true}) async {
    if (tampilkanMemuat) {
      setState(() {
        _memuat = true;
        _galat = null;
      });
    }

    try {
      final daftar = await _api.ambilNotifikasi();
      if (!mounted) return;
      setState(() {
        _daftar = daftar;
        _memuat = false;
        _galat = null;
      });

      if (daftar.jumlahBelumDibaca > 0) {
        try {
          await _api.tandaiNotifikasiTerbaca();
        } catch (_) {
          // Lencana akan dicoba lagi pada kunjungan berikutnya.
        }
      }
    } on GalatApi catch (galat) {
      if (!mounted) return;
      setState(() {
        _galat = galat.pesan;
        _memuat = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _galat = 'Notifikasi tidak dapat dimuat. Coba lagi.';
        _memuat = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () => _muatNotifikasi(tampilkanMemuat: false),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _bangunIsi(),
    );
  }

  Widget _bangunIsi() {
    if (_memuat) {
      return const TampilanMuat(pesan: 'Memuat notifikasi...');
    }

    if (_galat != null) {
      return TampilanGalat(
        pesanKustom: _galat,
        saatCobaLagi: _muatNotifikasi,
      );
    }

    if (_daftar.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: const BoxDecoration(
                  color: TemaWarna.kremLembut,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 44,
                  color: TemaWarna.cokelatKaramel,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada notifikasi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Info poin reward dan balasan CS akan muncul di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: TemaWarna.teksSekunder),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: TemaWarna.cokelatKaramel,
      onRefresh: () => _muatNotifikasi(tampilkanMemuat: false),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: _daftar.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _kartu(_daftar.items[index]),
      ),
    );
  }

  Widget _kartu(Notifikasi notifikasi) {
    final (IconData ikon, Color warna) = switch (notifikasi.tipe) {
      'poin' => (Icons.stars_rounded, TemaWarna.kuningBintang),
      'support' => (Icons.support_agent_rounded, TemaWarna.cokelatKaramel),
      _ => (Icons.notifications_rounded, TemaWarna.cokelatKaramel),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notifikasi.sudahDibaca ? Colors.white : TemaWarna.kremLembut,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notifikasi.sudahDibaca
              ? TemaWarna.garisAbu
              : TemaWarna.cokelatKaramel.withAlpha(70),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(ikon, color: warna, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notifikasi.judul,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: notifikasi.sudahDibaca
                              ? FontWeight.w600
                              : FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!notifikasi.sudahDibaca)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: TemaWarna.cokelatKaramel,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  notifikasi.pesan,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: TemaWarna.teksSekunder,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatWaktu(notifikasi.dibuatPada),
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: TemaWarna.teksSekunder,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatWaktu(String? teks) {
  if (teks == null || teks.isEmpty) return '';
  final waktu = DateTime.tryParse(teks);
  if (waktu == null) return '';

  const bulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  final lokal = waktu.toLocal();
  final jam = lokal.hour.toString().padLeft(2, '0');
  final menit = lokal.minute.toString().padLeft(2, '0');

  return '${lokal.day} ${bulan[lokal.month - 1]} ${lokal.year} • $jam:$menit';
}
