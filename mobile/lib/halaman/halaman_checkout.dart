import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../layanan/layanan_geocoding.dart';
import '../layanan/layanan_lokasi.dart';
import '../model/isi_keranjang.dart';
import '../model/katalog_promo.dart';
import '../model/kurir.dart';
import '../model/metode_pembayaran.dart';
import '../model/pesanan.dart';
import '../model/ringkasan_keranjang.dart';
import '../model/voucher_pelanggan.dart';
import '../umum/keadaan_muat.dart';
import '../umum/tema_warna.dart';
import '../umum/format_rupiah.dart';
import '../umum/galat_ui.dart';
import '../widget/tampilan_galat.dart';
import '../widget/tampilan_kosong.dart';
import '../widget/tampilan_muat.dart';
import '../widget/tombol_utama.dart';
import 'halaman_detail_pesanan.dart';
import 'halaman_promo.dart';

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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  /// Label alamat ala Shopee: Rumah, Kantor, Kampus, atau Lainnya.
  String _labelAlamat = 'Rumah';

  /// Koordinat opsional dari tombol "Gunakan lokasi saya".
  double? _latitude;
  double? _longitude;

  /// Voucher aktif milik pelanggan (`GET /promos`) untuk pemilih di checkout.
  List<VoucherPelanggan> _voucherAktif = [];
  int? _voucherTerpilihId;

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
  final MapController _mapController = MapController();
  final ValueNotifier<String> _statusLokasi = ValueNotifier<String>(
    'Peta lokasi pengiriman',
  );
  final LayananGeocoding _geocoding = const LayananGeocoding();
  Timer? _jedaGeocoding;
  int _urutanGeocoding = 0;
  bool _petaSiap = false;
  LatLng? _titikPeta;
  LatLng? _targetPeta;
  bool _sedangSegarkanRingkasan = false;

  /// Pesan galat 422 per kolom (PRD 7.3) untuk ditampilkan di bawah input.
  Map<String, String> _galatPerKolom = {};

  @override
  void initState() {
    super.initState();
    LayananLokasi.alamatPengirimanNotifier.addListener(
      _padaAlamatGlobalBerubah,
    );
    LayananLokasi.namaPenerimaNotifier.addListener(_padaNamaGlobalBerubah);
    _muatDataAwal();
  }

  @override
  void dispose() {
    LayananLokasi.alamatPengirimanNotifier.removeListener(
      _padaAlamatGlobalBerubah,
    );
    LayananLokasi.namaPenerimaNotifier.removeListener(_padaNamaGlobalBerubah);
    _jedaGeocoding?.cancel();
    _namaController.dispose();
    _phoneController.dispose();
    _regionController.dispose();
    _streetController.dispose();
    _noteController.dispose();
    _statusLokasi.dispose();
    super.dispose();
  }

  void _padaAlamatGlobalBerubah() {
    if (!mounted) return;
    final alamat = LayananLokasi.alamatPengirimanPilihan;
    final alamatTerkini = alamat ?? '';
    if (_streetController.text == alamatTerkini) return;
    setState(() {
      _streetController.text = alamatTerkini;
      _latitude = null;
      _longitude = null;
      _titikPeta = null;
    });
    if (alamatTerkini.trim().length >= 10) {
      _jedaGeocoding?.cancel();
      final urutan = ++_urutanGeocoding;
      unawaited(_cariAlamatDiPeta(alamatTerkini.trim(), urutan));
    }
  }

  void _padaNamaGlobalBerubah() {
    if (!mounted) return;
    final nama = LayananLokasi.namaPenerimaPilihan;
    if (nama != null && _namaController.text != nama) {
      setState(() => _namaController.text = nama);
    }
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

      // Voucher bersifat opsional: kegagalan memuat promo tidak boleh
      // menghalangi pelanggan menyelesaikan checkout.
      KatalogPromo? katalog;
      try {
        katalog = await _layanan.ambilKatalogPromo();
      } catch (_) {
        katalog = null;
      }

      if (!mounted) return;

      setState(() {
        final alamatPilihan = LayananLokasi.alamatPengirimanPilihan;

        if (riwayat.isNotEmpty) {
          final pesananTerakhir = riwayat.first;

          if (_namaController.text.isEmpty) {
            _namaController.text = pesananTerakhir.namaPenerima;
          }
          if (_phoneController.text.isEmpty) {
            _phoneController.text = pesananTerakhir.phone ?? '';
          }
          if (_regionController.text.isEmpty) {
            _regionController.text = pesananTerakhir.region ?? '';
          }
          if (_streetController.text.isEmpty) {
            _streetController.text =
                alamatPilihan ??
                pesananTerakhir.streetAddress ??
                pesananTerakhir.alamatPenerima;
          }

          final labelTerakhir = pesananTerakhir.label?.trim();
          if (labelTerakhir != null &&
              const [
                'Rumah',
                'Kantor',
                'Kampus',
                'Lainnya',
              ].contains(labelTerakhir)) {
            _labelAlamat = labelTerakhir;
          }

          _latitude ??= pesananTerakhir.latitude;
          _longitude ??= pesananTerakhir.longitude;
        } else if (_streetController.text.isEmpty && alamatPilihan != null) {
          _streetController.text = alamatPilihan;
        }

        if (_namaController.text.isNotEmpty) {
          LayananLokasi.namaPenerimaPilihan ??= _namaController.text;
        }
        if (_streetController.text.isNotEmpty) {
          LayananLokasi.alamatPengirimanPilihan ??= _streetController.text;
        }

        _voucherAktif = katalog?.voucherAktif ?? [];
        if (_voucherTerpilihId != null &&
            !_voucherAktif.any((item) => item.id == _voucherTerpilihId)) {
          _voucherTerpilihId = null;
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
      final alamatAwal = _streetController.text.trim();
      if (alamatAwal.length >= 10) {
        final urutan = ++_urutanGeocoding;
        unawaited(_cariAlamatDiPeta(alamatAwal, urutan));
      }
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
      tampilkanGalat(context, g);
    } catch (_) {
      tampilkanGalat(context, GalatApi.umum());
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
    _jedaGeocoding?.cancel();
    final urutan = ++_urutanGeocoding;
    setState(() => _sedangAmbilLokasi = true);
    _statusLokasi.value = 'Mengambil lokasi perangkat...';

    try {
      final posisi = await const LayananLokasi().ambilPosisiSaatIni();
      if (!mounted || urutan != _urutanGeocoding) return;

      final titik = LatLng(posisi.latitude, posisi.longitude);
      setState(() {
        _titikPeta = titik;
        _latitude = titik.latitude;
        _longitude = titik.longitude;
      });
      _geserPetaKe(titik);
      _statusLokasi.value = 'Mencari alamat dari lokasi perangkat...';

      final hasil = await _geocoding.balikArah(
        lintang: titik.latitude,
        bujur: titik.longitude,
      );
      if (!mounted || urutan != _urutanGeocoding) return;

      final alamat =
          hasil?.alamat ??
          'Lokasi perangkat: ${titik.latitude.toStringAsFixed(6)}, '
              '${titik.longitude.toStringAsFixed(6)}';
      setState(() {
        _streetController.text = alamat;
        LayananLokasi.alamatPengirimanPilihan = alamat;
      });
      _statusLokasi.value = hasil == null
          ? 'Alamat tidak ditemukan; koordinat perangkat ditampilkan.'
          : 'Alamat diambil dari lokasi perangkat';
      _bersihkanGalatKolom();
    } on LayananLokasiException catch (galat) {
      if (mounted) {
        _statusLokasi.value = galat.pesan;
        tampilkanGalat(context, GalatApi.umum(galat.pesan));
      }
    } catch (error) {
      if (mounted) {
        final pesan = 'Lokasi gagal diambil ($error). Coba lagi.';
        _statusLokasi.value = pesan;
        tampilkanGalat(context, GalatApi.umum(pesan));
      }
    } finally {
      if (mounted) setState(() => _sedangAmbilLokasi = false);
    }
  }

  void _saatNamaDiubah(String nilai) {
    _bersihkanGalatKolom();
    final nama = nilai.trim();
    LayananLokasi.namaPenerimaPilihan = nama.isEmpty ? null : nama;
  }

  void _saatAlamatDiubah(String nilai) {
    _bersihkanGalatKolom();
    final alamat = nilai.trim();
    LayananLokasi.alamatPengirimanPilihan = alamat.isEmpty ? null : alamat;
    setState(() {
      _latitude = null;
      _longitude = null;
      _titikPeta = null;
    });
    _jedaGeocoding?.cancel();
    final urutan = ++_urutanGeocoding;
    if (alamat.length < 10) {
      _statusLokasi.value = 'Tulis alamat lengkap agar peta dapat mengikuti.';
      return;
    }
    _jedaGeocoding = Timer(const Duration(milliseconds: 900), () {
      unawaited(_cariAlamatDiPeta(alamat, urutan));
    });
  }

  Future<void> _cariAlamatDiPeta(String alamat, int urutan) async {
    _statusLokasi.value = 'Mencari alamat di peta...';
    final hasil = await _geocoding.cariAlamat(alamat);
    if (!mounted || urutan != _urutanGeocoding) return;
    if (hasil == null) {
      _statusLokasi.value =
          'Alamat belum ditemukan atau layanan alamat tidak terjangkau.';
      return;
    }
    final titik = LatLng(hasil.lintang, hasil.bujur);
    setState(() {
      _titikPeta = titik;
      _latitude = titik.latitude;
      _longitude = titik.longitude;
    });
    _geserPetaKe(titik);
    _statusLokasi.value = 'Peta menampilkan: ${hasil.alamat}';
  }

  Future<void> _saatPetaDiklik(LatLng titik) async {
    _jedaGeocoding?.cancel();
    final urutan = ++_urutanGeocoding;
    setState(() {
      _titikPeta = titik;
      _latitude = titik.latitude;
      _longitude = titik.longitude;
    });
    _statusLokasi.value = 'Membaca alamat titik yang dipilih...';

    final hasil = await _geocoding.balikArah(
      lintang: titik.latitude,
      bujur: titik.longitude,
    );
    if (!mounted || urutan != _urutanGeocoding) return;
    if (hasil == null) {
      _statusLokasi.value =
          'Alamat titik belum terbaca. Coba lagi atau tulis manual.';
      return;
    }
    setState(() {
      _streetController.text = hasil.alamat;
      LayananLokasi.alamatPengirimanPilihan = hasil.alamat;
    });
    _bersihkanGalatKolom();
    _statusLokasi.value = 'Alamat dari titik yang dipilih di peta';
  }

  void _geserPetaKe(LatLng titik) {
    if (!_petaSiap) {
      _targetPeta = titik;
      return;
    }
    try {
      _mapController.move(titik, 16);
    } catch (_) {
      _targetPeta = titik;
    }
  }

  /// `POST /api/checkout` + `X-Kunci-Idempoten` (PRD 7.4).
  Future<void> _buatPesanan() async {
    if (_sedangKirim) return;

    if (!(_kunciForm.currentState?.validate() ?? false)) return;

    if (_kurirTerpilihId == null || _metodeTerpilih == null) {
      tampilkanGalat(
        context,
        GalatApi.umum('Pilih kurir dan metode pembayaran dulu.'),
      );
      return;
    }

    // Flag diset SEBELUM await agar satu ketukan tidak menjadi dua pesanan.
    setState(() {
      _sedangKirim = true;
      _galatPerKolom = {};
    });

    try {
      final nama = _namaController.text.trim();
      final phone = _phoneController.text.trim();
      final region = _regionController.text.trim();
      final street = _streetController.text.trim();
      final catatan = _noteController.text.trim();
      final alamatLengkap = region.isEmpty ? street : '$street, $region';

      final Pesanan pesanan = await _layanan.buatCheckout(
        namaPenerima: nama,
        alamatPenerima: alamatLengkap,
        kurirId: _kurirTerpilihId!,
        metodePembayaran: _metodeTerpilih!,
        kunciIdempoten: _kunciIdempoten,
        phone: phone,
        region: region,
        streetAddress: street,
        detailNote: catatan,
        label: _labelAlamat,
        latitude: _latitude,
        longitude: _longitude,
        voucherId: _voucherTerpilihId,
      );

      if (!mounted) return;
      LayananLokasi.alamatPengirimanPilihan = street;
      LayananLokasi.namaPenerimaPilihan = nama;

      // 201 → Rincian Pesanan dengan tumpukan dibersihkan (PRD 7.1)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HalamanDetailPesanan(pesananId: pesanan.id),
        ),
      );
    } on GalatApi catch (g) {
      if (!mounted) return;
      _tanganiGalatKirim(g);
    } catch (_) {
      tampilkanGalat(context, GalatApi.umum());
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
    tampilkanGalat(context, g);
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
        return TampilanGalat(galat: _galat, saatCobaLagi: _muatDataAwal);

      case KeadaanMuat.kosong:
        return TampilanKosong(
          ikon: Icons.shopping_bag_outlined,
          judul: 'Keranjang Belanja Kosong',
          pesan: 'Tidak ada menu yang bisa dicheckout. Pilih menu dulu sebelum memesan.',
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

          // 4. Voucher aktif milik pelanggan (opsional)
          _kartuVoucher(),

          const SizedBox(height: 14),

          // 5. Isi keranjang (data server)
          _kartuItem(isi),

          const SizedBox(height: 14),

          // 6. Rincian pembayaran dari `ringkasan` server
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
              Icon(
                Icons.access_time_rounded,
                size: 20,
                color: TemaWarna.cokelatUtama,
              ),
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
            style: TextStyle(fontSize: 12, color: TemaWarna.teksSekunder),
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
              Icon(
                Icons.location_on_outlined,
                size: 20,
                color: TemaWarna.cokelatUtama,
              ),
              SizedBox(width: 8),
              Text(
                'Alamat Pengiriman',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final label in const [
                'Rumah',
                'Kantor',
                'Kampus',
                'Lainnya',
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _labelAlamat == label,
                  showCheckmark: false,
                  selectedColor: TemaWarna.kremLembut,
                  backgroundColor: TemaWarna.abuMuda,
                  side: BorderSide(
                    color: _labelAlamat == label
                        ? TemaWarna.cokelatKaramel
                        : TemaWarna.garisAbu,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _labelAlamat == label
                        ? TemaWarna.cokelatPekat
                        : TemaWarna.teksSekunder,
                  ),
                  onSelected: _sedangKirim
                      ? null
                      : (_) => setState(() => _labelAlamat = label),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _namaController,
            textInputAction: TextInputAction.next,
            enabled: !_sedangKirim,
            textCapitalization: TextCapitalization.words,
            decoration: _dekorasiInput(
              label: 'Nama Penerima',
              hint: 'Contoh: Budi Santoso',
              kunci: 'nama_penerima',
            ),
            validator: (nilai) {
              final teks = nilai?.trim() ?? '';
              if (teks.isEmpty) return 'Nama penerima wajib diisi';
              if (teks.length < 3) return 'Nama penerima terlalu pendek';
              return null;
            },
            onChanged: _saatNamaDiubah,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            enabled: !_sedangKirim,
            maxLength: 20,
            decoration: _dekorasiInput(
              label: 'Nomor WhatsApp',
              hint: 'Contoh: 081234567890',
              kunci: 'phone',
            ).copyWith(counterText: ''),
            validator: (nilai) {
              final teks = nilai?.trim() ?? '';
              final digit = teks.replaceAll(RegExp(r'\D'), '');
              if (teks.isEmpty) return 'Nomor WhatsApp wajib diisi';
              if (digit.length < 9 || digit.length > 15) {
                return 'Nomor WhatsApp tidak valid';
              }
              return null;
            },
            onChanged: (_) => _bersihkanGalatKolom(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regionController,
            textInputAction: TextInputAction.next,
            enabled: !_sedangKirim,
            textCapitalization: TextCapitalization.words,
            maxLength: 60,
            decoration: _dekorasiInput(
              label: 'Kota / Kecamatan',
              hint: 'Contoh: Lowokwaru, Kota Malang',
              kunci: 'region',
            ).copyWith(counterText: ''),
            validator: (nilai) {
              final teks = nilai?.trim() ?? '';
              if (teks.isEmpty) return 'Kota/kecamatan wajib diisi';
              return null;
            },
            onChanged: (_) => _bersihkanGalatKolom(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _streetController,
            maxLines: 3,
            enabled: !_sedangKirim,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 180,
            decoration: _dekorasiInput(
              label: 'Alamat Lengkap',
              hint: 'Contoh: Jl. Mawar No. 12, RT 02/RW 03',
              kunci: 'street_address',
            ).copyWith(counterText: ''),
            validator: (nilai) {
              final teks = nilai?.trim() ?? '';
              if (teks.isEmpty) return 'Alamat lengkap wajib diisi';
              if (teks.length < 10) {
                return 'Alamat terlalu pendek, tuliskan detail alamat';
              }
              return null;
            },
            onChanged: _saatAlamatDiubah,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            maxLines: 2,
            enabled: !_sedangKirim,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 200,
            decoration: _dekorasiInput(
              label: 'Patokan (opsional)',
              hint: 'Contoh: Pagar hitam, sebelah warung kopi',
              kunci: 'detail_note',
            ).copyWith(counterText: ''),
            onChanged: (_) => _bersihkanGalatKolom(),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _sedangKirim || _sedangAmbilLokasi
                    ? null
                    : _ambilLokasi,
                icon: _sedangAmbilLokasi
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: Text(
                  _sedangAmbilLokasi
                      ? 'Mengambil lokasi...'
                      : 'Gunakan lokasi saya',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              if (_latitude != null && _longitude != null)
                Expanded(
                  child: Text(
                    'Koordinat tersimpan (${_latitude!.toStringAsFixed(4)}, '
                    '${_longitude!.toStringAsFixed(4)})',
                    style: const TextStyle(
                      fontSize: 11,
                      color: TemaWarna.hijauBuka,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<String>(
            valueListenable: _statusLokasi,
            builder: (context, teks, _) => Text(
              teks,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TemaWarna.teksSekunder,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(-7.9666, 112.6326),
                  initialZoom: 14,
                  onTap: (_, titik) => _saatPetaDiklik(titik),
                  onMapReady: () {
                    _petaSiap = true;
                    final target = _targetPeta;
                    if (target != null) _geserPetaKe(target);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    fallbackUrl: 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.makanyuk',
                  ),
                  if (_titikPeta != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _titikPeta!,
                          width: 44,
                          height: 44,
                          alignment: Alignment.topCenter,
                          child: Icon(
                            Icons.location_pin,
                            size: 44,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ketuk peta untuk memilih titik, ketik alamat untuk menggeser peta, atau gunakan lokasi perangkat.',
            style: TextStyle(fontSize: 12, color: TemaWarna.teksSekunder),
          ),
        ],
      ),
    );
  }

  InputDecoration _dekorasiInput({
    required String label,
    required String hint,
    String? kunci,
  }) {
    // Pesan galat 422 dari server tampil tepat di bawah kolomnya.
    final galat = kunci == null ? null : _galatPerKolom[kunci];

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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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

  VoucherPelanggan? get _voucherDipilih {
    if (_voucherTerpilihId == null) return null;

    for (final voucher in _voucherAktif) {
      if (voucher.id == _voucherTerpilihId) return voucher;
    }

    return null;
  }

  /// Pratinjau diskon di klien; nilai final tetap dihitung server.
  int _diskonPreview(RingkasanKeranjang ringkasan) {
    final promo = _voucherDipilih?.promo;
    if (promo == null) return 0;

    return promo.perkiraanDiskon(ringkasan.subtotal);
  }

  int? _totalPreview(RingkasanKeranjang ringkasan) {
    final ongkir = ringkasan.ongkosKirim;
    if (ongkir == null) return null;

    final total = ringkasan.subtotal + ongkir - _diskonPreview(ringkasan);

    return total < 0 ? 0 : total;
  }

  Future<void> _muatVoucher() async {
    try {
      final katalog = await _layanan.ambilKatalogPromo();
      if (!mounted) return;
      setState(() {
        _voucherAktif = katalog.voucherAktif;
        if (_voucherTerpilihId != null &&
            !_voucherAktif.any((voucher) => voucher.id == _voucherTerpilihId)) {
          _voucherTerpilihId = null;
        }
      });
    } catch (_) {
      // Voucher opsional: checkout tetap berjalan tanpa voucher.
    }
  }

  Future<void> _bukaHalamanPromo() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const HalamanPromo()));
    if (mounted) await _muatVoucher();
  }

  Widget _kartuVoucher() {
    final subtotal = _keranjang?.ringkasan.subtotal ?? 0;

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
            children: [
              const Icon(
                Icons.confirmation_number_outlined,
                size: 20,
                color: TemaWarna.cokelatUtama,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Voucher & Promo',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: _sedangKirim ? null : _bukaHalamanPromo,
                child: const Text('Tambah', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (_voucherAktif.isEmpty)
            InkWell(
              onTap: _sedangKirim ? null : _bukaHalamanPromo,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TemaWarna.abuMuda,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Belum ada voucher. Klaim kode atau tukar poin di halaman Promo.',
                  style: TextStyle(fontSize: 12, color: TemaWarna.teksSekunder),
                ),
              ),
            )
          else ...[
            _opsiVoucher(
              id: null,
              judul: 'Tanpa voucher',
              keterangan: 'Bayar dengan harga normal',
              terpilih: _voucherTerpilihId == null,
              aktif: true,
            ),
            for (final voucher in _voucherAktif) ...[
              const SizedBox(height: 8),
              _opsiVoucher(
                id: voucher.id,
                judul: voucher.promo?.judul ?? 'Voucher MakanYuk!',
                keterangan: _keteranganVoucher(voucher, subtotal),
                terpilih: _voucherTerpilihId == voucher.id,
                aktif: _voucherBolehDipakai(voucher, subtotal),
              ),
            ],
          ],
        ],
      ),
    );
  }

  bool _voucherBolehDipakai(VoucherPelanggan voucher, int subtotal) {
    final promo = voucher.promo;
    if (promo == null) return false;

    return subtotal >= promo.minimalBelanja;
  }

  String _keteranganVoucher(VoucherPelanggan voucher, int subtotal) {
    final promo = voucher.promo;
    if (promo == null) return voucher.labelStatus;

    final potongan = promo.labelDiskon.isNotEmpty
        ? promo.labelDiskon
        : promo.labelTipe;
    final kode = promo.kode.isEmpty ? '' : '${promo.kode} • ';

    if (!_voucherBolehDipakai(voucher, subtotal)) {
      return '$kode$potongan • Min. ${formatRupiah(promo.minimalBelanja)}';
    }

    return '$kode$potongan';
  }

  Widget _opsiVoucher({
    required int? id,
    required String judul,
    required String keterangan,
    required bool terpilih,
    required bool aktif,
  }) {
    return InkWell(
      onTap: !aktif || _sedangKirim
          ? null
          : () => setState(() => _voucherTerpilihId = id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: terpilih ? TemaWarna.kremLembut : TemaWarna.abuMuda,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: terpilih ? TemaWarna.cokelatKaramel : TemaWarna.garisAbu,
            width: terpilih ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              terpilih
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: aktif
                  ? (terpilih
                        ? TemaWarna.cokelatKaramel
                        : TemaWarna.teksSekunder)
                  : TemaWarna.garisAbu,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: aktif
                          ? TemaWarna.teksUtama
                          : TemaWarna.teksSekunder,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    keterangan,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TemaWarna.teksSekunder,
                    ),
                  ),
                ],
              ),
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
            _barisRincian('Subtotal Produk', formatRupiah(ringkasan.subtotal)),
            if (_diskonPreview(ringkasan) > 0)
              _barisRincian(
                'Diskon Voucher',
                '−${formatRupiah(_diskonPreview(ringkasan))}',
                warnaNilai: TemaWarna.hijauBuka,
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
              _totalPreview(ringkasan) == null
                  ? '—'
                  : formatRupiah(_totalPreview(ringkasan)!),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_daftarMetode.isNotEmpty) ...[
              const Text(
                'METODE PEMBAYARAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: TemaWarna.teksSekunder,
                ),
              ),
              DropdownButton<String>(
                isExpanded: true,
                itemHeight: null,
                value:
                    _daftarMetode.any(
                      (metode) => metode.kode == _metodeTerpilih,
                    )
                    ? _metodeTerpilih
                    : _daftarMetode.first.kode,
                underline: const SizedBox(),
                items: [
                  for (final metode in _daftarMetode)
                    DropdownMenuItem<String>(
                      value: metode.kode,
                      child: Text(
                        metode.nama,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'TOTAL TAGIHAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: TemaWarna.teksSekunder,
                    ),
                  ),
                ),
                Text(
                  ringkasan == null || _totalPreview(ringkasan) == null
                      ? '—'
                      : formatRupiah(_totalPreview(ringkasan)!),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: TemaWarna.teksUtama,
                  ),
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
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: tebal ? FontWeight.w700 : FontWeight.w400,
                color: tebal ? TemaWarna.teksUtama : TemaWarna.teksSekunder,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nilai,
              textAlign: TextAlign.right,
              softWrap: true,
              style: TextStyle(
                fontSize: 13,
                fontWeight: tebal ? FontWeight.w800 : FontWeight.w600,
                color:
                    warnaNilai ??
                    (tebal ? TemaWarna.cokelatUtama : TemaWarna.teksUtama),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
