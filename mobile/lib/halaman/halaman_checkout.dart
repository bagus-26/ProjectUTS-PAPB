import 'package:flutter/material.dart';
import '../layanan/galat_api.dart';
import '../umum/tema_warna.dart';
import '../widget/tombol_utama.dart';
import 'halaman_detail_pesanan.dart';

/// Halaman Checkout Transaksi (Kelompok 1)
/// Menampilkan aturan bisnis jam operasional toko (08.00-22.00 WIB),
/// pemilihan kurir internal, serta simulasi pembayaran COD / Transfer.
class HalamanCheckout extends StatefulWidget {
  final int subtotal;
  final List<Map<String, dynamic>> items;

  const HalamanCheckout({
    super.key,
    required this.subtotal,
    required this.items,
  });

  @override
  State<HalamanCheckout> createState() => _HalamanCheckoutState();
}

class _HalamanCheckoutState extends State<HalamanCheckout> {
  int _ongkosKirim = 8000;
  final int _biayaLayanan = 2000;
  final int _diskonOngkir = 2000;
  String _metodeBayar = 'Tunai di Tempat (COD)';
  bool _sedangMemproses = false;

  int get _totalBayar =>
      widget.subtotal + _ongkosKirim + _biayaLayanan - _diskonOngkir;

  /// Memeriksa apakah toko sedang dalam jam operasional (08:00 - 22:00 WIB)
  bool _cekTokoBuka() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    return now.hour >= 8 && now.hour < 22;
  }

  Future<void> _buatPesanan() async {
    // Penegakan aturan bisnis khas Domain 1: Checkout ditolak di luar jam buka
    if (!_cekTokoBuka()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.store_mall_directory_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Toko Sedang Tutup'),
            ],
          ),
          content: const Text(
            'Mohon maaf, toko kami hanya melayani pesanan pada jam operasional 08.00 – 22.00 WIB. Silakan kembali lagi besok pagi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _sedangMemproses = true);

    try {
      // Simulasi delay POST /api/checkout dengan X-Kunci-Idempoten
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HalamanDetailPesanan(
            nomorPesanan: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
            items: widget.items,
            totalBayar: _totalBayar,
            metodeBayar: _metodeBayar,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: TemaWarna.merahHabis,
          content: Text(GalatApi.galatServer().pesan),
        ),
      );
    } finally {
      if (mounted) setState(() => _sedangMemproses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool tokoBuka = _cekTokoBuka();

    return Scaffold(
      backgroundColor: TemaWarna.latarKrem,
      appBar: AppBar(
        backgroundColor: TemaWarna.latarKrem,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Checkout',
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
          // 1. Kartu Jam Operasional Toko (Domain 1 Aturan Khas)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: tokoBuka ? TemaWarna.garisAbu : Colors.red.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 20, color: TemaWarna.cokelatUtama),
                        SizedBox(width: 8),
                        Text(
                          'Jam Operasional Toko',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TemaWarna.teksUtama,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: tokoBuka ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tokoBuka ? '● Buka Sekarang' : '● Tutup',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tokoBuka
                              ? TemaWarna.hijauBuka
                              : TemaWarna.merahHabis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '08.00 – 22.00 WIB',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: TemaWarna.cokelatUtama,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tokoBuka
                      ? 'Pesanan akan segera diracik dan diantar oleh kurir toko.'
                      : 'Pesanan di luar rentang jam operasional akan ditolak oleh sistem.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TemaWarna.teksSekunder,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. Alamat Pengiriman
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
                    const Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 20, color: TemaWarna.cokelatUtama),
                        SizedBox(width: 8),
                        Text(
                          'Alamat Pengiriman',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Ganti Alamat',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const Text(
                  'Budi Santoso • (+62 812-3456-7890)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Jl. Mawar No. 12, RT 04 / RW 02, Klojen, Kota Malang, Jawa Timur 65111',
                  style: TextStyle(fontSize: 12, color: TemaWarna.teksSekunder),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TemaWarna.latarKrem,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 14, color: TemaWarna.cokelatMuda),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Catatan: Pagar warna hitam, titip pos sekuriti bila kosong',
                          style: TextStyle(
                            fontSize: 11,
                            color: TemaWarna.cokelatTua,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Pilihan Kurir Internal Toko
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Kurir Pengantaran',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                _pilihanKurir(
                  tarif: 8000,
                  nama: 'Kurir Internal - Reguler',
                  estimasi: 'Estimasi 30–45 menit',
                  badge: 'Standar',
                  ikon: Icons.delivery_dining_rounded,
                ),
                const SizedBox(height: 8),
                _pilihanKurir(
                  tarif: 12000,
                  nama: 'Kurir Internal - Kilat',
                  estimasi: 'Estimasi 15–30 menit',
                  badge: 'Cepat',
                  ikon: Icons.bolt_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 4. Rincian Pembayaran
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rincian Pembayaran',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _barisRincian(
                  'Subtotal Produk',
                  TemaWarna.formatRupiah(widget.subtotal),
                ),
                _barisRincian(
                  'Biaya Pengiriman',
                  TemaWarna.formatRupiah(_ongkosKirim),
                ),
                _barisRincian(
                  'Biaya Layanan & Penanganan',
                  TemaWarna.formatRupiah(_biayaLayanan),
                ),
                _barisRincian(
                  'Diskon Promo Ongkir',
                  '-${TemaWarna.formatRupiah(_diskonOngkir)}',
                  warnaNilai: Colors.green,
                ),
                const Divider(height: 20),
                _barisRincian(
                  'Total Pembayaran',
                  TemaWarna.formatRupiah(_totalBayar),
                  tebal: true,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: TemaWarna.garisAbu)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL TAGIHAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: TemaWarna.teksSekunder,
                        ),
                      ),
                      Text(
                        TemaWarna.formatRupiah(_totalBayar),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: TemaWarna.teksUtama,
                        ),
                      ),
                    ],
                  ),
                  DropdownButton<String>(
                    value: _metodeBayar,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'Tunai di Tempat (COD)',
                        child: Text('Tunai di Tempat (COD)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      DropdownMenuItem(
                        value: 'Transfer Manual',
                        child: Text('Transfer Manual',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _metodeBayar = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TombolUtama(
                teks: 'Buat Pesanan',
                sedangMemuat: _sedangMemproses,
                onPressed: _buatPesanan,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pilihanKurir({
    required int tarif,
    required String nama,
    required String estimasi,
    required String badge,
    required IconData ikon,
  }) {
    final bool terpilih = _ongkosKirim == tarif;

    return InkWell(
      onTap: () => setState(() => _ongkosKirim = tarif),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: terpilih ? Colors.white : TemaWarna.abuMuda,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: terpilih ? TemaWarna.hitamTombol : TemaWarna.garisAbu,
            width: terpilih ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: terpilih ? TemaWarna.hitamTombol : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                ikon,
                size: 20,
                color: terpilih ? Colors.white : TemaWarna.cokelatUtama,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    estimasi,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TemaWarna.teksSekunder,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              TemaWarna.formatRupiah(tarif),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              terpilih
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: terpilih ? TemaWarna.hitamTombol : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _barisRincian(
    String label,
    String nilai, {
    bool tebal = false,
    Color? warnaNilai,
  }) {
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
              fontSize: 13,
              fontWeight: tebal ? FontWeight.w800 : FontWeight.w600,
              color: warnaNilai ??
                  (tebal ? TemaWarna.cokelatUtama : TemaWarna.teksUtama),
            ),
          ),
        ],
      ),
    );
  }
}
