import 'dart:async';

import 'package:flutter/material.dart';

import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../model/pesanan.dart';
import '../umum/keadaan_muat.dart';
import '../umum/tema_warna.dart';
import '../umum/format_rupiah.dart';
import '../umum/galat_ui.dart';
import '../widget/tampilan_galat.dart';
import '../widget/tampilan_kosong.dart';
import '../widget/tampilan_muat.dart';
import '../widget/tombol_utama.dart';
import '../widget/gambar_menu.dart';
import 'halaman_riwayat_pesanan.dart';
import 'halaman_utama.dart';

/// Halaman Rincian Pesanan (`HalamanRincianPesanan` pada PRD 7.1).
///
/// * `GET /pesanan/{id}` — nomor, status, item + harga saat beli, total, metode.
/// * `PATCH /pesanan/{id}/status` — tombol **Bayar (simulasi)** mengirim
///   `menunggu_konfirmasi`; tombol terima mengirim `selesai` (PRD Bagian 6.7).
/// * Setelah aksi final → Katalog dengan tumpukan dibersihkan
///   (`pushAndRemoveUntil`).
class HalamanDetailPesanan extends StatefulWidget {
  final int pesananId;

  const HalamanDetailPesanan({super.key, required this.pesananId});

  @override
  State<HalamanDetailPesanan> createState() => _HalamanDetailPesananState();
}

class _HalamanDetailPesananState extends State<HalamanDetailPesanan> {
  final LayananApi _layanan = LayananApi();

  // Empat keadaan layar eksplisit (PRD 7.2)
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  Pesanan? _pesanan;
  GalatApi? _galat;

  bool _sedangMengirim = false;
  Timer? _timerPembaruan;

  @override
  void initState() {
    super.initState();
    _muatRincian();
    _timerPembaruan = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _muatRincianSenyap(),
    );
  }

  @override
  void dispose() {
    _timerPembaruan?.cancel();
    super.dispose();
  }

  /// Pembaruan senyap tiap 3 detik: tidak mengubah keadaan memuat.
  Future<void> _muatRincianSenyap() async {
    if (_sedangMengirim) return;
    try {
      final hasil = await _layanan.ambilRincianPesanan(widget.pesananId);
      if (!mounted) return;
      setState(() => _pesanan = hasil);
    } catch (_) {
      // Abaikan galat polling agar tidak mengganggu UI.
    }
  }
  Future<void> _muatRincian() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _galat = null;
    });

    try {
      final hasil = await _layanan.ambilRincianPesanan(widget.pesananId);
      if (!mounted) return;
      setState(() {
        _pesanan = hasil;
        _keadaan = KeadaanMuat.berhasil;
      });
    } on GalatApi catch (g) {
      if (!mounted) return;
      setState(() {
        _galat = g;
        _keadaan = g.jenis == JenisGalat.tidakDitemukan
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

  /// `PATCH /api/pesanan/{id}/status` — hanya transisi sah (PRD 6.7).
  /// 409/422 tampil inline tanpa pindah halaman (PRD 7.3).
  Future<void> _ubahStatus(String statusTujuan) async {
    if (_sedangMengirim) return;

    setState(() => _sedangMengirim = true);
    try {
      final hasil = await _layanan.ubahStatusPesanan(
        id: widget.pesananId,
        status: statusTujuan,
      );
      if (!mounted) return;
      setState(() => _pesanan = hasil);

      if (statusTujuan == 'selesai') _tampilkanKonfirmasiDiterima();
    } on GalatApi catch (g) {
      tampilkanGalat(context, g);
      // Segarkan agar layar konsisten dengan keadaan server
      await _muatRincian();
    } catch (_) {
      tampilkanGalat(context, GalatApi.umum());
    } finally {
      if (mounted) setState(() => _sedangMengirim = false);
    }
  }

  /// Bayar simulasi: `menunggu_pembayaran` → `menunggu_konfirmasi` (A5-04).
  void _bayarSimulasi() => _ubahStatus('menunggu_konfirmasi');

  void _konfirmasiDiterima() => _ubahStatus('selesai');

  /// Kembali ke Katalog dengan tumpukan rute dibersihkan (PRD 7.1).
  void _keKatalog() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HalamanUtama()),
      (route) => false,
    );
  }

  void _keRiwayat() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HalamanRiwayatPesanan()),
      (route) => false,
    );
  }

  void _tampilkanKonfirmasiDiterima() {
    final pesanan = _pesanan;
    if (pesanan == null) return;

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
                color: TemaWarna.cokelatUtama,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.check_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pesanan Telah Diterima!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Terima kasih sudah memesan di MakanYuk!. Selamat menikmati sajian kulinermu!',
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
                      Text(
                        pesanan.nomorPesanan,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${pesanan.items.length} Menu Pilihan',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    formatRupiah(pesanan.total),
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
              teks: 'Lihat Riwayat Pesanan',
              warnaLatar: TemaWarna.cokelatUtama,
              onPressed: _keRiwayat,
            ),
            const SizedBox(height: 10),
            TombolUtama(
              teks: 'Kembali ke Menu Utama',
              warnaLatar: TemaWarna.hitamTombol,
              onPressed: _keKatalog,
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
      body: _bangunIsi(),
      bottomNavigationBar: _keadaan == KeadaanMuat.berhasil
          ? _bangunBilahBawah()
          : null,
    );
  }

  Widget _bangunIsi() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const TampilanMuat(pesan: 'Memuat rincian pesanan...');

      case KeadaanMuat.galat:
        return TampilanGalat(
          galat: _galat,
          saatCobaLagi: _muatRincian,
        );

      case KeadaanMuat.kosong:
        return TampilanKosong(
          ikon: Icons.receipt_long_outlined,
          judul: 'Pesanan Tidak Ditemukan',
          pesan: _galat?.pesan ??
              'Pesanan yang kamu cari tidak ada atau sudah dihapus.',
          teksAksi: 'Lihat Riwayat Pesanan',
          saatAksiDitekan: _keRiwayat,
        );

      case KeadaanMuat.berhasil:
        return _bangunIsiPesanan(_pesanan!);
    }
  }

  Widget _bangunIsiPesanan(Pesanan pesanan) {
    final langkah = _langkahStatus(pesanan.status);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // 1. Banner status + nomor pesanan + stepper
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
                  _lencanaStatus(pesanan.status),
                  Text(
                    pesanan.nomorPesanan,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _judulStatus(pesanan.status),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _pesanStatus(pesanan.status),
                style: const TextStyle(
                  fontSize: 13,
                  color: TemaWarna.teksSekunder,
                ),
              ),
              const SizedBox(height: 16),
              if (pesanan.status != 'dibatalkan')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var i = 0; i < 4; i++)
                      _StepItem(
                        label: const ['Dibuat', 'Diracik', 'Dikirim', 'Selesai'][i],
                        selesai: i < langkah || pesanan.status == 'selesai',
                        aktif: i == langkah && pesanan.status != 'selesai',
                      ),
                  ],
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Info kurir (bila server mengirimkannya)
        if (pesanan.namaKurir != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: TemaWarna.kremTua,
                  child: Text(
                    'KT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: TemaWarna.cokelatUtama,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pesanan.namaKurir} • Kurir Toko',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (pesanan.wilayahKurir != null &&
                          pesanan.wilayahKurir!.isNotEmpty)
                        Text(
                          pesanan.wilayahKurir!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: TemaWarna.teksSekunder,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.delivery_dining_rounded,
                  color: TemaWarna.cokelatUtama,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 3. Rincian item + harga saat beli (snapshot D-08)
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
                'Rincian Menu (${pesanan.items.length} Menu)',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              for (final item in pesanan.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: GambarMenu(
                            nama: item.namaProduk,
                            kategori: 'Makanan',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.jumlah}x ${item.namaProduk}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (item.varianNama != null ||
                                item.labelPedas != null)
                              Text(
                                [
                                  if (item.varianNama != null) item.varianNama!,
                                  if (item.labelPedas != null) item.labelPedas!,
                                ].join(' • '),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            if (item.catatan != null &&
                                item.catatan!.trim().isNotEmpty)
                              Text(
                                'Catatan: ${item.catatan}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        formatRupiah(item.subtotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 20),
              _barisTotal('Metode Pembayaran',
                  pesanan.namaMetode ?? pesanan.kodeMetode),
              if (pesanan.ongkosKirim != null)
                _barisTotal('Ongkos Kirim', formatRupiah(pesanan.ongkosKirim!)),
              _barisTotal(
                'Total Pembayaran',
                formatRupiah(pesanan.total),
                tebal: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _barisTotal(String label, String nilai, {bool tebal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: tebal ? FontWeight.w700 : FontWeight.w400,
              color: tebal ? TemaWarna.teksUtama : TemaWarna.teksSekunder,
            ),
          ),
          Text(
            nilai,
            style: TextStyle(
              fontSize: tebal ? 15 : 13,
              fontWeight: tebal ? FontWeight.w800 : FontWeight.w600,
              color: tebal ? TemaWarna.cokelatUtama : TemaWarna.teksUtama,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lencanaStatus(String status) {
    final (warna, teks) = switch (status) {
      'selesai' => (Colors.green.shade50, '● Selesai'),
      'dibatalkan' => (Colors.red.shade50, '● Dibatalkan'),
      'dibayar' || 'diproses' || 'dikirim' => (
          Colors.green.shade50,
          '● ${_judulStatus(status)}',
        ),
      _ => (Colors.orange.shade50, '● ${_judulStatus(status)}'),
    };

    final warnaTeks = switch (status) {
      'selesai' || 'dibayar' || 'diproses' || 'dikirim' => TemaWarna.hijauBuka,
      'dibatalkan' => TemaWarna.merahHabis,
      _ => const Color(0xFFE67E22),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: warna,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        teks,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: warnaTeks,
        ),
      ),
    );
  }

  /// Posisi stepper: 0 Dibuat, 1 Diracik, 2 Dikirim, 3 Selesai.
  int _langkahStatus(String status) => switch (status) {
    'menunggu_pembayaran' || 'menunggu_konfirmasi' => 0,
    'dibayar' || 'diproses' => 1,
    'dikirim' => 2,
    'selesai' => 3,
    _ => 0,
  };

  String _judulStatus(String status) => switch (status) {
    'menunggu_pembayaran' => 'Menunggu Pembayaran',
    'menunggu_konfirmasi' => 'Menunggu Konfirmasi',
    'dibayar' => 'Sudah Dibayar',
    'diproses' => 'Sedang Diracik',
    'dikirim' => 'Dalam Pengiriman',
    'selesai' => 'Pesanan Selesai',
    'dibatalkan' => 'Pesanan Dibatalkan',
    _ => status,
  };

  String _pesanStatus(String status) => switch (status) {
    'menunggu_pembayaran' =>
      'Selesaikan pembayaran simulasi agar pesanan segera diproses.',
    'menunggu_konfirmasi' => 'Pembayaran sedang diverifikasi oleh toko.',
    'dibayar' => 'Pembayaran diterima, pesanan segera diracik.',
    'diproses' => 'Pesanan sedang disiapkan di dapur toko.',
    'dikirim' => 'Kurir internal sedang membawa pesananmu.',
    'selesai' => 'Pesanan sudah diterima. Terima kasih!',
    'dibatalkan' => 'Pesanan ini dibatalkan dan tidak akan diproses.',
    _ => '',
  };

  Widget _bangunBilahBawah() {
    final pesanan = _pesanan;
    if (pesanan == null) return const SizedBox.shrink();

    final bool bisaBayar =
        pesanan.status == 'menunggu_pembayaran' && !_sedangMengirim;
    final bool bisaTerima = pesanan.status == 'dikirim' && !_sedangMengirim;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      color: Colors.white,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (bisaBayar)
              TombolUtama(
                teks: 'Bayar (Simulasi) • ${formatRupiah(pesanan.total)}',
                warnaLatar: TemaWarna.cokelatUtama,
                sedangMemuat: _sedangMengirim,
                onPressed: _bayarSimulasi,
              )
            else if (bisaTerima)
              TombolUtama(
                teks: 'Konfirmasi Pesanan Diterima',
                warnaLatar: TemaWarna.cokelatUtama,
                sedangMemuat: _sedangMengirim,
                onPressed: _konfirmasiDiterima,
              )
            else if (pesanan.status == 'selesai' ||
                pesanan.status == 'dibatalkan')
              TombolUtama(
                teks: 'Kembali ke Menu Utama',
                warnaLatar: TemaWarna.hitamTombol,
                onPressed: _keKatalog,
              )
            else
              TombolUtama(
                teks: _judulStatus(pesanan.status),
                warnaLatar: TemaWarna.cokelatMuda,
                onPressed: null,
              ),
          ],
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
