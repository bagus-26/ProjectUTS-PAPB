import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../layanan/layanan_geocoding.dart';
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

  final TextEditingController _alamatController = TextEditingController();
  final MapController _mapController = MapController();
  final LayananGeocoding _geocoding = const LayananGeocoding();

  /// Status peta (memuat, hasil geocoding, atau galat) tampil di atas peta.
  final ValueNotifier<String> _statusPeta = ValueNotifier<String>(
    'Peta alamat pengiriman',
  );

  bool _sedangAmbilLokasi = false;

  /// Peta baru bisa digerakkan setelah widget-nya terpasang; bila belum,
  /// target disimpan dulu di [_targetPeta] lalu diterapkan saat peta siap.
  bool _petaSiap = false;
  LatLng? _titikPeta;
  LatLng? _targetPeta;

  /// Jeda debounce ketikan manual; Nominatim membatasi ±1 permintaan/detik.
  Timer? _jedaGeocoding;
  int _urutanGeocoding = 0;

  @override
  void initState() {
    super.initState();
    LayananLokasi.alamatPengirimanNotifier.addListener(
      _padaAlamatGlobalBerubah,
    );
    LayananLokasi.namaPenerimaNotifier.addListener(_padaNamaGlobalBerubah);
    _muatRingkasan();
  }

  @override
  void dispose() {
    LayananLokasi.alamatPengirimanNotifier.removeListener(
      _padaAlamatGlobalBerubah,
    );
    LayananLokasi.namaPenerimaNotifier.removeListener(_padaNamaGlobalBerubah);
    _jedaGeocoding?.cancel();
    _alamatController.dispose();
    _statusPeta.dispose();
    super.dispose();
  }

  void _padaAlamatGlobalBerubah() {
    if (!mounted) return;
    final alamatBaru = LayananLokasi.alamatPengirimanPilihan;
    if (_alamat != alamatBaru) {
      setState(() {
        _alamat = alamatBaru;
        if (alamatBaru != null && _alamatController.text != alamatBaru) {
          _alamatController.text = alamatBaru;
        }
      });
      if (alamatBaru != null && alamatBaru.trim().length >= 10) {
        _jedaGeocoding?.cancel();
        final urutan = ++_urutanGeocoding;
        unawaited(_cariAlamatDiPeta(alamatBaru.trim(), urutan));
      }
    }
  }

  void _padaNamaGlobalBerubah() {
    if (!mounted) return;
    final namaBaru = LayananLokasi.namaPenerimaPilihan;
    if (namaBaru != null && _nama != namaBaru) {
      setState(() {
        _nama = namaBaru;
      });
    }
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
          _nama =
              LayananLokasi.namaPenerimaPilihan ?? pesananTerakhir.namaPenerima;
          _alamat ??= pesananTerakhir.alamatPenerima;
        }
        LayananLokasi.namaPenerimaPilihan ??= _nama;
        LayananLokasi.alamatPengirimanPilihan ??= _alamat;
        if (_alamatController.text.trim().isEmpty && _alamat != null) {
          _alamatController.text = _alamat!;
        }
        _memuat = false;
      });

      // Peta langsung menampilkan lokasi alamat yang sudah tersimpan,
      // sehingga pin mengikuti alamat sejak halaman dibuka.
      final alamatAwal = _alamatController.text.trim();
      if (alamatAwal.length >= 10) {
        _jedaGeocoding?.cancel();
        final urutan = ++_urutanGeocoding;
        unawaited(_cariAlamatDiPeta(alamatAwal, urutan));
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
        _galat = 'Ringkasan akun tidak dapat dimuat. Coba lagi.';
        _memuat = false;
      });
    }
  }

  /// Mode **otomatis**: ambil lokasi perangkat lalu tampilkan alamatnya
  /// (reverse geocoding), bukan koordinat mentah.
  Future<void> _ambilLokasiPerangkat() async {
    if (_sedangAmbilLokasi) return;

    // Pencarian manual yang masih tertunda dibatalkan agar tidak menimpa
    // hasil lokasi perangkat.
    _jedaGeocoding?.cancel();
    final urutan = ++_urutanGeocoding;

    setState(() => _sedangAmbilLokasi = true);
    _statusPeta.value = 'Mengambil lokasi perangkat...';

    try {
      final posisi = await const LayananLokasi().ambilPosisiSaatIni();
      if (!mounted || urutan != _urutanGeocoding) return;

      final titik = LatLng(posisi.latitude, posisi.longitude);
      setState(() => _titikPeta = titik);
      _geserPetaKe(titik, 16);
      _statusPeta.value = 'Mencari alamat dari lokasi perangkat...';

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
        _alamat = alamat;
        _alamatController.text = alamat;
        LayananLokasi.alamatPengirimanPilihan = alamat;
      });
      _statusPeta.value = hasil != null
          ? 'Alamat diambil dari lokasi perangkat'
          : 'Layanan alamat tidak terjangkau; koordinat perangkat ditampilkan. Coba lagi.';
    } on LayananLokasiException catch (galat) {
      _statusPeta.value = galat.pesan;
    } catch (e) {
      _statusPeta.value =
          'Lokasi gagal diambil ($e). Coba lagi atau ketuk titik di peta.';
    } finally {
      if (mounted) setState(() => _sedangAmbilLokasi = false);
    }
  }

  /// Mode **manual**: alamat disimpan tiap ketikan lalu peta di-geocode
  /// setelah jeda, sehingga peta mengikuti alamat yang diketik.
  void _saatAlamatDiubah(String nilai) {
    final teks = nilai.trim();
    setState(() {
      _alamat = teks.isEmpty ? null : teks;
      LayananLokasi.alamatPengirimanPilihan = teks.isEmpty ? null : teks;
    });

    _jedaGeocoding?.cancel();
    final urutan = ++_urutanGeocoding;

    if (teks.length < 10) {
      _statusPeta.value = 'Tulis alamat lengkap agar peta dapat mengikuti.';
      return;
    }

    _jedaGeocoding = Timer(
      const Duration(milliseconds: 900),
      () => _cariAlamatDiPeta(teks, urutan),
    );
  }

  Future<void> _cariAlamatDiPeta(String teks, int urutan) async {
    _statusPeta.value = 'Mencari lokasi alamat di peta...';
    final hasil = await _geocoding.cariAlamat(teks);
    if (!mounted || urutan != _urutanGeocoding) return;

    if (hasil == null) {
      _statusPeta.value = 'Alamat belum ditemukan di peta (atau layanan alamat tidak terjangkau). Tulis lebih lengkap, mis. Jl. Mawar No. 12, Malang.';
      return;
    }

    final titik = LatLng(hasil.lintang, hasil.bujur);
    setState(() => _titikPeta = titik);
    _geserPetaKe(titik, 16);
    _statusPeta.value = 'Peta menampilkan: ${hasil.alamat}';
  }

  /// Mode **ketuk peta**: titik yang dipilih pengguna di-reverse geocode
  /// menjadi alamat, lalu alamat itu mengisi kolom alamat pengiriman.
  Future<void> _saatPetaDiklik(LatLng titik) async {
    // Ketikan manual yang masih tertunda dibatalkan agar tidak menimpa
    // hasil pilihan dari peta.
    _jedaGeocoding?.cancel();
    final urutan = ++_urutanGeocoding;

    // Pin pindah dulu supaya pengguna langsung melihat titik pilihannya,
    // kamera tidak digeser karena titiknya memang sudah di layar.
    setState(() => _titikPeta = titik);
    _statusPeta.value = 'Membaca alamat titik yang dipilih di peta...';

    final hasil = await _geocoding.balikArah(
      lintang: titik.latitude,
      bujur: titik.longitude,
    );
    if (!mounted || urutan != _urutanGeocoding) return;

    if (hasil == null) {
      _statusPeta.value = 'Alamat titik ini belum terbaca (layanan alamat tidak terjangkau). Ketuk lagi, atau tulis manual.';
      return;
    }

    setState(() {
      _alamat = hasil.alamat;
      _alamatController.text = hasil.alamat;
      LayananLokasi.alamatPengirimanPilihan = hasil.alamat;
    });
    _statusPeta.value = 'Alamat dari titik yang dipilih di peta';
  }

  /// Menggerakkan peta ke [titik]; bila peta belum terpasang, targetnya
  /// diterapkan lewat `onMapReady`.
  void _geserPetaKe(LatLng titik, double zoom) {
    _targetPeta = titik;
    if (!_petaSiap) return;
    try {
      _mapController.move(titik, zoom);
    } catch (_) {
      // Peta belum siap; target diterapkan saat onMapReady dipanggil.
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

  Future<void> _tampilkanDialogUbahNama() async {
    final controller = TextEditingController(text: _nama);
    final formKey = GlobalKey<FormState>();

    final hasil = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama Pengguna'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap',
              hintText: 'Masukkan nama Anda',
            ),
            validator: (val) {
              final teks = val?.trim() ?? '';
              if (teks.isEmpty) return 'Nama tidak boleh kosong';
              if (teks.length < 3) return 'Nama terlalu pendek';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (hasil != null && hasil.isNotEmpty && mounted) {
      setState(() {
        _nama = hasil;
      });
      LayananLokasi.namaPenerimaPilihan = hasil;
    }
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _nama,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _tampilkanDialogUbahNama,
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: TemaWarna.cokelatUtama,
                          ),
                        ),
                      ],
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

        // Alamat pengiriman + peta inline (tanpa popup).
        _kartuAlamat(),
        const SizedBox(height: 16),
        Card(
          color: Colors.white,
          child: Column(
            children: [
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

  /// Kartu alamat: input manual + tombol lokasi otomatis, dengan peta
  /// yang tampil tepat di bawahnya dan mengikuti alamat yang dipilih.
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
          TextField(
            controller: _alamatController,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Alamat pengiriman',
              hintText: 'Contoh: Jl. Mawar No. 12, Klojen, Kota Malang',
              filled: true,
              fillColor: TemaWarna.abuMuda,
              labelStyle: const TextStyle(
                fontSize: 13,
                color: TemaWarna.teksSekunder,
              ),
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
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
                  color: TemaWarna.cokelatUtama,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: _saatAlamatDiubah,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _sedangAmbilLokasi ? null : _ambilLokasiPerangkat,
            icon: _sedangAmbilLokasi
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(
              _sedangAmbilLokasi
                  ? 'Mengambil lokasi...'
                  : 'Ambil lokasi otomatis',
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<String>(
            valueListenable: _statusPeta,
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

          // Peta inline di bawah alamat pengiriman (Leaflet/OpenStreetMap).
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(-7.9666, 112.6326),
                  initialZoom: 14,
                  // Ketuk peta → titik itu dijadikan alamat pengiriman.
                  onTap: (posisi, titik) => _saatPetaDiklik(titik),
                  onMapReady: () {
                    _petaSiap = true;
                    final target = _targetPeta;
                    if (target != null) {
                      try {
                        _mapController.move(target, 16);
                      } catch (_) {
                        // Peta belum benar-benar siap; biarkan apa adanya.
                      }
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    // Cadangan bila tile utama gagal/rate-limit.
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
            'Ketuk titik mana pun di peta untuk memilih alamat, ketik alamat manual agar peta mengikuti, atau ambil alamat otomatis dari lokasi perangkat.',
            style: TextStyle(fontSize: 12, color: TemaWarna.teksSekunder),
          ),
        ],
      ),
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
