import 'dart:async';

import 'package:flutter/material.dart';

import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../model/pesan_dukungan.dart';
import '../umum/tema_warna.dart';
import '../widget/tampilan_galat.dart';
import '../widget/tampilan_muat.dart';

/// Pusat Bantuan: percakapan dua arah dengan CS MakanYuk!.
///
/// * `GET /api/support/messages` setiap 5 detik (polling).
/// * `POST /api/support/messages` untuk mengirim pesan.
/// * Balasan admin otomatis membuat notifikasi lonceng di aplikasi.
class HalamanBantuan extends StatefulWidget {
  const HalamanBantuan({super.key});

  @override
  State<HalamanBantuan> createState() => _HalamanBantuanState();
}

class _HalamanBantuanState extends State<HalamanBantuan> {
  static const List<String> _templatCepat = [
    'Pesanan saya belum sampai',
    'Bagaimana cara memakai voucher?',
    'Saya ingin mengubah alamat pengiriman',
  ];

  final LayananApi _api = LayananApi();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  Timer? _polling;
  List<PesanDukungan> _pesan = [];
  String? _galat;
  bool _memuat = true;
  bool _mengirim = false;
  int _jumlahTerakhir = 0;

  @override
  void initState() {
    super.initState();
    _muatPesan();
    _polling = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _muatPesan(tampilkanMemuat: false),
    );
  }

  @override
  void dispose() {
    _polling?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _muatPesan({bool tampilkanMemuat = true}) async {
    if (tampilkanMemuat && mounted) {
      setState(() {
        _memuat = true;
        _galat = null;
      });
    }

    try {
      final pesan = await _api.ambilPesanDukungan();
      if (!mounted) return;
      final bertambah = pesan.length != _jumlahTerakhir;
      setState(() {
        _pesan = pesan;
        _jumlahTerakhir = pesan.length;
        _memuat = false;
        _galat = null;
      });
      if (bertambah && tampilkanMemuat) {
        _gulirKeBawah();
      }
    } on GalatApi catch (galat) {
      if (!mounted || !tampilkanMemuat) return;
      setState(() {
        _galat = galat.pesan;
        _memuat = false;
      });
    } catch (_) {
      if (!mounted || !tampilkanMemuat) return;
      setState(() {
        _galat = 'Pesan bantuan tidak dapat dimuat. Coba lagi.';
        _memuat = false;
      });
    }
  }

  Future<void> _kirim() async {
    if (_mengirim) return;

    final teks = _controller.text.trim();
    if (teks.isEmpty) return;

    setState(() => _mengirim = true);

    try {
      final pesan = await _api.kirimPesanDukungan(teks);
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _pesan = [..._pesan, pesan];
        _jumlahTerakhir = _pesan.length;
      });
      _gulirKeBawah();
    } on GalatApi catch (galat) {
      _tampilkanPesan(galat.pesan);
    } catch (_) {
      _tampilkanPesan('Pesan gagal dikirim. Coba lagi.');
    } finally {
      if (mounted) setState(() => _mengirim = false);
    }
  }

  void _gulirKeBawah() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _tampilkanPesan(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pusat Bantuan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'CS MakanYuk! • Online',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: TemaWarna.hijauBuka,
              ),
            ),
          ],
        ),
      ),
      body: _bangunIsi(),
    );
  }

  Widget _bangunIsi() {
    if (_memuat) {
      return const TampilanMuat(pesan: 'Menyiapkan ruang chat...');
    }

    if (_galat != null) {
      return TampilanGalat(
        pesanKustom: _galat,
        saatCobaLagi: _muatPesan,
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TemaWarna.kremLembut,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: TemaWarna.cokelatKaramel,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tim CS membalas pada jam operasional. Balasan masuk ke lonceng notifikasi.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: TemaWarna.cokelatPekat,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _pesan.isEmpty
              ? _bangunKosong()
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _pesan.length,
                  itemBuilder: (context, index) =>
                      _gelembung(_pesan[index]),
                ),
        ),
        if (_pesan.isEmpty) _bilahTemplatCepat(),
        _bangunInput(),
      ],
    );
  }

  Widget _bangunKosong() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
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
                Icons.support_agent_rounded,
                size: 44,
                color: TemaWarna.cokelatKaramel,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ada yang bisa kami bantu?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tulis pesanmu di bawah. Tim CS MakanYuk! akan segera membalas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: TemaWarna.teksSekunder),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bilahTemplatCepat() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _templatCepat.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final teks = _templatCepat[index];
          return ActionChip(
            backgroundColor: Colors.white,
            side: const BorderSide(color: TemaWarna.garisAbu),
            label: Text(
              teks,
              style: const TextStyle(
                fontSize: 11.5,
                color: TemaWarna.cokelatPekat,
              ),
            ),
            onPressed: () {
              _controller.text = teks;
              setState(() {});
            },
          );
        },
      ),
    );
  }

  Widget _gelembung(PesanDukungan pesan) {
    final bool dariAdmin = pesan.dariAdmin;
    final bool gelap = !dariAdmin;

    return Align(
      alignment: dariAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: gelap ? TemaWarna.cokelatPekat : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(dariAdmin ? 4 : 16),
            bottomRight: Radius.circular(dariAdmin ? 16 : 4),
          ),
          border: dariAdmin
              ? Border.all(color: TemaWarna.garisAbu)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dariAdmin)
              const Text(
                'CS MakanYuk!',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: TemaWarna.cokelatKaramel,
                ),
              ),
            Text(
              pesan.pesan,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: gelap ? Colors.white : TemaWarna.teksUtama,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              pesan.waktu,
              style: TextStyle(
                fontSize: 9.5,
                color: gelap ? Colors.white70 : TemaWarna.teksSekunder,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bangunInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: TemaWarna.garisAbu)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_mengirim,
                minLines: 1,
                maxLines: 4,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Tulis pesan untuk CS...',
                  counterText: '',
                  isDense: true,
                  filled: true,
                  fillColor: TemaWarna.abuMuda,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _kirim(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              height: 44,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: TemaWarna.cokelatPekat,
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                ),
                onPressed: _mengirim ? null : _kirim,
                child: _mengirim
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 19),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
