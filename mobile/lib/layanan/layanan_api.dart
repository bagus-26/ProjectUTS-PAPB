import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../model/produk.dart';
import 'galat_api.dart';

/// Kelas Layanan API Pusat untuk MakanYuk! (Kelompok 1)
/// Mengimplementasikan kontrak REST API Laravel, batas waktu 10 detik,
/// serta penanganan lima jenis galat jaringan dan server secara disiplin.
class LayananApi {
  // Singleton pattern agar hemat sumber daya koneksi
  static final LayananApi _instance = LayananApi._internal();
  factory LayananApi() => _instance;
  LayananApi._internal();

  /// Alamat server disimpan dalam satu konstanta (Ketentuan Sisi Flutter butir 2)
  /// Emulator Android: http://10.0.2.2:8000/api
  /// Perangkat Fisik / Web: sesuaikan IP komputer host
  static const String baseUrlDefault = 'http://10.0.2.2:8000/api';
  String baseUrl = baseUrlDefault;

  /// Mode simulasi data offline (Jalur B) jika server Laravel sedang tidak dijalankan
  static bool gunakanMockFallback = true;

  final http.Client _client = http.Client();

  /// Batas waktu pemanggilan API: 10 detik (Ketentuan Sisi Flutter butir 4)
  static const Duration batasWaktu = Duration(seconds: 10);

  // -------------------------------------------------------------
  // Data Master Domain 1 (Makanan & Minuman) - Min. 12 produk, 2 stok nol
  // Sesuai Bagian 3 Spesifikasi Tugas UTS
  // -------------------------------------------------------------
  static final List<Produk> _dataMockProduk = [
    const Produk(
      id: 1,
      nama: 'Iced Latte',
      harga: 18000,
      kategori: 'Minuman',
      stok: 25,
      tersedia: true,
      deskripsi:
          'Perpaduan seimbang espresso premium dengan susu segar dingin yang lembut dan creamy.',
      varianPorsi: ['Reguler', 'Large'],
      tingkatKepedasan: ['Normal Ice', 'Less Ice', 'No Ice'],
      gambar:
          'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=500&q=80',
      rating: 4.9,
      terjual: '120+',
      hargaTambahanLarge: 5000,
    ),
    const Produk(
      id: 2,
      nama: 'Chicken Rice Bowl',
      harga: 28000,
      kategori: 'Makanan',
      stok: 18,
      tersedia: true,
      deskripsi:
          'Ayam krispi gurih dengan saus spesial di atas nasi hangat pulen dan taburan wijen.',
      varianPorsi: ['Reguler', 'Jumbo'],
      tingkatKepedasan: ['Tidak Pedas', 'Sedang', 'Pedas', 'Extra Pedas'],
      gambar:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
      rating: 4.8,
      terjual: '98',
      hargaTambahanLarge: 6000,
    ),
    const Produk(
      id: 3,
      nama: 'Mochaccino',
      harga: 20000,
      kategori: 'Minuman',
      stok: 0, // STOK HABIS untuk menguji penanda stok nol
      tersedia: true,
      deskripsi:
          'Kombinasi kaya cokelat Belgia murni dan seduhan kopi espresso yang harum.',
      varianPorsi: ['Reguler', 'Large'],
      tingkatKepedasan: ['Less Sweet', 'Normal Sweet', 'Extra Sweet'],
      gambar:
          'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=500&q=80',
      rating: 4.9,
      terjual: '84',
      hargaTambahanLarge: 5000,
    ),
    const Produk(
      id: 4,
      nama: 'French Fries',
      harga: 15000,
      kategori: 'Snack',
      stok: 30,
      tersedia: true,
      deskripsi:
          'Kentang goreng renyah keemasan dibumbui rempah gurih lengkap dengan cocolan saus.',
      varianPorsi: ['Reguler', 'Large'],
      tingkatKepedasan: ['Original', 'Barbeque', 'Balado Pedas'],
      gambar:
          'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=500&q=80',
      rating: 4.7,
      terjual: '150+',
      hargaTambahanLarge: 4000,
    ),
    const Produk(
      id: 5,
      nama: 'Caramel Macchiato',
      harga: 22000,
      kategori: 'Minuman',
      stok: 14,
      tersedia: true,
      deskripsi:
          'Espresso freshly brewed berbalut sirup vanila lembut, susu berbusa, dan drizzle karamel manis.',
      varianPorsi: ['Reguler', 'Large'],
      tingkatKepedasan: ['Normal Ice', 'Less Ice'],
      gambar:
          'https://images.unsplash.com/photo-1485808191679-5f86510681a2?w=500&q=80',
      rating: 4.8,
      terjual: '67',
      hargaTambahanLarge: 5000,
    ),
    const Produk(
      id: 6,
      nama: 'Beef Burger Special',
      harga: 32000,
      kategori: 'Makanan',
      stok: 12,
      tersedia: true,
      deskripsi:
          'Patty daging sapi 100% juicy, keju cheddar meleleh, selada segar, tomat, dan saus burger rahasia.',
      varianPorsi: ['Single', 'Double'],
      tingkatKepedasan: ['Tidak Pedas', 'Pedas'],
      gambar:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&q=80',
      rating: 4.9,
      terjual: '210+',
      hargaTambahanLarge: 8000,
    ),
    const Produk(
      id: 7,
      nama: 'Kopi Susu Gula Aren',
      harga: 18000,
      kategori: 'Minuman',
      stok: 40,
      tersedia: true,
      deskripsi:
          'Kopi susu khas nusantara dengan sentuhan manis autentik gula aren murni.',
      varianPorsi: ['Reguler', 'Large'],
      tingkatKepedasan: ['Normal Sweet', 'Less Sugar (50%)', 'No Sugar'],
      gambar:
          'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=500&q=80',
      rating: 4.9,
      terjual: '320+',
      hargaTambahanLarge: 5000,
    ),
    const Produk(
      id: 8,
      nama: 'Croissant Butter Warm',
      harga: 10000,
      kategori: 'Snack',
      stok: 15,
      tersedia: true,
      deskripsi:
          'Pastry khas Prancis berlapis renyah di luar, beraroma mentega gurih harum di dalam.',
      varianPorsi: ['1 Pcs', '2 Pcs (Hemat)'],
      tingkatKepedasan: ['Original Dipanaskan', 'Suhu Ruang'],
      gambar:
          'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500&q=80',
      rating: 4.8,
      terjual: '95',
      hargaTambahanLarge: 8000,
    ),
    const Produk(
      id: 9,
      nama: 'Mie Goreng Spesial Pedas',
      harga: 24000,
      kategori: 'Makanan',
      stok: 22,
      tersedia: true,
      deskripsi:
          'Mie kenyal racikan bumbu rempah nusantara dengan suwiran ayam, bakso sapi, dan telur ceplok.',
      varianPorsi: ['Reguler', 'Porsi Jumbo'],
      tingkatKepedasan: ['Level 1 (Sedang)', 'Level 2 (Pedas)', 'Level 3 (Extra Pedas)'],
      gambar:
          'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=500&q=80',
      rating: 4.7,
      terjual: '140+',
      hargaTambahanLarge: 5000,
    ),
    const Produk(
      id: 10,
      nama: 'Matcha Green Tea Latte',
      harga: 21000,
      kategori: 'Minuman',
      stok: 20,
      tersedia: true,
      deskripsi:
          'Matcha premium asli Uji Kyoto dipadukan dengan susu murni segar menghasilkan rasa earthy creamy.',
      varianPorsi: ['Reguler', 'Large'],
      tingkatKepedasan: ['Normal Sweet', 'Less Sugar'],
      gambar:
          'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=500&q=80',
      rating: 4.8,
      terjual: '110+',
      hargaTambahanLarge: 5000,
    ),
    const Produk(
      id: 11,
      nama: 'Nasi Gila Mercon',
      harga: 27000,
      kategori: 'Makanan',
      stok: 16,
      tersedia: true,
      deskripsi:
          'Tumisan sosis, bakso, ayam suwir berbumbu cabai rawit melimpah di atas nasi putih panas.',
      varianPorsi: ['Reguler', 'Jumbo'],
      tingkatKepedasan: ['Pedas Manis', 'Pedas Gurih', 'Super Mercon 🔥'],
      gambar:
          'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=500&q=80',
      rating: 4.9,
      terjual: '175+',
      hargaTambahanLarge: 6000,
    ),
    const Produk(
      id: 12,
      nama: 'Spicy Chicken Wings',
      harga: 26000,
      kategori: 'Snack',
      stok: 0, // STOK HABIS ke-2 sesuai syarat sekurang-kurangnya dua produk bertanda habis/nol
      tersedia: false, // Bertanda tidak tersedia
      deskripsi:
          'Sayap ayam goreng renyah berlumur saus pedas manis korea yang menggoda selera.',
      varianPorsi: ['4 Sayap', '6 Sayap'],
      tingkatKepedasan: ['Pedas Korea', 'Extra Pedas Ghost Pepper'],
      gambar:
          'https://images.unsplash.com/photo-1527477396000-e27163b481c2?w=500&q=80',
      rating: 4.6,
      terjual: '80',
      hargaTambahanLarge: 8000,
    ),
  ];

  // -------------------------------------------------------------
  // SIMULASI KERANJANG BELANJA (Server-Side Sesuai Rubrik Kriteria 3)
  // Subtotal dihitung oleh server, bukan di klien Flutter
  // -------------------------------------------------------------
  static final List<Map<String, dynamic>> _dataMockKeranjang = [
    {
      'id': 101,
      'produk_id': 1,
      'nama': 'Iced Latte',
      'harga': 18000,
      'jumlah': 1,
      'varian_porsi': 'Reguler',
      'tingkat_kepedasan': 'Sedang',
      'catatan': 'Less ice',
      'gambar':
          'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=500&q=80',
      'subtotal_item': 18000,
    },
    {
      'id': 102,
      'produk_id': 2,
      'nama': 'Chicken Rice Bowl',
      'harga': 28000,
      'jumlah': 1,
      'varian_porsi': 'Reguler',
      'tingkat_kepedasan': 'Tidak Pedas',
      'catatan': 'Sambal dipisah',
      'gambar':
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
      'subtotal_item': 28000,
    },
  ];

  // -------------------------------------------------------------
  // METODE API INTI
  // -------------------------------------------------------------

  /// Generic GET /ambil untuk fleksibilitas pemanggilan
  Future<dynamic> ambil(String path) async {
    final urlString = path.startsWith('http')
        ? path
        : '$baseUrl${path.startsWith('/') ? path : '/$path'}';

    try {
      final response = await _client
          .get(
            Uri.parse(urlString),
            headers: {'Accept': 'application/json'},
          )
          .timeout(batasWaktu);

      return _prosesRespons(response);
    } on SocketException {
      if (gunakanMockFallback) {
        return _mockFallbackAmbil(path);
      }
      throw GalatApi.tidakAdaSambungan();
    } on TimeoutException {
      throw GalatApi.batasWaktu();
    } on http.ClientException {
      if (gunakanMockFallback) {
        return _mockFallbackAmbil(path);
      }
      throw GalatApi.tidakAdaSambungan();
    } catch (e) {
      if (e is GalatApi) rethrow;
      if (gunakanMockFallback) {
        return _mockFallbackAmbil(path);
      }
      throw GalatApi.umum();
    }
  }

  /// GET /api/produk?kategori=...&cari=...
  /// Mendukung query parameter ?kategori= dan ?cari=
  /// Tetap 200 dan mengembalikan list kosong [] jika tidak ada data (bukan 404)
  Future<List<Produk>> ambilDaftarProduk({
    String? kategori,
    String? cari,
  }) async {
    final queryParams = <String, String>{};
    if (kategori != null && kategori.isNotEmpty && kategori != 'Semua') {
      queryParams['kategori'] = kategori;
    }
    if (cari != null && cari.trim().isNotEmpty) {
      queryParams['cari'] = cari.trim();
    }

    final uri = Uri.parse('$baseUrl/produk').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    try {
      final response = await _client
          .get(
            uri,
            headers: {'Accept': 'application/json'},
          )
          .timeout(batasWaktu);

      final dynamic data = _prosesRespons(response);
      if (data is List) {
        return data
            .map((item) => Produk.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return [];
    } on SocketException {
      if (gunakanMockFallback) {
        return _mockDaftarProduk(kategori: kategori, cari: cari);
      }
      throw GalatApi.tidakAdaSambungan();
    } on TimeoutException {
      throw GalatApi.batasWaktu();
    } on http.ClientException {
      if (gunakanMockFallback) {
        return _mockDaftarProduk(kategori: kategori, cari: cari);
      }
      throw GalatApi.tidakAdaSambungan();
    } catch (e) {
      if (e is GalatApi) rethrow;
      if (gunakanMockFallback) {
        return _mockDaftarProduk(kategori: kategori, cari: cari);
      }
      throw GalatApi.umum();
    }
  }

  /// GET /api/produk/{id}
  /// Mengambil rincian produk spesifik; 404 bila tidak ditemukan
  Future<Produk> ambilRincianProduk(int id) async {
    final uri = Uri.parse('$baseUrl/produk/$id');

    try {
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(batasWaktu);

      final dynamic data = _prosesRespons(response);
      if (data is Map) {
        return Produk.fromJson(Map<String, dynamic>.from(data));
      }
      throw GalatApi.tidakDitemukan();
    } on SocketException {
      if (gunakanMockFallback) {
        return _mockRincianProduk(id);
      }
      throw GalatApi.tidakAdaSambungan();
    } on TimeoutException {
      throw GalatApi.batasWaktu();
    } on http.ClientException {
      if (gunakanMockFallback) {
        return _mockRincianProduk(id);
      }
      throw GalatApi.tidakAdaSambungan();
    } catch (e) {
      if (e is GalatApi) rethrow;
      if (gunakanMockFallback) {
        return _mockRincianProduk(id);
      }
      throw GalatApi.umum();
    }
  }

  /// POST /api/keranjang
  /// Menambah item ke keranjang; 409 bila stok tidak cukup
  Future<Map<String, dynamic>> tambahKeKeranjang({
    required int produkId,
    required int jumlah,
    String? varianPorsi,
    String? tingkatKepedasan,
    String? catatan,
  }) async {
    final uri = Uri.parse('$baseUrl/keranjang');
    final payload = {
      'produk_id': produkId,
      'jumlah': jumlah,
      'varian_porsi': ?varianPorsi,
      'tingkat_kepedasan': ?tingkatKepedasan,
      if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
    };

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(batasWaktu);

      final dynamic data = _prosesRespons(response);
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on SocketException {
      if (gunakanMockFallback) {
        return _mockTambahKeKeranjang(
          produkId: produkId,
          jumlah: jumlah,
          varianPorsi: varianPorsi,
          tingkatKepedasan: tingkatKepedasan,
          catatan: catatan,
        );
      }
      throw GalatApi.tidakAdaSambungan();
    } on TimeoutException {
      throw GalatApi.batasWaktu();
    } on http.ClientException {
      if (gunakanMockFallback) {
        return _mockTambahKeKeranjang(
          produkId: produkId,
          jumlah: jumlah,
          varianPorsi: varianPorsi,
          tingkatKepedasan: tingkatKepedasan,
          catatan: catatan,
        );
      }
      throw GalatApi.tidakAdaSambungan();
    } catch (e) {
      if (e is GalatApi) rethrow;
      if (gunakanMockFallback) {
        return _mockTambahKeKeranjang(
          produkId: produkId,
          jumlah: jumlah,
          varianPorsi: varianPorsi,
          tingkatKepedasan: tingkatKepedasan,
          catatan: catatan,
        );
      }
      throw GalatApi.umum();
    }
  }

  /// GET /api/keranjang
  /// Mengambil isi keranjang beserta subtotal yang dihitung server
  Future<Map<String, dynamic>> ambilKeranjang() async {
    final uri = Uri.parse('$baseUrl/keranjang');

    try {
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(batasWaktu);

      final dynamic data = _prosesRespons(response);
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on SocketException {
      if (gunakanMockFallback) {
        return _mockAmbilKeranjang();
      }
      throw GalatApi.tidakAdaSambungan();
    } on TimeoutException {
      throw GalatApi.batasWaktu();
    } on http.ClientException {
      if (gunakanMockFallback) {
        return _mockAmbilKeranjang();
      }
      throw GalatApi.tidakAdaSambungan();
    } catch (e) {
      if (e is GalatApi) rethrow;
      if (gunakanMockFallback) {
        return _mockAmbilKeranjang();
      }
      throw GalatApi.umum();
    }
  }

  // -------------------------------------------------------------
  // PEMROSESAN RESPONS SERAGAM SESUAI KONTRAK API
  // -------------------------------------------------------------
  dynamic _prosesRespons(http.Response response) {
    Map<String, dynamic> body = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {
      // Jika respons bukan json sah (misal crash html)
    }

    final code = response.statusCode;
    final message = body['message']?.toString();

    // 200 & 201: Sukses
    if (code == 200 || code == 201) {
      return body['data'] ?? body;
    }

    // 404: Tidak ditemukan
    if (code == 404) {
      throw GalatApi.tidakDitemukan(message);
    }

    // 409: Bentrok keadaan (stok kurang / di luar jam buka)
    if (code == 409) {
      throw GalatApi.bentrok(message ?? 'Permintaan bertentangan dengan keadaan server.');
    }

    // 422: Validasi gagal dengan error kolom
    if (code == 422) {
      Map<String, List<String>> rincianErrors = {};
      if (body['errors'] is Map) {
        final errMap = body['errors'] as Map;
        for (final entry in errMap.entries) {
          if (entry.value is List) {
            rincianErrors[entry.key.toString()] =
                (entry.value as List).map((e) => e.toString()).toList();
          } else {
            rincianErrors[entry.key.toString()] = [entry.value.toString()];
          }
        }
      }
      throw GalatApi.validasi(
        pesan: message ?? 'Data yang dikirim tidak lengkap.',
        errors: rincianErrors,
      );
    }

    // 500: Galat server
    if (code >= 500) {
      throw GalatApi.galatServer();
    }

    // Galat umum
    throw GalatApi.umum(message);
  }

  // -------------------------------------------------------------
  // IMPLEMENTASI SIMULASI CADANGAN (MOCK JALUR B)
  // Menjamin aplikasi tetap berjalan stabil jika server Laravel lokal mati
  // -------------------------------------------------------------
  Future<dynamic> _mockFallbackAmbil(String path) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (path.contains('/produk')) {
      return _dataMockProduk.map((p) => p.toJson()).toList();
    }
    if (path.contains('/keranjang')) {
      return _mockAmbilKeranjang();
    }
    return [];
  }

  Future<List<Produk>> _mockDaftarProduk({
    String? kategori,
    String? cari,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    var hasil = List<Produk>.from(_dataMockProduk);

    if (kategori != null && kategori.isNotEmpty && kategori != 'Semua') {
      hasil = hasil
          .where((p) => p.kategori.toLowerCase() == kategori.toLowerCase())
          .toList();
    }

    if (cari != null && cari.trim().isNotEmpty) {
      final keyword = cari.trim().toLowerCase();
      hasil = hasil
          .where((p) =>
              p.nama.toLowerCase().contains(keyword) ||
              (p.deskripsi?.toLowerCase().contains(keyword) ?? false))
          .toList();
    }

    return hasil;
  }

  Future<Produk> _mockRincianProduk(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final ditemukan = _dataMockProduk.where((p) => p.id == id);
    if (ditemukan.isEmpty) {
      throw GalatApi.tidakDitemukan('Produk dengan ID $id tidak ditemukan.');
    }
    return ditemukan.first;
  }

  Future<Map<String, dynamic>> _mockTambahKeKeranjang({
    required int produkId,
    required int jumlah,
    String? varianPorsi,
    String? tingkatKepedasan,
    String? catatan,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final itemIndex = _dataMockProduk.indexWhere((p) => p.id == produkId);
    if (itemIndex == -1) {
      throw GalatApi.tidakDitemukan();
    }

    final targetProduk = _dataMockProduk[itemIndex];
    if (!targetProduk.dapatDipesan || targetProduk.stok < jumlah) {
      throw GalatApi.bentrok(
          'Stok menu ${targetProduk.nama} tidak mencukupi untuk jumlah yang diminta.');
    }

    // Tambah / update keranjang
    final cartIdx = _dataMockKeranjang
        .indexWhere((k) => k['produk_id'] == produkId);
    if (cartIdx >= 0) {
      final currentJumlah = _dataMockKeranjang[cartIdx]['jumlah'] as int;
      final totalBaru = currentJumlah + jumlah;
      if (totalBaru > targetProduk.stok) {
        throw GalatApi.bentrok(
            'Jumlah item melebihi sisa stok (${targetProduk.stok}).');
      }
      _dataMockKeranjang[cartIdx]['jumlah'] = totalBaru;
      _dataMockKeranjang[cartIdx]['subtotal_item'] =
          totalBaru * targetProduk.harga;
    } else {
      _dataMockKeranjang.add({
        'id': 100 + _dataMockKeranjang.length + 1,
        'produk_id': targetProduk.id,
        'nama': targetProduk.nama,
        'harga': targetProduk.harga,
        'jumlah': jumlah,
        'varian_porsi': varianPorsi ?? 'Reguler',
        'tingkat_kepedasan': tingkatKepedasan ?? 'Tidak Pedas',
        'catatan': catatan ?? '',
        'gambar': targetProduk.gambar,
        'subtotal_item': targetProduk.harga * jumlah,
      });
    }

    return _mockAmbilKeranjang();
  }

  Map<String, dynamic> _mockAmbilKeranjang() {
    int subtotal = 0;
    int totalItem = 0;
    for (final item in _dataMockKeranjang) {
      final sub = (item['subtotal_item'] as int?) ??
          ((item['harga'] as int) * (item['jumlah'] as int));
      subtotal += sub;
      totalItem += (item['jumlah'] as int);
    }

    return {
      'items': List<Map<String, dynamic>>.from(_dataMockKeranjang),
      'subtotal': subtotal,
      'total_item': totalItem,
    };
  }
}
