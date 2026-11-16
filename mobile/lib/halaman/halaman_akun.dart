import 'package:flutter/material.dart';

import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../layanan/layanan_lokasi.dart';
import '../model/profil_pelanggan.dart';
import '../umum/tema_warna.dart';
import 'halaman_bantuan.dart';
import 'halaman_notifikasi.dart';
import 'halaman_promo.dart';

/// Tab Profil pelanggan, mengikuti rancangan `assets/images/profil.png`.
///
/// Menampilkan identitas, poin reward, voucher aktif, serta pintasan ke
/// alamat pengiriman, metode pembayaran, riwayat, promo, dan pusat bantuan.
class HalamanAkun extends StatefulWidget {
  final VoidCallback saatBukaRiwayat;

  const HalamanAkun({super.key, required this.saatBukaRiwayat});

  @override
  State<HalamanAkun> createState() => _HalamanAkunState();
}

class _HalamanAkunState extends State<HalamanAkun> {
  final LayananApi _api = LayananApi();

  ProfilPelanggan? _profil;
  String? _alamat;
  String? _galat;
  bool _memuat = true;

  @override
  void initState() {
    super.initState();
    _muatProfil();
  }

  Future<void> _muatProfil({bool tampilkanMemuat = true}) async {
    if (tampilkanMemuat) {
      setState(() {
        _memuat = true;
        _galat = null;
      });
    }

    try {
      final profil = await _api.ambilProfil();
      final pesanan = await _api.ambilDaftarPesanan();
      if (!mounted) return;

      final terakhir = pesanan.isEmpty ? null : pesanan.first;
      setState(() {
        _profil = profil;
        _alamat = LayananLokasi.alamatPengirimanPilihan ??
            terakhir?.alamatLengkap ??
            terakhir?.alamatPenerima;
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
        _galat = 'Profil tidak dapat dimuat. Coba lagi.';
        _memuat = false;
      });
    }
  }

  /// Dialog ubah nama, nomor WhatsApp, dan email lewat `PATCH /api/profil`.
  Future<void> _ubahProfil() async {
    final profil = _profil;
    if (profil == null) return;

    final namaController = TextEditingController(text: profil.nama);
    final phoneController = TextEditingController(text: profil.phone ?? '');
    final emailController = TextEditingController(text: profil.email ?? '');
    String? galat;
    var menyimpan = false;
    var dialogAktif = true;

    final hasil = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => PopScope<bool>(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) dialogAktif = false;
        },
        child: StatefulBuilder(
          builder: (context, ubahDialog) => AlertDialog(
            title: const Text('Ubah Profil'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: namaController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama lengkap',
                      hintText: 'Contoh: Budi Santoso',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor WhatsApp',
                      hintText: 'Contoh: 081234567890',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'nama@email.com',
                    ),
                  ),
                  if (galat != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        galat!,
                        style: const TextStyle(
                          color: TemaWarna.merahHabis,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: menyimpan
                    ? null
                    : () {
                        dialogAktif = false;
                        Navigator.of(dialogContext).pop(false);
                      },
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: menyimpan
                    ? null
                    : () async {
                        final nama = namaController.text.trim();
                        if (nama.length < 3) {
                          ubahDialog(
                            () => galat = 'Nama minimal 3 karakter.',
                          );
                          return;
                        }

                        ubahDialog(() {
                          menyimpan = true;
                          galat = null;
                        });

                        try {
                          final baru = await _api.ubahProfil(
                            nama: nama,
                            phone: phoneController.text,
                            email: emailController.text,
                          );
                          if (!mounted) return;
                          if (!dialogAktif || !dialogContext.mounted) return;
                          dialogAktif = false;
                          setState(() => _profil = baru);
                          Navigator.of(dialogContext).pop(true);
                        } on GalatApi catch (error) {
                          if (dialogAktif) {
                            ubahDialog(() {
                              menyimpan = false;
                              galat = error.pesan;
                            });
                          }
                        } catch (_) {
                          if (dialogAktif) {
                            ubahDialog(() {
                              menyimpan = false;
                              galat = 'Profil gagal disimpan. Coba lagi.';
                            });
                          }
                        }
                      },
                child: menyimpan
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );

    namaController.dispose();
    phoneController.dispose();
    emailController.dispose();

    if (hasil == true && mounted) {
      _tampilkanPesan('Profil berhasil diperbarui.');
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
            children: [
              for (final item in metode.where((item) => item.aktif))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 17,
                        color: TemaWarna.hijauBuka,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.nama)),
                    ],
                  ),
                ),
            ],
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

  Future<void> _bukaPromo() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const HalamanPromo()),
    );
    if (mounted) await _muatProfil(tampilkanMemuat: false);
  }

  Future<void> _bukaBantuan() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const HalamanBantuan()),
    );
    if (mounted) await _muatProfil(tampilkanMemuat: false);
  }

  Future<void> _bukaNotifikasi() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const HalamanNotifikasi()),
    );
    if (mounted) await _muatProfil(tampilkanMemuat: false);
  }

  Future<void> _keluar() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Aplikasi ini memakai akun demo dengan token statis. '
          'Keluar akan membersihkan alamat pengiriman yang tersimpan di perangkat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TemaWarna.merahHabis,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (yakin != true || !mounted) return;

    LayananLokasi.alamatPengirimanPilihan = null;
    setState(() => _alamat = null);
    _tampilkanPesan('Alamat lokal dibersihkan. Sesi demo tetap aktif.');
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Profil Saya',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: TemaWarna.cokelatPekat,
                      ),
                    ),
                  ),
                  _tombolLonceng(),
                ],
              ),
            ),
            Expanded(child: _bangunIsi()),
          ],
        ),
      ),
    );
  }

  Widget _tombolLonceng() {
    final jumlah = _profil?.notifikasiBelumDibaca ?? 0;

    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _bukaNotifikasi,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 26,
                color: TemaWarna.cokelatPekat,
              ),
              if (jumlah > 0)
                Positioned(
                  top: -2,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(
                      color: TemaWarna.merahHabis,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      jumlah > 9 ? '9+' : '$jumlah',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bangunIsi() {
    if (_memuat) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_galat != null || _profil == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _galat ?? 'Profil tidak tersedia.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: TemaWarna.cokelatPekat,
                ),
                onPressed: _muatProfil,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final profil = _profil!;

    return RefreshIndicator(
      color: TemaWarna.cokelatKaramel,
      onRefresh: () => _muatProfil(tampilkanMemuat: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _kartuIdentitas(profil),
          const SizedBox(height: 16),
          _kartuMenu(profil),
          const SizedBox(height: 18),
          _tombolKeluar(),
        ],
      ),
    );
  }

  Widget _kartuIdentitas(ProfilPelanggan profil) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TemaWarna.kremLembut, width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TemaWarna.kremLembut,
                  border: Border.all(
                    color: TemaWarna.cokelatKaramel,
                    width: 1.6,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 38,
                  color: TemaWarna.cokelatPekat,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profil.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: TemaWarna.cokelatPekat,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      profil.phone?.trim().isNotEmpty == true
                          ? '${profil.phone} • ${profil.email ?? ''}'
                          : (profil.email ?? 'Nomor WhatsApp belum diisi'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: TemaWarna.teksSekunder,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: _ubahProfil,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: TemaWarna.garisAbu),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 17,
                    color: TemaWarna.cokelatPekat,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF8F3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TemaWarna.kremLembut),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: TemaWarna.cokelatPekat,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.confirmation_number_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Voucher Saya',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: TemaWarna.teksSekunder,
                              ),
                            ),
                            Text(
                              '${profil.voucherAktif} Voucher',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: TemaWarna.cokelatPekat,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: TemaWarna.kremLembut,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: TemaWarna.kremLembut,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 21,
                          color: TemaWarna.cokelatKaramel,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Poin Reward',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: TemaWarna.teksSekunder,
                              ),
                            ),
                            Text(
                              '${_formatAngka(profil.poin)} Pts',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: TemaWarna.cokelatPekat,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: TemaWarna.cokelatPekat,
                side: const BorderSide(color: TemaWarna.cokelatKaramel),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _bukaPromo,
              child: const Text(
                'Tukar Poin & Lihat Promo',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuMenu(ProfilPelanggan profil) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TemaWarna.kremLembut, width: 1.2),
      ),
      child: Column(
        children: [
          _barisMenu(
            ikon: Icons.location_on_outlined,
            judul: 'Alamat Pengiriman',
            keterangan: _alamat?.trim().isNotEmpty == true
                ? _alamat!
                : 'Belum ada alamat tersimpan',
            saatDitekan: _pilihAlamat,
          ),
          _garis(),
          _barisMenu(
            ikon: Icons.credit_card_rounded,
            judul: 'Metode Pembayaran',
            keterangan: 'QRIS, GoPay, DANA, OVO, Transfer Bank',
            saatDitekan: _tampilkanMetodePembayaran,
          ),
          _garis(),
          _barisMenu(
            ikon: Icons.receipt_long_outlined,
            judul: 'Riwayat Pesanan',
            keterangan: 'Daftar transaksi dan tagihan',
            saatDitekan: widget.saatBukaRiwayat,
          ),
          _garis(),
          _barisMenu(
            ikon: Icons.confirmation_number_outlined,
            judul: 'Voucher & Promo',
            keterangan: profil.voucherAktif > 0
                ? '${profil.voucherAktif} voucher siap dipakai'
                : 'Klaim kode atau tukar poin',
            lencana: profil.voucherAktif > 0 ? '${profil.voucherAktif}' : null,
            saatDitekan: _bukaPromo,
          ),
          _garis(),
          _barisMenu(
            ikon: Icons.support_agent_rounded,
            judul: 'Pusat Bantuan',
            keterangan: profil.pesanBelumDibaca > 0
                ? '${profil.pesanBelumDibaca} balasan CS belum dibaca'
                : 'Hubungi CS',
            lencana: profil.pesanBelumDibaca > 0
                ? '${profil.pesanBelumDibaca}'
                : null,
            saatDitekan: _bukaBantuan,
          ),
        ],
      ),
    );
  }

  Widget _garis() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: 16,
      color: Color(0xFFF6EEE5),
    );
  }

  Widget _barisMenu({
    required IconData ikon,
    required String judul,
    required String keterangan,
    required VoidCallback saatDitekan,
    String? lencana,
  }) {
    return InkWell(
      onTap: saatDitekan,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TemaWarna.kremLembut,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(ikon, size: 21, color: TemaWarna.cokelatPekat),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TemaWarna.cokelatPekat,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    keterangan,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: TemaWarna.teksSekunder,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (lencana != null)
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: TemaWarna.cokelatPekat,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  lencana,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: TemaWarna.teksSekunder,
              ),
          ],
        ),
      ),
    );
  }

  Widget _tombolKeluar() {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFFF5F5),
          foregroundColor: TemaWarna.merahHabis,
          side: const BorderSide(color: Color(0xFFF3B6B6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _keluar,
        icon: const Icon(Icons.logout_rounded, size: 19),
        label: const Text(
          'Keluar dari Akun',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
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
