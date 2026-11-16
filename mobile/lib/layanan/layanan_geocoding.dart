import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Alamat terbaca beserta titik koordinat hasil geocoding.
class HasilGeocoding {
  final String alamat;
  final double lintang;
  final double bujur;

  const HasilGeocoding({
    required this.alamat,
    required this.lintang,
    required this.bujur,
  });
}

/// Geocoding tanpa API key.
///
/// Dua arah yang dipakai aplikasi:
/// * [balikArah] — koordinat → alamat (mode **otomatis**, lokasi perangkat),
/// * [cariAlamat] — alamat → koordinat (mode **manual**, peta mengikuti ketikan).
///
/// Sumber utama: **Nominatim** (OpenStreetMap). Cadangan: **Photon** (komoot),
/// dipakai bila Nominatim gagal/rate-limit supaya tombol lokasi tetap
/// menghasilkan alamat, bukan koordinat.
///
/// Nominatim membatasi ±1 permintaan per detik, jadi ketikan manual diberi
/// jeda (debounce) oleh pemanggil.
class LayananGeocoding {
  const LayananGeocoding();

  static const String _nominatim = 'https://nominatim.openstreetmap.org';
  static const String _photon = 'https://photon.komoot.io';
  static const String _agen = 'projek_makanyuk/1.0 (tugas UTS PAPB)';
  static const Duration _batasWaktu = Duration(seconds: 10);

  static const Map<String, String> _header = {
    'User-Agent': _agen,
    'Accept': 'application/json',
  };

  // ---------------------------------------------------------------------------
  // Koordinat → alamat (mode otomatis)
  // ---------------------------------------------------------------------------

  Future<HasilGeocoding?> balikArah({
    required double lintang,
    required double bujur,
  }) async {
    final hasil = await _balikArahNominatim(lintang, bujur);
    if (hasil != null) return hasil;

    debugPrint('[geocoding] Nominatim gagal, mencoba cadangan (Photon)...');
    return _balikArahPhoton(lintang, bujur);
  }

  Future<HasilGeocoding?> _balikArahNominatim(
    double lintang,
    double bujur,
  ) async {
    final uri = Uri.parse('$_nominatim/reverse').replace(
      queryParameters: {
        'lat': lintang.toStringAsFixed(6),
        'lon': bujur.toStringAsFixed(6),
        'format': 'jsonv2',
        'accept-language': 'id',
      },
    );

    final respons = await _ambil(uri);
    if (respons == null) return null;

    try {
      final isi = jsonDecode(respons.body);
      if (isi is! Map) return null;

      final daftarKomponen = isi['address'];
      final tampilan = isi['display_name']?.toString().trim() ?? '';
      final alamat = daftarKomponen is Map
          ? _susunAlamat(Map<String, dynamic>.from(daftarKomponen), tampilan)
          : tampilan;
      if (alamat.isEmpty) return null;

      return HasilGeocoding(
        alamat: alamat,
        lintang: double.tryParse(isi['lat']?.toString() ?? '') ?? lintang,
        bujur: double.tryParse(isi['lon']?.toString() ?? '') ?? bujur,
      );
    } catch (e) {
      debugPrint('[geocoding] balas Nominatim tidak terbaca: $e');
      return null;
    }
  }

  Future<HasilGeocoding?> _balikArahPhoton(double lintang, double bujur) async {
    final uri = Uri.parse('$_photon/reverse').replace(
      queryParameters: {
        'lat': lintang.toStringAsFixed(6),
        'lon': bujur.toStringAsFixed(6),
      },
    );

    final respons = await _ambil(uri);
    if (respons == null) return null;
    return _dariPhoton(respons.body, fallbackLat: lintang, fallbackLng: bujur);
  }

  // ---------------------------------------------------------------------------
  // Alamat → koordinat (mode manual)
  // ---------------------------------------------------------------------------

  Future<HasilGeocoding?> cariAlamat(String teks) async {
    final kueri = teks.trim();
    if (kueri.isEmpty) return null;

    // Nominatim sering tidak menemukan hasil bila nomor rumah yang diketik
    // tidak ada di data OpenStreetMap, jadi kueri dicoba ulang dengan versi
    // yang semakin ringkas sampai ada hasil.
    final kandidat = _kandidatKueri(kueri);
    for (var urutan = 0; urutan < kandidat.length; urutan++) {
      if (urutan > 0) {
        // Kebijakan Nominatim: maksimum ±1 permintaan per detik.
        await Future<void>.delayed(const Duration(milliseconds: 1100));
      }
      final hasil = await _cariNominatim(kandidat[urutan]);
      if (hasil != null) return hasil;
    }

    debugPrint('[geocoding] Nominatim gagal, mencoba cadangan (Photon)...');
    return _cariPhoton(kueri);
  }

  Future<HasilGeocoding?> _cariNominatim(String kueri) async {
    final uri = Uri.parse('$_nominatim/search').replace(
      queryParameters: {
        'q': kueri,
        'format': 'jsonv2',
        'limit': '1',
        'accept-language': 'id',
      },
    );

    final respons = await _ambil(uri);
    if (respons == null) return null;

    try {
      final isi = jsonDecode(respons.body);
      if (isi is! List || isi.isEmpty || isi.first is! Map) return null;
      return _dariDaftarNominatim(Map<String, dynamic>.from(isi.first as Map));
    } catch (e) {
      debugPrint('[geocoding] balas Nominatim tidak terbaca: $e');
      return null;
    }
  }

  Future<HasilGeocoding?> _cariPhoton(String kueri) async {
    final uri = Uri.parse('$_photon/api/')
        .replace(queryParameters: {'q': kueri, 'limit': '1'});

    final respons = await _ambil(uri);
    if (respons == null) return null;
    return _dariPhoton(respons.body);
  }

  HasilGeocoding? _dariDaftarNominatim(Map<String, dynamic> pertama) {
    final lintang = double.tryParse(pertama['lat']?.toString() ?? '');
    final bujur = double.tryParse(pertama['lon']?.toString() ?? '');
    if (lintang == null || bujur == null) return null;

    final alamat = pertama['display_name']?.toString().trim() ?? '';
    if (alamat.isEmpty) return null;

    return HasilGeocoding(alamat: alamat, lintang: lintang, bujur: bujur);
  }

  /// Membaca balasan Photon (GeoJSON `FeatureCollection`) menjadi alamat.
  HasilGeocoding? _dariPhoton(
    String body, {
    double? fallbackLat,
    double? fallbackLng,
  }) {
    try {
      final isi = jsonDecode(body);
      if (isi is! Map) return null;

      final daftarFitur = isi['features'];
      if (daftarFitur is! List || daftarFitur.isEmpty) return null;
      if (daftarFitur.first is! Map) return null;

      final fitur = Map<String, dynamic>.from(daftarFitur.first as Map);
      final koordinat = fitur['geometry'] is Map
          ? (fitur['geometry'] as Map)['coordinates']
          : null;
      if (koordinat is! List || koordinat.length < 2) return null;

      final bujur = double.tryParse(koordinat[0]?.toString() ?? '');
      final lintang = double.tryParse(koordinat[1]?.toString() ?? '');
      if (lintang == null || bujur == null) return null;

      final properti = fitur['properties'] is Map
          ? Map<String, dynamic>.from(fitur['properties'] as Map)
          : <String, dynamic>{};
      final alamat = _susunAlamat(_kanonisasiPhoton(properti), '');
      if (alamat.isEmpty && (fallbackLat == null || fallbackLng == null)) {
        return null;
      }

      return HasilGeocoding(
        alamat: alamat.isEmpty ? 'Lokasi ditemukan di peta' : alamat,
        lintang: lintang,
        bujur: bujur,
      );
    } catch (e) {
      debugPrint('[geocoding] balas Photon tidak terbaca: $e');
      return null;
    }
  }

  /// Menyamakan kunci properti Photon dengan kunci komponen Nominatim,
  /// sehingga penyusunan alamat cukup ditulis satu kali.
  Map<String, dynamic> _kanonisasiPhoton(Map<String, dynamic> properti) {
    String? teks(String kunci) {
      final nilai = properti[kunci]?.toString().trim();
      return nilai == null || nilai.isEmpty ? null : nilai;
    }

    final jalan = teks('street') ?? teks('name');
    final nama = teks('name');

    final hasil = <String, dynamic>{};
    void isi(String kunci, String? nilai) {
      if (nilai != null) hasil[kunci] = nilai;
    }

    isi('road', jalan);
    isi('house_number', teks('housenumber'));
    if (nama != null && nama != jalan) isi('neighbourhood', nama);
    isi('suburb', teks('district'));
    isi('quarter', teks('locality'));
    isi('city', teks('city'));
    isi('county', teks('county'));
    isi('state', teks('state'));
    isi('postcode', teks('postcode'));
    isi('country', teks('country'));
    return hasil;
  }

  // ---------------------------------------------------------------------------
  // Util
  // ---------------------------------------------------------------------------

  /// GET dengan batas waktu; `null` + log bila gagal (offline, CORS, rate-limit).
  Future<http.Response?> _ambil(Uri uri) async {
    try {
      final respons = await http
          .get(uri, headers: _header)
          .timeout(_batasWaktu);
      if (respons.statusCode != 200) {
        debugPrint(
          '[geocoding] HTTP ${respons.statusCode} dari ${uri.host}${uri.path}',
        );
        return null;
      }
      return respons;
    } catch (e) {
      debugPrint('[geocoding] gagal menghubungi ${uri.host}: $e');
      return null;
    }
  }

  /// Daftar kueri Nominatim yang dicoba berurutan: alamat lengkap, tanpa
  /// nomor rumah, lalu hanya segmen jalan/kota pertamanya.
  List<String> _kandidatKueri(String kueri) {
    final tanpaNomor = kueri
        .replaceAll(RegExp(r'\bNo\.?\s*#?\s*\d+[A-Za-z]?\b'), '')
        .replaceAll(RegExp(r'#\s*\d+[A-Za-z]?\b'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'\s+,'), ',')
        .trim();

    final segmenPertama = tanpaNomor.split(',').first.trim();

    return <String>{
      kueri,
      if (tanpaNomor.isNotEmpty && tanpaNomor != kueri) tanpaNomor,
      if (segmenPertama.isNotEmpty &&
          segmenPertama != kueri &&
          segmenPertama != tanpaNomor)
        segmenPertama,
    }.toList();
  }

  /// Menyusun alamat rapi dari komponen Nominatim/Photon, mis.
  /// "Jalan Mawar No. 12, Klojen, Kota Malang, Jawa Timur 65111".
  /// Bila komponen kosong, pakai [cadangan] (`display_name`).
  String _susunAlamat(Map<String, dynamic> komponen, String cadangan) {
    String? ambil(List<String> kunci) {
      for (final kunciSatu in kunci) {
        final nilai = komponen[kunciSatu]?.toString().trim();
        if (nilai != null && nilai.isNotEmpty) return nilai;
      }
      return null;
    }

    final jalan = ambil(['road', 'pedestrian', 'footway', 'path']);
    final nomor = komponen['house_number']?.toString().trim();
    final barisJalan = [
      ?jalan,
      if (nomor != null && nomor.isNotEmpty) 'No. $nomor',
    ].join(' ');

    final kampung = ambil([
      'neighbourhood',
      'suburb',
      'quarter',
      'village',
      'hamlet',
      'city_district',
    ]);
    final kota = ambil([
      'city',
      'town',
      'municipality',
      'county',
      'state_district',
    ]);
    final provinsi = ambil(['state', 'province']);
    final negara = ambil(['country']);
    final kodePos = komponen['postcode']?.toString().trim();

    final baris = <String>[
      if (barisJalan.isNotEmpty) barisJalan,
      if (kampung != null && kampung != barisJalan) kampung,
      if (kota != null && kota != kampung) kota,
      if (provinsi != null && provinsi != kota)
        kodePos != null && kodePos.isNotEmpty ? '$provinsi $kodePos' : provinsi,
      if (negara != null && negara != provinsi && negara != kota) negara,
    ];

    final hasil = baris.join(', ');
    return hasil.isEmpty ? cadangan : hasil;
  }
}
