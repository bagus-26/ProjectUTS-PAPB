import 'dart:convert';

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

/// Geocoding tanpa API key memakai Nominatim milik OpenStreetMap.
///
/// Dua arah yang dipakai aplikasi:
/// * [balikArah] — koordinat → alamat (mode **otomatis**, lokasi perangkat),
/// * [cariAlamat] — alamat → koordinat (mode **manual**, peta mengikuti ketikan).
///
/// Nominatim membatasi sekitar 1 permintaan per detik, sehingga pemanggil
/// wajib memberi jeda (debounce) untuk ketikan manual.
class LayananGeocoding {
  const LayananGeocoding();

  static const String _akar = 'https://nominatim.openstreetmap.org';
  static const String _agen = 'projek_makanyuk/1.0 (tugas UTS PAPB)';
  static const Duration _batasWaktu = Duration(seconds: 10);

  static const Map<String, String> _header = {
    'User-Agent': _agen,
    'Accept': 'application/json',
  };

  /// Koordinat → alamat terbaca, mis. "Jalan Mawar No. 12, Klojen, Kota Malang".
  Future<HasilGeocoding?> balikArah({
    required double lintang,
    required double bujur,
  }) async {
    final uri = Uri.parse('$_akar/reverse').replace(
      queryParameters: {
        'lat': lintang.toStringAsFixed(6),
        'lon': bujur.toStringAsFixed(6),
        'format': 'jsonv2',
        'accept-language': 'id',
      },
    );

    try {
      final respons = await http.get(uri, headers: _header).timeout(_batasWaktu);
      if (respons.statusCode != 200) return null;

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
    } catch (_) {
      return null;
    }
  }

  /// Alamat → titik koordinat terdekat, supaya peta mengikuti ketikan manual.
  ///
  /// Nominatim sering tidak menemukan hasil bila nomor rumah yang diketik
  /// tidak ada di data OpenStreetMap, jadi kueri dicoba ulang dengan versi
  /// yang semakin ringkas sampai ada hasil.
  Future<HasilGeocoding?> cariAlamat(String teks) async {
    final kueri = teks.trim();
    if (kueri.isEmpty) return null;

    final kandidat = _kandidatKueri(kueri);
    for (var urutan = 0; urutan < kandidat.length; urutan++) {
      if (urutan > 0) {
        // Kebijakan Nominatim: maksimum ±1 permintaan per detik.
        await Future<void>.delayed(const Duration(milliseconds: 1100));
      }
      final hasil = await _kirimCari(kandidat[urutan]);
      if (hasil != null) return hasil;
    }
    return null;
  }

  /// Daftar kueri yang dicoba berurutan: alamat lengkap, tanpa nomor rumah,
  /// lalu hanya segmen jalan/kota pertamanya.
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

  Future<HasilGeocoding?> _kirimCari(String kueri) async {
    final uri = Uri.parse('$_akar/search').replace(
      queryParameters: {
        'q': kueri,
        'format': 'jsonv2',
        'limit': '1',
        'accept-language': 'id',
      },
    );

    try {
      final respons = await http.get(uri, headers: _header).timeout(_batasWaktu);
      if (respons.statusCode != 200) return null;

      final isi = jsonDecode(respons.body);
      if (isi is! List || isi.isEmpty || isi.first is! Map) return null;

      final pertama = Map<String, dynamic>.from(isi.first as Map);
      final lintang = double.tryParse(pertama['lat']?.toString() ?? '');
      final bujur = double.tryParse(pertama['lon']?.toString() ?? '');
      if (lintang == null || bujur == null) return null;

      final alamat = pertama['display_name']?.toString().trim() ?? '';
      if (alamat.isEmpty) return null;

      return HasilGeocoding(alamat: alamat, lintang: lintang, bujur: bujur);
    } catch (_) {
      return null;
    }
  }

  /// Menyusun alamat rapi dari komponen Nominatim, mis.
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
    final kodePos = komponen['postcode']?.toString().trim();

    final baris = <String>[
      if (barisJalan.isNotEmpty) barisJalan,
      if (kampung != null && kampung != barisJalan) kampung,
      if (kota != null && kota != kampung) kota,
      if (provinsi != null && provinsi != kota)
        kodePos != null && kodePos.isNotEmpty ? '$provinsi $kodePos' : provinsi,
    ];

    final hasil = baris.join(', ');
    return hasil.isEmpty ? cadangan : hasil;
  }
}
