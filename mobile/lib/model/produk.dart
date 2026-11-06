/// Model data Produk Makanan & Minuman Siap Saji (Kelompok 1)
/// Sesuai kontrak basis data dan atribut khas domain
class Produk {
  final int id;
  final String nama;
  final int harga;
  final String kategori;
  final int stok;
  final bool tersedia;
  final String? deskripsi;

  // Atribut Khas Domain Kelompok 1 (Makanan & Minuman)
  final List<String> varianPorsi;
  final List<String> tingkatKepedasan;
  final String? catatan;

  // Atribut pendukung visual UI
  final String? gambar;
  final double rating;
  final String terjual;
  final int hargaTambahanLarge;

  const Produk({
    required this.id,
    required this.nama,
    required this.harga,
    required this.kategori,
    required this.stok,
    required this.tersedia,
    this.deskripsi,
    this.varianPorsi = const ['Reguler', 'Large'],
    this.tingkatKepedasan = const ['Tidak Pedas', 'Sedang', 'Pedas', 'Extra Pedas'],
    this.catatan,
    this.gambar,
    this.rating = 4.8,
    this.terjual = '100+',
    this.hargaTambahanLarge = 5000,
  });

  /// Cek apakah produk siap dipesan (stok > 0 dan berstatus tersedia)
  bool get dapatDipesan => tersedia && stok > 0;

  /// Konversi dari JSON response server Laravel
  factory Produk.fromJson(Map<String, dynamic> json) {
    // Parse ID
    final idRaw = json['id'];
    final id = idRaw is int
        ? idRaw
        : int.tryParse(idRaw?.toString() ?? '') ?? 0;

    // Parse Nama & Kategori
    final nama = json['nama']?.toString().trim() ?? 'Menu Tanpa Nama';
    final kategori = json['kategori']?.toString().trim() ?? 'Makanan';

    // Parse Harga & Stok
    final hargaRaw = json['harga'];
    final harga = hargaRaw is int
        ? hargaRaw
        : (hargaRaw is num
            ? hargaRaw.toInt()
            : int.tryParse(hargaRaw?.toString() ?? '') ?? 0);

    final stokRaw = json['stok'];
    final stok = stokRaw is int
        ? stokRaw
        : (stokRaw is num
            ? stokRaw.toInt()
            : int.tryParse(stokRaw?.toString() ?? '') ?? 0);

    // Parse Tersedia
    final tersediaRaw = json['tersedia'];
    final bool tersedia = switch (tersediaRaw) {
      bool b => b,
      int i => i == 1,
      String s => s == '1' || s.toLowerCase() == 'true',
      _ => true,
    };

    // Deskripsi (boleh null sesuai spesifikasi)
    final deskripsi = json['deskripsi']?.toString();

    // Parse Varian Porsi khas Domain 1
    List<String> varianPorsi = const ['Reguler', 'Large'];
    if (json['varian_porsi'] != null) {
      if (json['varian_porsi'] is List) {
        varianPorsi = (json['varian_porsi'] as List)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (json['varian_porsi'] is String) {
        varianPorsi = (json['varian_porsi'] as String)
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    // Parse Tingkat Kepedasan khas Domain 1
    List<String> tingkatKepedasan = const ['Tidak Pedas', 'Sedang', 'Pedas', 'Extra Pedas'];
    if (json['tingkat_kepedasan'] != null) {
      if (json['tingkat_kepedasan'] is List) {
        tingkatKepedasan = (json['tingkat_kepedasan'] as List)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (json['tingkat_kepedasan'] is String) {
        tingkatKepedasan = (json['tingkat_kepedasan'] as String)
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    // Rating & Terjual
    final ratingRaw = json['rating'];
    final rating = ratingRaw is num
        ? ratingRaw.toDouble()
        : double.tryParse(ratingRaw?.toString() ?? '') ?? 4.8;

    final terjual = json['terjual']?.toString() ?? '100+';

    final hargaTambahanLargeRaw = json['harga_tambahan_large'];
    final hargaTambahanLarge = hargaTambahanLargeRaw is int
        ? hargaTambahanLargeRaw
        : int.tryParse(hargaTambahanLargeRaw?.toString() ?? '') ?? 5000;

    return Produk(
      id: id,
      nama: nama,
      harga: harga,
      kategori: kategori,
      stok: stok,
      tersedia: tersedia,
      deskripsi: deskripsi,
      varianPorsi: varianPorsi,
      tingkatKepedasan: tingkatKepedasan,
      catatan: json['catatan']?.toString(),
      gambar: json['gambar']?.toString(),
      rating: rating,
      terjual: terjual,
      hargaTambahanLarge: hargaTambahanLarge,
    );
  }

  /// Konversi ke Map JSON untuk dikirim ke API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'harga': harga,
      'kategori': kategori,
      'stok': stok,
      'tersedia': tersedia,
      if (deskripsi != null) 'deskripsi': deskripsi,
      'varian_porsi': varianPorsi,
      'tingkat_kepedasan': tingkatKepedasan,
      if (catatan != null) 'catatan': catatan,
      if (gambar != null) 'gambar': gambar,
      'rating': rating,
      'terjual': terjual,
      'harga_tambahan_large': hargaTambahanLarge,
    };
  }

  Produk copyWith({
    int? id,
    String? nama,
    int? harga,
    String? kategori,
    int? stok,
    bool? tersedia,
    String? deskripsi,
    List<String>? varianPorsi,
    List<String>? tingkatKepedasan,
    String? catatan,
    String? gambar,
    double? rating,
    String? terjual,
    int? hargaTambahanLarge,
  }) {
    return Produk(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      harga: harga ?? this.harga,
      kategori: kategori ?? this.kategori,
      stok: stok ?? this.stok,
      tersedia: tersedia ?? this.tersedia,
      deskripsi: deskripsi ?? this.deskripsi,
      varianPorsi: varianPorsi ?? this.varianPorsi,
      tingkatKepedasan: tingkatKepedasan ?? this.tingkatKepedasan,
      catatan: catatan ?? this.catatan,
      gambar: gambar ?? this.gambar,
      rating: rating ?? this.rating,
      terjual: terjual ?? this.terjual,
      hargaTambahanLarge: hargaTambahanLarge ?? this.hargaTambahanLarge,
    );
  }
}
