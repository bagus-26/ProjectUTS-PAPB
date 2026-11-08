import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../layanan/layanan_lokasi.dart';
import '../model/isi_keranjang.dart';
import '../model/kurir.dart';
import '../model/metode_pembayaran.dart';
import '../model/pesanan.dart';
import '../model/ringkasan_keranjang.dart';
import '../umum/keadaan_muat.dart';
import '../umum/tema_warna.dart';
import '../umum/format_rupiah.dart';
import '../widget/tampilan_galat.dart';
import '../widget/tampilan_kosong.dart';
import '../widget/tampilan_muat.dart';
import '../widget/tombol_utama.dart';
import 'halaman_detail_pesanan.dart';

/// Halaman Checkout (Kelompok 1: MakanYuk!)
///
/// Mengikuti PRD 7.1 & A5-03:
/// * `GET /kurir`, `GET /metode-pembayaran`, `GET /keranjang?kurir_id=`
///   (subtotal, ongkir, dan total **dihitung server** — D-06),
/// * `POST /checkout` dengan header `X-Kunci-Idempoten` (PRD 7.4),
/// * 422 tampil per kolom di bawah formulir, 409 tampil inline,
/// * aturan jam buka **hanya** diputuskan server (409 `toko_tutup`),
///   tidak pernah diblokir dari Flutter (K1),
/// * 201 → `pushReplacement` ke Rincian Pesanan.
class HalamanCheckout extends StatefulWidget {
  const HalamanCheckout({super.key});

  @override
  State<HalamanCheckout> createState() => _HalamanCheckoutState();
}

class _HalamanCheckoutState extends State<HalamanCheckout> {
  final LayananApi _layanan = LayananApi();
  final GlobalKey<FormState> _kunciForm = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  /// Kunci idempoten dibuat **sekali per kunjungan** halaman (PRD 7.4).
  /// Tombol coba lagi setelah galat sambungan/timeout memakai kunci yang sama,
  /// sehingga retry tidak pernah membuat pesanan ganda.
  final String _kunciIdempoten = const Uuid().v4();

  // Empat keadaan layar eksplisit (PRD 7.2)
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  GalatApi? _galat;

  List<Kurir> _daftarKurir = [];
  List<MetodePembayaran> _daftarMetode = [];

  /// Isi keranjang + `ringkasan` (subtotal, ongkir, total) dari server.
  IsiKeranjang? _keranjang;

  int? _kurirTerpilihId;
  String? _metodeTerpilih;

  bool _sedangKirim = false;
  bool _sedangAmbilLokasi = false;
  bool _sedangSegarkanRingkasan = false;

  /// Pesan galat 422 per kolom (PRD 7.3) untuk ditampilkan di bawah input.
  Map<String, String> _galatPerKolom = {};

  @override
  void initState() {
    super.initState();
    _muatDataAwal();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  /// Memuat `GET /kurir`, `GET /metode-pembayaran`, lalu
  /// `GET /keranjang?kurir_id=` untuk ringkasan dari server.
  Future<void> _muatDataAwal() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _galat = null;
      _galatPerKolom = {};
    });

    try {
      final kurir = await _layanan.ambilKurir();
      final metode = await _layanan.ambilMetodePembayaran();
      final riwayat = await _layanan.ambilDaftarPesanan();
      if (!mounted) return;

      setState(() {
        if (riwayat.isNotEmpty) {
          final pesananTerakhir = riwayat.first;
          if (_namaController.text.isEmpty) {
            _namaController.text = pesananTerakhir.namaPenerima;
          }
          if (_alamatController.text.isEmpty) {
            _alamatController.text =
                LayananLokasi.alamatPengirimanPilihan ??
                pesananTerakhir.alamatPenerima;
          }
        } else if (_alamatController.text.isEmpty) {
          _alamatController.text =
              LayananLokasi.alamatPengirimanPilihan ?? '';
        }
        _daftarKurir = kurir.where((item) => item.aktif).toList();
        _daftarMetode = metode.where((item) => item.aktif).toList();
        if (_kurirTerpilihId == null && _daftarKurir.isNotEmpty) {
          _kurirTerpilihId = _daftarKurir.first.id;
        }
        if (_metodeTerpilih == null && _daftarMetode.isNotEmpty) {
          _metodeTerpilih = _daftarMetode.first.kode;
        }
      });

      final isi = await _layanan.ambilKeranjang(kurirId: _kurirTerpilihId);
      if (!mounted) return;

      setState(() {
        _keranjang = isi;
        _keadaan = isi.kosong ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
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

  /// `GET /keranjang?kurir_id=` ulang setelah kurir diganti, sehingga
  /// ongkos_kirim dan total **berubah mengikuti server** (D-06).
  Future<void> _segarkanRingkasan() async {
    if (_kurirTerpilihId == null || _sedangSegarkanRingkasan) return;

    setState(() => _sedangSegarkanRingkasan = true);
    try {
      final isi = await _layanan.ambilKeranjang(kurirId: _kurirTerpilihId);
      if (!mounted) return;
      setState(() => _keranjang = isi);
    } on GalatApi catch (g) {
      _tampilkanGalat(g);
    } catch (_) {
      _tampilkanGalat(GalatApi.umum());
    } finally {
      if (mounted) setState(() => _sedangSegarkanRingkasan = false);
    }
  }

  void _pilihKurir(Kurir kurir) {
    if (_kurirTerpilihId == kurir.id) return;
    setState(() => _kurirTerpilihId = kurir.id);
    _segarkanRingkasan();
  }

  Future<void> _ambilLokasi() async {
    if (_sedangAmbilLokasi) return;
    setState(() => _sedangAmbilLokasi = true);

    try {
      final alamat = await const LayananLokasi().ambilKoordinatSaatIni();
      if (!mounted) return;
      setState(() {
        _alamatController.text = alamat;
        LayananLokasi.alamatPengirimanPilihan = alamat;
      });
      _bersihkanGalatKolom();
    } on LayananLokasiException catch (galat) {
      _tampilkanGalat(GalatApi.umum(galat.pesan));
    } catch (_) {
      _tampilkanGalat(GalatApi.umum('Lokasi tidak dapat diambil. Coba lagi.'));
    } finally {
      if (mounted) setState(() => _sedangAmbilLokasi = false);
    }
  }

  /// `POST /api/checkout` + `X-Kunci-Idempoten` (PRD 7.4).
  Future<void> _buatPesanan() async {
    if (_sedangKirim) return;

    if (!(_kunciForm.currentState?.validate() ?? false)) return;

    if (_kurirTerpilihId == null || _metodeTerpilih == null) {
      _tampilkanGalat(GalatApi.umum('Pilih kurir dan metode pembayaran dulu.'));
      return;
    }

    // Flag diset SEBELUM await agar satu ketukan tidak menjadi dua pesanan.
    setState(() {
      _sedangKirim = true;
      _galatPerKolom = {};
    });

    try {
      final Pesanan pesanan = await _layanan.buatCheckout(
        namaPenerima: _namaController.text.trim(),
        alamatPenerima: _alamatController.text.trim(),
        kurirId: _kurirTerpilihId!,
        metodePembayaran: _metodeTerpilih!,
        kunciIdempoten: _kunciIdempoten,
      );

      if (!mounted) return;
      LayananLokasi.alamatPengirimanPilihan =
          _alamatController.text.trim();

      // 201 → Rincian Pesanan dengan tumpukan dibersihkan (PRD 7.1)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HalamanDetailPesanan(
            pesananId: pesanan.id,
          ),
        ),
      );
    } on GalatApi catch (g) {
      if (!mounted) return;
      _tanganiGalatKirim(g);
    } catch (_) {
      _tampilkanGalat(GalatApi.umum());
    } finally {
      if (mounted) setState(() => _sedangKirim = false);
    }
  }

  /// Memetakan galat `POST /checkout` ke tampilan yang sesuai (PRD 7.3):
  /// 422 → pesan per kolom di bawah input; 409 → pesan server inline.
  void _tanganiGalatKirim(GalatApi g) {
    if (g.jenis == JenisGalat.validasi && g.errors != null) {
      setState(() {
        _galatPerKolom = g.errors!.map(
          (kolom, pesan) => MapEntry(kolom, pesan.join('\n')),
        );
      });
    }
    _tampilkanGalat(g);
  }

  /// Pesan galat untuk ditampilkan inline (422 memakai pesan per kolom).
  String _pesanGalat(GalatApi g) {
    if (g.jenis == JenisGalat.validasi &&
        g.errors != null &&
        g.errors!.isNotEmpty) {
      final rincian = g.errors!.values.expand((baris) => baris).join('\n');
      if (rincian.isNotEmpty) return rincian;
    }

    // 409 toko_tutup: tampilkan jam operasional dari data server
    if (g.jenis == JenisGalat.bentrok && g.data?['alasan'] == 'toko_tutup') {
      final buka = g.data?['jam_buka']?.toString() ?? '08:00';
      final tutup = g.data?['jam_tutup']?.toString() ?? '22:00';
      return 'Toko sedang tutup. Pesanan hanya diproses pukul $buka – $tutup WIB.';
    }

    return g.pesan;
  }

  void _tampilkanGalat(GalatApi g) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: TemaWarna.merahHabis,
          duration: const Duration(seconds: 4),
          content: Text(_pesanGalat(g)),
        ),
      );
  }

  void _kembaliKeKatalog() {
    // Keranjang kosong → kembali ke katalog dengan tumpukan dibersihkan
    Navigator.of(context).popUntil((route) => route.isFirst);
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
          'Checkout',
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
        return const TampilanMuat(pesan: 'Menyiapkan halaman checkout...');

      case KeadaanMuat.galat:
        return TampilanGalat(
          galat: _galat,
          saatCobaLagi: _muatDataAwal,
        );

      case KeadaanMuat.kosong:
        return TampilanKosong(
          ikon: Icons.shopping_bag_outlined,
          judul: 'Keranjang Belanja Kosong',
          pesan:
              'Tidak ada menu yang bisa dicheckout. Pilih menu dulu sebelum memesan.',
          teksAksi: 'Pilih Menu Sekarang',
          saatAksiDitekan: _kembaliKeKatalog,
        );

      case KeadaanMuat.berhasil:
        return _bangunFormulir();
    }
  }

  Widget _bangunFormulir() {
    final isi = _keranjang!;
    final ringkasan = isi.ringkasan;

    return Form(
      key: _kunciForm,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // 1. Kartu jam operasional (informasi; keputusan tetap di server)
          _kartuJamOperasional(),

          const SizedBox(height: 14),

          // 2. Alamat pengiriman (Form + validator berbahasa Indonesia)
          _kartuAlamat(),

          const SizedBox(height: 14),

          // 3. Pemilih kurir dari GET /kurir
          _kartuKurir(),

          const SizedBox(height: 14),

          // 4. Isi keranjang (data server)
          _kartuItem(isi),

          const SizedBox(height: 14),

          // 5. Rincian pembayaran dari `ringkasan` server
          _kartuRincian(ringkasan),
        ],
      ),
    );
  }

  Widget _kartuJamOperasional() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TemaWarna.garisAbu),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          SizedBox(height: 8),
          Text(
            'Sesuai jam operasional toko',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: TemaWarna.cokelatUtama,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pesanan di luar rentang jam operasional akan ditolak oleh sistem.',
            style: TextStyle(
              fontSize: 12,
              color: TemaWarna.teksSekunder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuAlamat() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 12),
          TextFormField(
            controller: _namaController,
            textInputAction: TextInputAction.next,
            enabled: !_sedangKirim,
            decoration: _dekorasiInput(
              label: 'Nama Penerima',
              hint: 'Contoh: Budi Santoso',
            ),
            validator: (nilai) {
              final teks = nilai?.trim() ?? '';
              if (teks.isEmpty) return 'Nama penerima wajib diisi';
              if (teks.length < 3) return 'Nama penerima terlalu pendek';
              return null;
            },
            onChanged: (_) => _bersihkanGalatKolom(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _alamatController,
            maxLines: 3,
            enabled: !_sedangKirim,
            decoration: _dekorasiInput(
              label: 'Alamat Pengiriman',
              hint: 'Contoh: Jl. Mawar No. 12, Klojen, Kota Malang',
            ),
            validator: (nilai) {
              final teks = nilai?.trim() ?? '';
              if (teks.isEmpty) return 'Alamat pengiriman wajib diisi';
              if (teks.length < 10) {
                return 'Alamat terlalu pendek, tuliskan detail alamat';
              }
              return null;
            },
            onChanged: (_) => _bersihkanGalatKolom(),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed:
                _sedangKirim || _sedangAmbilLokasi ? null : _ambilLokasi,
            icon: _sedangAmbilLokasi
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(
              _sedangAmbilLokasi ? 'Mengambil lokasi...' : 'Gunakan lokasi saya',
            ),
          ),
          const Text(
            'Koordinat perlu dilengkapi dengan nama jalan dan patokan alamat.',
            style: TextStyle(fontSize: 12, color: TemaWarna.teksSekunder),
          ),
        ],
      ),
    );
  }

  InputDecoration _dekorasiInput({required String label, required String hint}) {
    // Pesan galat 422 dari server tampil tepat di bawah kolomnya
    final galat = _galatPerKolom[
        label == 'Nama Penerima' ? 'nama_penerima' : 'alamat_penerima'];

    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: galat,
      labelStyle: const TextStyle(fontSize: 13, color: TemaWarna.teksSekunder),
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      filled: true,
      fillColor: TemaWarna.abuMuda,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: const BorderSide(color: TemaWarna.cokelatUtama, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TemaWarna.merahHabis),
      ),
    );
  }

  void _bersihkanGalatKolom() {
    if (_galatPerKolom.isEmpty) return;
    setState(() => _galatPerKolom = {});
  }

  Widget _kartuKurir() {
    return Container(
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
          if (_daftarKurir.isEmpty)
            const Text(
              'Belum ada kurir aktif. Hubungi toko untuk informasi lebih lanjut.',
              style: TextStyle(fontSize: 12, color: TemaWarna.teksSekunder),
            )
          else
            for (final kurir in _daftarKurir) ...[
              _pilihanKurir(kurir),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _pilihanKurir(Kurir kurir) {
    final bool terpilih = _kurirTerpilihId == kurir.id;
    final bool mati = _sedangKirim || _sedangSegarkanRingkasan;

    return InkWell(
      onTap: mati ? null : () => _pilihKurir(kurir),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: terpilih ? Colors.white : TemaWarna.abuMuda,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: terpilih ? TemaWarna.cokelatUtama : TemaWarna.garisAbu,
            width: terpilih ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: terpilih ? TemaWarna.cokelatUtama : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.delivery_dining_rounded,
                size: 20,
                color: terpilih ? Colors.white : TemaWarna.cokelatUtama,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kurir.nama,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    kurir.wilayah,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TemaWarna.teksSekunder,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatRupiah(kurir.tarif),
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
              color: terpilih ? TemaWarna.cokelatUtama : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartuItem(IsiKeranjang isi) {
    return Container(
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
              const Text(
                'Menu Pesanan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                '${isi.jumlahItem} item',
                style: const TextStyle(
                  fontSize: 12,
                  color: TemaWarna.teksSekunder,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in isi.items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${item.jumlah}x ${item.nama}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  formatRupiah(item.subtotal),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _kartuRincian(RingkasanKeranjang ringkasan) {
    final bool sedangUbah = _sedangSegarkanRingkasan;

    return Container(
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
          if (sedangUbah)
            const LinearProgressIndicator(
              color: TemaWarna.cokelatUtama,
              minHeight: 2,
            )
          else ...[
            _barisRincian(
              'Subtotal Produk',
              formatRupiah(ringkasan.subtotal),
            ),
            _barisRincian(
              'Biaya Pengiriman',
              ringkasan.ongkosKirim == null
                  ? '—'
                  : formatRupiah(ringkasan.ongkosKirim!),
            ),
            const Divider(height: 20),
            _barisRincian(
              'Total Pembayaran',
              ringkasan.total == null
                  ? '—'
                  : formatRupiah(ringkasan.total!),
              tebal: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _bangunBilahBawah() {
    final ringkasan = _keranjang?.ringkasan;
    final bool mati = _sedangKirim || _sedangSegarkanRingkasan;

    return Container(
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
                      ringkasan?.total == null
                          ? '—'
                          : formatRupiah(ringkasan!.total!),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: TemaWarna.teksUtama,
                      ),
                    ),
                  ],
                ),
                if (_daftarMetode.isNotEmpty)
                  DropdownButton<String>(
                    value: _daftarMetode
                            .any((metode) => metode.kode == _metodeTerpilih)
                        ? _metodeTerpilih
                        : _daftarMetode.first.kode,
                    underline: const SizedBox(),
                    items: [
                      for (final metode in _daftarMetode)
                        DropdownMenuItem(
                          value: metode.kode,
                          child: Text(
                            metode.nama,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                    onChanged: mati
                        ? null
                        : (nilai) {
                            if (nilai != null) {
                              setState(() => _metodeTerpilih = nilai);
                            }
                          },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TombolUtama(
              teks: 'Buat Pesanan',
              warnaLatar: TemaWarna.cokelatUtama,
              sedangMemuat: _sedangKirim,
              onPressed: mati ? null : _buatPesanan,
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
