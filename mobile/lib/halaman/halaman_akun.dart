import 'package:flutter/material.dart';

import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../layanan/layanan_lokasi.dart';
import '../umum/tema_warna.dart';

class HalamanAkun extends StatefulWidget {
  final VoidCallback saatBukaRiwayat;

  const HalamanAkun({super.key, required this.saatBukaRiwayat});

  @override
  State<HalamanAkun> createState() => _HalamanAkunState();
}

class _HalamanAkunState extends State<HalamanAkun> {
  final LayananApi _api = LayananApi();
  String _nama = 'Pelanggan Uji 1';
  String? _alamat;
  String? _galat;
  bool _memuat = true;

  @override
  void initState() {
    super.initState();
    _muatRingkasan();
  }

  Future<void> _muatRingkasan() async {
    setState(() {
      _memuat = true;
      _galat = null;
    });

    try {
      final pesanan = await _api.ambilDaftarPesanan();
      if (!mounted) return;
      final pesananTerakhir = pesanan.isEmpty ? null : pesanan.first;
      setState(() {
        _alamat = LayananLokasi.alamatPengirimanPilihan;
        if (pesananTerakhir != null) {
          _nama = pesananTerakhir.namaPenerima;
          _alamat ??= pesananTerakhir.alamatPenerima;
        }
        _memuat = false;
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
        _galat = 'Ringkasan akun tidak dapat dimuat. Coba lagi.';
        _memuat = false;
      });
    }
  }

  Future<void> _pilihAlamat() async {
    final controller = TextEditingController(
      text: LayananLokasi.alamatPengirimanPilihan ?? _alamat ?? '',
    );
    String? galat;
    var mengambilLokasi = false;
    var dialogMasihAktif = true;
    final hasil = await showDialog<String>(
      context: context,
      builder: (dialogContext) => PopScope<String>(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) dialogMasihAktif = false;
        },
        child: StatefulBuilder(
          builder: (context, ubahDialog) => AlertDialog(
            title: const Text('Alamat untuk checkout'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Alamat pengiriman',
                    hintText: 'Lengkapi jalan, nomor rumah, dan patokan',
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: mengambilLokasi
                        ? null
                        : () async {
                            ubahDialog(() {
                              mengambilLokasi = true;
                              galat = null;
                            });
                            try {
                              final alamat = await const LayananLokasi()
                                  .ambilKoordinatSaatIni();
                              if (!dialogMasihAktif) return;
                              controller.text = alamat;
                            } on LayananLokasiException catch (error) {
                              if (dialogMasihAktif) {
                                ubahDialog(() => galat = error.pesan);
                              }
                            } catch (_) {
                              if (dialogMasihAktif) {
                                ubahDialog(() {
                                  galat =
                                      'Lokasi tidak dapat diambil. Coba lagi.';
                                });
                              }
                            } finally {
                              if (dialogMasihAktif) {
                                ubahDialog(() => mengambilLokasi = false);
                              }
                            }
                          },
                    icon: mengambilLokasi
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded),
                    label: Text(
                      mengambilLokasi ? 'Mengambil lokasi...' : 'Ambil lokasi',
                    ),
                  ),
                ),
                const Text(
                  'Koordinat perangkat bukan alamat lengkap. Lengkapi detail pengiriman sebelum checkout.',
                  style: TextStyle(color: TemaWarna.teksSekunder, fontSize: 12),
                ),
                if (galat != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      galat!,
                      style: const TextStyle(color: TemaWarna.merahHabis),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  dialogMasihAktif = false;
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  if (controller.text.trim().isEmpty) {
                    ubahDialog(() => galat = 'Alamat pengiriman wajib diisi.');
                    return;
                  }
                  dialogMasihAktif = false;
                  Navigator.of(dialogContext).pop(controller.text.trim());
                },
                child: const Text('Gunakan alamat'),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();

    if (hasil != null && mounted) {
      setState(() {
        _alamat = hasil;
        LayananLokasi.alamatPengirimanPilihan = hasil;
      });
    }
  }

  Future<void> _tampilkanMetodePembayaran() async {
    try {
      final metode = await _api.ambilMetodePembayaran();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Metode pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: metode
                .where((item) => item.aktif)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(item.nama),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } on GalatApi catch (galat) {
      _tampilkanPesan(galat.pesan);
    } catch (_) {
      _tampilkanPesan('Metode pembayaran tidak dapat dimuat.');
    }
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
      backgroundColor: TemaWarna.latarKrem,
      appBar: AppBar(
        title: const Text(
          'Akun Saya',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _muatRingkasan,
            tooltip: 'Muat ulang akun',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _memuat
          ? const Center(child: CircularProgressIndicator())
          : _galat != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_galat!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _muatRingkasan,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            )
          : _bangunProfil(),
    );
  }

  Widget _bangunProfil() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: TemaWarna.kremTua,
                child: Icon(
                  Icons.person,
                  size: 36,
                  color: TemaWarna.cokelatUtama,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nama,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _alamat?.isNotEmpty == true
                          ? _alamat!
                          : 'Alamat pengiriman belum tersedia',
                      style: const TextStyle(
                        fontSize: 12,
                        color: TemaWarna.teksSekunder,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.white,
          child: Column(
            children: [
              _menu(
                ikon: Icons.location_on_outlined,
                judul: 'Alamat pengiriman',
                keterangan: 'Pilih alamat atau gunakan lokasi perangkat',
                saatDitekan: _pilihAlamat,
              ),
              const Divider(height: 1, indent: 64),
              _menu(
                ikon: Icons.payment_outlined,
                judul: 'Metode pembayaran',
                keterangan: 'Lihat metode pembayaran yang tersedia',
                saatDitekan: _tampilkanMetodePembayaran,
              ),
              const Divider(height: 1, indent: 64),
              _menu(
                ikon: Icons.receipt_long_outlined,
                judul: 'Riwayat pesanan',
                keterangan: 'Daftar transaksi dan tagihan',
                saatDitekan: widget.saatBukaRiwayat,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Akun menggunakan pelanggan demo yang ditentukan oleh token sesi.',
          textAlign: TextAlign.center,
          style: TextStyle(color: TemaWarna.teksSekunder, fontSize: 12),
        ),
      ],
    );
  }

  Widget _menu({
    required IconData ikon,
    required String judul,
    required String keterangan,
    required VoidCallback saatDitekan,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: TemaWarna.kremTua,
        child: Icon(ikon, color: TemaWarna.cokelatUtama),
      ),
      title: Text(judul, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(keterangan),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: saatDitekan,
    );
  }
}
