import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../konfigurasi/konfigurasi.dart';
import '../model/isi_keranjang.dart';
import '../model/item_keranjang.dart';
import '../model/kurir.dart';
import '../model/metode_pembayaran.dart';
import '../model/pesanan.dart';
import '../model/produk.dart';
import 'galat_api.dart';

/// Satu-satunya kelas yang melakukan pemanggilan HTTP (PRD Bagian 7.5).
///
/// Setiap permintaan melewati [_kirim] yang menerapkan:
/// * batas waktu 10 detik + `Authorization: Bearer` (token diatur di satu tempat),
/// * pembungkus respons seragam `status/code/message/data/errors`,
/// * exception bertipe sesuai matriks penanganan galat PRD Bagian 7.3.
class LayananApi {
  LayananApi();

  static final http.Client _klien = http.Client();

  /// Token statis pelanggan (keputusan D-02). Hanya disebut di sini,
  /// sehingga penggantian ke login JWT cukup mengubah satu berkas.
  static const String _tokenPelanggan = 'kelompok1-token-statis';

  Map<String, String> _header({
    bool membawaBody = false,
    String? kunciIdempoten,
  }) {
    return {
      'Accept': 'application/json',
      if (membawaBody) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $_tokenPelanggan',
      if (kunciIdempoten != null && kunciIdempoten.isNotEmpty)
        'X-Kunci-Idempoten': kunciIdempoten,
    };
  }

  Uri _uri(String jalur, [Map<String, dynamic>? query]) {
    final bersih = jalur.startsWith('/') ? jalur : '/$jalur';
    final parameter = query == null || query.isEmpty
        ? null
        : query.map((kunci, nilai) => MapEntry(kunci, nilai.toString()));

    return Uri.parse('${Konfigurasi.baseUrl}$bersih').replace(
      queryParameters: parameter,
    );
  }

  /// Jalur pengiriman tunggal untuk seluruh endpoint.
  Future<dynamic> kirim(
    String metode,
    String jalur, {
    Map<String, dynamic>? query,
    Object? body,
    String? kunciIdempoten,
  }) async {
    final uri = _uri(jalur, query);
    final header = _header(
      membawaBody: body != null,
      kunciIdempoten: kunciIdempoten,
    );
    final isiBody = body == null ? null : jsonEncode(body);
    final batas = Konfigurasi.batasWaktu;

    try {
      final http.Response respons;
      switch (metode) {
        case 'POST':
          respons = await _klien
              .post(uri, headers: header, body: isiBody)
              .timeout(batas);
        case 'PUT':
          respons = await _klien
              .put(uri, headers: header, body: isiBody)
              .timeout(batas);
        case 'PATCH':
          respons = await _klien
              .patch(uri, headers: header, body: isiBody)
              .timeout(batas);
        case 'DELETE':
          respons = await _klien.delete(uri, headers: header).timeout(batas);
        default:
          respons = await _klien.get(uri, headers: header).timeout(batas);
      }

      return _prosesRespons(respons);
    } on TimeoutException {
      throw GalatApi.batasWaktu();
    } on SocketException {
      throw GalatApi.tidakAdaSambungan();
    } on http.ClientException {
      throw GalatApi.tidakAdaSambungan();
    } on GalatApi {
      rethrow;
    } catch (_) {
      throw GalatApi.umum();
    }
  }

  /// Membaca pembungkus respons dan melempar exception bertipe (PRD Bagian 6.2).
  dynamic _prosesRespons(http.Response respons) {
    Map<String, dynamic> isi = {};
    try {
      final hasil = jsonDecode(respons.body);
      if (hasil is Map<String, dynamic>) {
        isi = hasil;
      }
    } catch (_) {
      // Bukan JSON sah; penentuan galat tetap memakai kode status.
    }

    final kode = respons.statusCode;
    final pesan = isi['message']?.toString();

    if (kode == 200 || kode == 201) {
      return isi['data'];
    }

    if (kode == 401) {
      throw GalatApi.aksesDitolak();
    }

    if (kode == 404) {
      throw GalatApi.tidakDitemukan(pesan);
    }

    if (kode == 409) {
      final data = isi['data'];
      throw GalatApi.bentrok(
        pesan ?? 'Permintaan bertentangan dengan keadaan server.',
        data: data is Map ? Map<String, dynamic>.from(data) : null,
      );
    }

    if (kode == 422) {
      final rincian = <String, List<String>>{};
      final errors = isi['errors'];
      if (errors is Map) {
        errors.forEach((kunci, nilai) {
          rincian[kunci.toString()] = nilai is List
              ? nilai.map((item) => item.toString()).toList()
              : [nilai.toString()];
        });
      }

      throw GalatApi.validasi(
        pesan: pesan ?? 'Data yang dikirim tidak lengkap.',
        errors: rincian,
      );
    }

    if (kode >= 500) {
      throw GalatApi.galatServer();
    }

    throw GalatApi.umum(pesan);
  }

  List<Map<String, dynamic>> _daftar(dynamic data) {
    if (data is! List) return [];

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // -------------------------------------------------------------
  // Produk (A1)
  // -------------------------------------------------------------

  /// `GET /api/produk?kategori=&cari=` — kosong tetap 200 dengan `data: []`.
  Future<List<Produk>> ambilDaftarProduk({String? kategori, String? cari}) async {
    final data = await kirim(
      'GET',
      '/produk',
      query: {
        if (kategori != null && kategori.isNotEmpty && kategori != 'Semua')
          'kategori': kategori,
        if (cari != null && cari.trim().isNotEmpty) 'cari': cari.trim(),
      },
    );

    return _daftar(data).map(Produk.fromJson).toList();
  }

  /// `GET /api/produk/{id}` — 404 → `GalatTidakDitemukan`.
  Future<Produk> ambilRincianProduk(int id) async {
    final data = await kirim('GET', '/produk/$id');
    if (data is! Map) {
      throw GalatApi.tidakDitemukan();
    }

    return Produk.fromJson(Map<String, dynamic>.from(data));
  }

  /// `POST /api/produk` — 201 saat berhasil, 422 per kolom saat gagal.
  Future<Produk> tambahProduk({
    required String nama,
    required int harga,
    required String kategori,
    required int stok,
    required bool tersedia,
    String? deskripsi,
    required bool bisaPedas,
    required int waktuPersiapanMenit,
  }) async {
    final data = await kirim(
      'POST',
      '/produk',
      body: {
        'nama': nama,
        'harga': harga,
        'kategori': kategori,
        'stok': stok,
        'tersedia': tersedia,
        'deskripsi': deskripsi,
        'bisa_pedas': bisaPedas,
        'waktu_persiapan_menit': waktuPersiapanMenit,
      },
    );

    return Produk.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// `PUT /api/produk/{id}` — 404 bila tidak ada, 422 per kolom.
  Future<Produk> ubahProduk({
    required int id,
    required String nama,
    required int harga,
    required String kategori,
    required int stok,
    required bool tersedia,
    String? deskripsi,
    required bool bisaPedas,
    required int waktuPersiapanMenit,
  }) async {
    final data = await kirim(
      'PUT',
      '/produk/$id',
      body: {
        'nama': nama,
        'harga': harga,
        'kategori': kategori,
        'stok': stok,
        'tersedia': tersedia,
        'deskripsi': deskripsi,
        'bisa_pedas': bisaPedas,
        'waktu_persiapan_menit': waktuPersiapanMenit,
      },
    );

    return Produk.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// `DELETE /api/produk/{id}` — 409 bila produk masih dipakai pesanan aktif.
  Future<void> hapusProduk(int id) async {
    await kirim('DELETE', '/produk/$id');
  }

  /// `GET /api/kategori` — daftar kategori untuk chip filter.
  Future<List<String>> ambilKategori() async {
    final data = await kirim('GET', '/kategori');

    return _daftar(data)
        .map((item) => (item['nama'] ?? item['kategori'])?.toString() ?? '')
        .where((nama) => nama.isNotEmpty)
        .toList();
  }

  // -------------------------------------------------------------
  // Keranjang (A2)
  // -------------------------------------------------------------

  /// `GET /api/keranjang?kurir_id=` — items + jumlah_item + ringkasan.
  Future<IsiKeranjang> ambilKeranjang({int? kurirId}) async {
    final data = await kirim(
      'GET',
      '/keranjang',
      query: kurirId == null ? null : {'kurir_id': kurirId},
    );

    return IsiKeranjang.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  }

  /// `POST /api/keranjang` — 201 (baris baru maupun hasil penggabungan, D-07).
  /// 409 bila stok kurang atau produk tidak tersedia.
  Future<ItemKeranjang> tambahKeKeranjang({
    required int produkId,
    required int jumlah,
    int? varianId,
    String? tingkatPedas,
    String? catatan,
  }) async {
    final data = await kirim(
      'POST',
      '/keranjang',
      body: {
        'produk_id': produkId,
        'jumlah': jumlah,
        'varian_id': ?varianId,
        'tingkat_pedas': ?tingkatPedas,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      },
    );

    return ItemKeranjang.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  }

  /// `PUT /api/keranjang/{id}` — 422 bila jumlah ≤ 0, 409 bila stok kurang.
  Future<ItemKeranjang> ubahJumlahKeranjang({
    required int id,
    required int jumlah,
  }) async {
    final data = await kirim(
      'PUT',
      '/keranjang/$id',
      body: {'jumlah': jumlah},
    );

    return ItemKeranjang.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  }

  /// `DELETE /api/keranjang/{id}` — 404 bila item sudah tidak ada.
  Future<void> hapusItemKeranjang(int id) async {
    await kirim('DELETE', '/keranjang/$id');
  }

  // -------------------------------------------------------------
  // Referensi (A3)
  // -------------------------------------------------------------

  /// `GET /api/kurir` — kurir internal beserta tarifnya.
  Future<List<Kurir>> ambilKurir() async {
    final data = await kirim('GET', '/kurir');

    return _daftar(data).map(Kurir.fromJson).toList();
  }

  /// `GET /api/metode-pembayaran` — metode simulasi pembayaran.
  Future<List<MetodePembayaran>> ambilMetodePembayaran() async {
    final data = await kirim('GET', '/metode-pembayaran');

    return _daftar(data).map(MetodePembayaran.fromJson).toList();
  }

  // -------------------------------------------------------------
  // Checkout (A2)
  // -------------------------------------------------------------

  /// `POST /api/checkout` dengan header `X-Kunci-Idempoten` (PRD Bagian 7.4).
  ///
  /// 201 → pesanan baru; 409 → toko tutup / stok kurang / keranjang kosong;
  /// 422 → validasi per kolom.
  Future<Pesanan> buatCheckout({
    required String namaPenerima,
    required String alamatPenerima,
    required int kurirId,
    required String metodePembayaran,
    required String kunciIdempoten,
  }) async {
    final data = await kirim(
      'POST',
      '/checkout',
      kunciIdempoten: kunciIdempoten,
      body: {
        'nama_penerima': namaPenerima,
        'alamat_penerima': alamatPenerima,
        'kurir_id': kurirId,
        'metode_pembayaran': metodePembayaran,
      },
    );

    return Pesanan.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  }

  // -------------------------------------------------------------
  // Pesanan (A3)
  // -------------------------------------------------------------

  /// `GET /api/pesanan` — riwayat, terbaru dahulu (diatur server).
  Future<List<Pesanan>> ambilDaftarPesanan() async {
    final data = await kirim('GET', '/pesanan');

    return _daftar(data).map(Pesanan.fromJson).toList();
  }

  /// `GET /api/pesanan/{id}` — rincian + item dengan harga saat beli.
  Future<Pesanan> ambilRincianPesanan(int id) async {
    final data = await kirim('GET', '/pesanan/$id');
    if (data is! Map) {
      throw GalatApi.tidakDitemukan();
    }

    return Pesanan.fromJson(Map<String, dynamic>.from(data));
  }

  /// `PATCH /api/pesanan/{id}/status` — hanya transisi sah (PRD Bagian 6.7).
  /// 409 bila transisi tidak sah, 422 bila nilai status tidak dikenal.
  Future<Pesanan> ubahStatusPesanan({
    required int id,
    required String status,
  }) async {
    final data = await kirim(
      'PATCH',
      '/pesanan/$id/status',
      body: {'status': status},
    );

    return Pesanan.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  }

  // -------------------------------------------------------------
  // Permintaan generik (dipakai halaman pendukung)
  // -------------------------------------------------------------

  Future<dynamic> ambil(String jalur) => kirim('GET', jalur);
}
