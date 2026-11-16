import 'package:flutter/material.dart';

import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../model/katalog_promo.dart';
import '../model/promo.dart';
import '../model/voucher_pelanggan.dart';
import '../umum/format_rupiah.dart';
import '../umum/tema_warna.dart';
import '../widget/tampilan_galat.dart';
import '../widget/tampilan_muat.dart';

/// Halaman Promo & Tukar Poin.
///
/// * `GET /api/promos` — katalog promo, voucher milik pelanggan, saldo poin.
/// * `POST /api/promos/redeem-code` — klaim kode promo.
/// * `POST /api/promos/redeem-point` — tukar poin menjadi voucher.
///
/// Voucher hasil klaim otomatis tersedia pada pemilih voucher di checkout.
class HalamanPromo extends StatefulWidget {
  const HalamanPromo({super.key});

  @override
  State<HalamanPromo> createState() => _HalamanPromoState();
}

class _HalamanPromoState extends State<HalamanPromo> {
  final LayananApi _api = LayananApi();
  final TextEditingController _kodeController = TextEditingController();

  KatalogPromo? _katalog;
  String? _galat;
  bool _memuat = true;
  bool _sedangKlaim = false;
  int? _sedangTukarId;

  @override
  void initState() {
    super.initState();
    _muatKatalog();
  }

  @override
  void dispose() {
    _kodeController.dispose();
    super.dispose();
  }

  Future<void> _muatKatalog({bool tampilkanMemuat = true}) async {
    if (tampilkanMemuat) {
      setState(() {
        _memuat = true;
        _galat = null;
      });
    }

    try {
      final katalog = await _api.ambilKatalogPromo();
      if (!mounted) return;
      setState(() {
        _katalog = katalog;
        _memuat = false;
        _galat = null;
      });
    } on GalatApi catch (galat) {
      if (!mounted) return;
      setState(() {
        _galat = galat.pesan;
        _memuat = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _galat = 'Promo tidak dapat dimuat. Coba lagi.';
        _memuat = false;
      });
    }
  }

  Future<void> _klaimKode() async {
    if (_sedangKlaim) return;

    final kode = _kodeController.text.trim();
    if (kode.isEmpty) {
      _tampilkanPesan('Masukkan kode promo terlebih dahulu.');
      return;
    }

    setState(() => _sedangKlaim = true);

    try {
      final hasil = await _api.klaimKodePromo(kode);
      if (!mounted) return;
      _kodeController.clear();
      _tampilkanPesan(
        'Voucher ${hasil.voucher.promo?.kode ?? kode} berhasil diklaim.',
      );
      await _muatKatalog(tampilkanMemuat: false);
    } on GalatApi catch (galat) {
      if (!mounted) return;
      _tampilkanPesan(galat.pesan);
    } catch (_) {
      if (!mounted) return;
      _tampilkanPesan('Kode promo gagal diklaim. Coba lagi.');
    } finally {
      if (mounted) setState(() => _sedangKlaim = false);
    }
  }

  Future<void> _tukarPoin(Promo promo) async {
    if (_sedangTukarId != null) return;

    setState(() => _sedangTukarId = promo.id);

    try {
      final hasil = await _api.tukarPoinPromo(promo.id);
      if (!mounted) return;
      _tampilkanPesan(
        '${promo.judul} berhasil ditukar. Sisa poin: '
        '${_formatAngka(hasil.poin)}.',
      );
      await _muatKatalog(tampilkanMemuat: false);
    } on GalatApi catch (galat) {
      if (!mounted) return;
      _tampilkanPesan(galat.pesan);
    } catch (_) {
      if (!mounted) return;
      _tampilkanPesan('Poin gagal ditukar. Coba lagi.');
    } finally {
      if (mounted) setState(() => _sedangTukarId = null);
    }
  }

  void _tampilkanPesan(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: TemaWarna.cokelatPekat,
          content: Text(pesan),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Promo & Tukar Poin',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _bangunIsi(),
    );
  }

  Widget _bangunIsi() {
    if (_memuat) {
      return const TampilanMuat(pesan: 'Memuat promo...');
    }

    if (_galat != null) {
      return TampilanGalat(
        pesanKustom: _galat,
        saatCobaLagi: _muatKatalog,
      );
    }

    final katalog = _katalog ?? const KatalogPromo();
    final promoPoin =
        katalog.promos.where((promo) => promo.bisaDitukarPoin).toList();
    final promoKode =
        katalog.promos.where((promo) => promo.bisaDiklaimKode).toList();

    return RefreshIndicator(
      color: TemaWarna.cokelatKaramel,
      onRefresh: () => _muatKatalog(tampilkanMemuat: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _kartuPoin(katalog.poin),
          const SizedBox(height: 14),
          _kartuKlaimKode(),
          const SizedBox(height: 20),
          _judulSeksi('Voucher Saya', '${katalog.voucherAktif.length} aktif'),
          const SizedBox(height: 10),
          if (katalog.vouchers.isEmpty)
            _kotakKosong('Belum ada voucher. Klaim kode atau tukar poin dulu.')
          else
            for (final voucher in katalog.vouchers) ...[
              _kartuVoucher(voucher),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 12),
          _judulSeksi('Tukar Poin', '${_formatAngka(katalog.poin)} poin'),
          const SizedBox(height: 10),
          if (promoPoin.isEmpty)
            _kotakKosong('Belum ada promo yang bisa ditukar dengan poin.')
          else
            for (final promo in promoPoin) ...[
              _kartuPromo(
                promo,
                sudahDimiliki: katalog.sudahDimiliki(promo.id),
                poinTidakCukup: katalog.poin < promo.biayaPoin,
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 12),
          _judulSeksi('Klaim dengan Kode', '${promoKode.length} promo'),
          const SizedBox(height: 10),
          if (promoKode.isEmpty)
            _kotakKosong('Belum ada promo kode yang aktif.')
          else
            for (final promo in promoKode) ...[
              _kartuPromo(
                promo,
                sudahDimiliki: katalog.sudahDimiliki(promo.id),
                poinTidakCukup: false,
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _kartuPoin(int poin) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TemaWarna.kremLembut,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              color: TemaWarna.cokelatKaramel,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Poin Reward',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: TemaWarna.teksSekunder,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatAngka(poin)} Poin',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: TemaWarna.cokelatPekat,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Dapat 100 poin setiap transaksi Rp 10.000',
                  style: TextStyle(fontSize: 11, color: TemaWarna.teksSekunder),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuKlaimKode() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TemaWarna.garisAbu),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Punya kode promo?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _kodeController,
                  enabled: !_sedangKlaim,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _klaimKode(),
                  decoration: InputDecoration(
                    hintText: 'Contoh: MAKAN20',
                    isDense: true,
                    filled: true,
                    fillColor: TemaWarna.abuMuda,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: TemaWarna.garisAbu),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: TemaWarna.garisAbu),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: TemaWarna.cokelatKaramel,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: TemaWarna.cokelatPekat,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _sedangKlaim ? null : _klaimKode,
                  child: _sedangKlaim
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Klaim'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _judulSeksi(String judul, String keterangan) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          judul,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        Text(
          keterangan,
          style: const TextStyle(
            fontSize: 12,
            color: TemaWarna.teksSekunder,
          ),
        ),
      ],
    );
  }

  Widget _kotakKosong(String pesan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaWarna.abuMuda,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        pesan,
        style: const TextStyle(fontSize: 12.5, color: TemaWarna.teksSekunder),
      ),
    );
  }

  Widget _kartuPromo(
    Promo promo, {
    required bool sudahDimiliki,
    required bool poinTidakCukup,
  }) {
    final bool sedangMenukar = _sedangTukarId == promo.id;
    final bool tombolMati = sudahDimiliki || poinTidakCukup || sedangMenukar;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TemaWarna.garisAbu),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: TemaWarna.kremLembut,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  color: TemaWarna.cokelatKaramel,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promo.judul,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      promo.deskripsi?.trim().isNotEmpty == true
                          ? promo.deskripsi!
                          : 'Voucher MakanYuk!',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: TemaWarna.teksSekunder,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(promo.kode, tebal: true),
              _chip(promo.labelDiskon.isNotEmpty
                  ? promo.labelDiskon
                  : promo.labelTipe),
              if (promo.minimalBelanja > 0)
                _chip('Min. ${formatRupiah(promo.minimalBelanja)}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  sudahDimiliki
                      ? 'Voucher sudah ada di akunmu'
                      : promo.bisaDitukarPoin
                          ? '${_formatAngka(promo.biayaPoin)} poin'
                          : 'Gratis dengan kode',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sudahDimiliki
                        ? TemaWarna.hijauBuka
                        : TemaWarna.teksSekunder,
                  ),
                ),
              ),
              SizedBox(
                height: 38,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: TemaWarna.cokelatKaramel,
                    disabledBackgroundColor: TemaWarna.garisAbu,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: TemaWarna.teksSekunder,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: tombolMati ? null : () => _tukarPoin(promo),
                  child: sedangMenukar
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          sudahDimiliki
                              ? 'Dimiliki'
                              : poinTidakCukup
                                  ? 'Poin kurang'
                                  : 'Tukar',
                          style: const TextStyle(fontSize: 12),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kartuVoucher(VoucherPelanggan voucher) {
    final promo = voucher.promo;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: voucher.aktif ? TemaWarna.kremLembut : TemaWarna.abuMuda,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: voucher.aktif ? TemaWarna.cokelatKaramel : TemaWarna.garisAbu,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            voucher.aktif
                ? Icons.confirmation_number_rounded
                : Icons.check_circle_outline_rounded,
            color: voucher.aktif
                ? TemaWarna.cokelatPekat
                : TemaWarna.teksSekunder,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo?.judul ?? 'Voucher MakanYuk!',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${promo?.kode ?? '-'} • ${voucher.labelStatus}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: TemaWarna.teksSekunder,
                  ),
                ),
              ],
            ),
          ),
          Text(
            promo?.labelDiskon ?? '',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: TemaWarna.cokelatPekat,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String teks, {bool tebal = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: TemaWarna.garisAbu),
      ),
      child: Text(
        teks,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: tebal ? FontWeight.w800 : FontWeight.w500,
          letterSpacing: tebal ? 0.5 : 0,
          color: TemaWarna.cokelatPekat,
        ),
      ),
    );
  }
}

String _formatAngka(int nilai) {
  final teks = nilai.abs().toString();
  final hasil = StringBuffer();

  for (var i = 0; i < teks.length; i++) {
    if (i > 0 && (teks.length - i) % 3 == 0) {
      hasil.write('.');
    }
    hasil.write(teks[i]);
  }

  return hasil.toString();
}
