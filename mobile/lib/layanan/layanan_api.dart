import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../konfigurasi/konfigurasi.dart';
import 'galat_api.dart';

class LayananApi {
  LayananApi({http.Client? klien}) : _klien = klien ?? http.Client();

  final http.Client _klien;

  static const Duration _batasWaktu = Duration(seconds: 10);
  static const String _tokenAktif = 'kelompok1-token-statis';
  static const String tokenPelangganKedua = 'kelompok1-token-statis-2';

  Map<String, String> _header() {
    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_tokenAktif',
    };
  }

  Future<dynamic> ambil(String jalur, {Map<String, String>? query}) {
    final uri = _buatUri(jalur, query);

    return _kirim(() => _klien.get(uri, headers: _header()));
  }

  Future<dynamic> kirim(String jalur, Map<String, dynamic> isi) {
    final uri = _buatUri(jalur);

    return _kirim(
      () => _klien.post(uri, headers: _header(), body: jsonEncode(isi)),
    );
  }

  Future<dynamic> ubah(String jalur, Map<String, dynamic> isi) {
    final uri = _buatUri(jalur);

    return _kirim(
      () => _klien.put(uri, headers: _header(), body: jsonEncode(isi)),
    );
  }

  Future<dynamic> ubahSebagian(String jalur, Map<String, dynamic> isi) {
    final uri = _buatUri(jalur);

    return _kirim(
      () => _klien.patch(uri, headers: _header(), body: jsonEncode(isi)),
    );
  }

  Future<dynamic> hapus(String jalur) {
    final uri = _buatUri(jalur);

    return _kirim(() => _klien.delete(uri, headers: _header()));
  }

  Future<dynamic> _kirim(Future<http.Response> Function() permintaan) async {
    try {
      final respons = await permintaan().timeout(_batasWaktu);

      return _bacaRespons(respons);
    } on TimeoutException {
      throw const GalatBatasWaktu();
    } on SocketException {
      throw const GalatSambungan();
    } on http.ClientException {
      throw const GalatSambungan();
    }
  }

  dynamic _bacaRespons(http.Response respons) {
    Map<String, dynamic>? isi;

    try {
      final teks = utf8.decode(respons.bodyBytes, allowMalformed: true);
      final terurai = jsonDecode(teks);

      if (terurai is Map<String, dynamic>) {
        isi = terurai;
      }
    } on FormatException {
      isi = null;
    }

    final kode = respons.statusCode;

    if (kode >= 200 && kode < 300) {
      if (isi == null) {
        throw const GalatServer();
      }

      return isi['data'];
    }

    final pesanMentah = isi?['message'];
    final pesan = pesanMentah is String
        ? pesanMentah
        : 'Terjadi kesalahan pada permintaan.';

    switch (kode) {
      case 401:
        throw const GalatUmum('Akses ditolak. Periksa token pelanggan.');
      case 404:
        throw const GalatTidakDitemukan();
      case 409:
        final data = isi?['data'];
        throw GalatBentrok(
          pesan,
          data is Map<String, dynamic> ? data : null,
        );
      case 422:
        throw GalatValidasi(pesan, _bacaErrors(isi?['errors']));
    }

    if (kode >= 500) {
      throw const GalatServer();
    }

    throw GalatUmum(pesan);
  }

  Map<String, List<String>> _bacaErrors(dynamic errors) {
    if (errors is! Map) {
      return const <String, List<String>>{};
    }

    final hasil = <String, List<String>>{};

    errors.forEach((kunci, nilai) {
      if (nilai is List) {
        hasil[kunci.toString()] = nilai.map((item) => item.toString()).toList();
      } else if (nilai != null) {
        hasil[kunci.toString()] = <String>[nilai.toString()];
      }
    });

    return hasil;
  }

  Uri _buatUri(String jalur, [Map<String, String>? query]) {
    final bersih = jalur.startsWith('/') ? jalur.substring(1) : jalur;
    final uri = Uri.parse('${Konfigurasi.baseUrl}/$bersih');

    if (query == null || query.isEmpty) {
      return uri;
    }

    return uri.replace(queryParameters: query);
  }
}
