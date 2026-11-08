import 'varian_produk.dart';

/// Model Produk sesuai kontrak API v1 (PRD Bagian 6.4).
///
/// Kolom: `id`, `nama`, `harga`, `kategori`, `stok`, `tersedia`,
/// `deskripsi` (boleh null), `bisa_pedas`, `waktu_persiapan_menit`, `varian`.
class Produk {
  final int id;
  final String nama;
  final int harga;
  final String kategori;
  final int stok;
  final bool tersedia;
  final String? deskripsi;
  final bool bisaPedas;
  final int waktuPersiapanMenit;
  final List<VarianProduk> varian;

  const Produk({
    required this.id,
    required this.nama,
    required this.harga,
    required this.kategori,
    required this.stok,
    required this.tersedia,
    this.deskripsi,
    this.bisaPedas = false,
    this.waktuPersiapanMenit = 0,
    this.varian = const [],
  });

  /// Produk dapat dipesan bila berstatus tersedia dan stoknya lebih dari nol.
  /// Ketersediaan akhir tetap diputuskan server (PRD pagar pengaman 1).
  bool get dapatDipesan => tersedia && stok > 0;

  /// Daftar nama varian porsi, mis. `['Reguler', 'Jumbo']`.
  List<String> get varianPorsi =>
      varian.map((item) => item.nama).toList(growable: false);

  VarianProduk? varianDenganNama(String nama) {
    for (final item in varian) {
      if (item.nama == nama) {
        return item;
      }
    }

    return null;
  }

  int? idVarian(String nama) => varianDenganNama(nama)?.id;

  /// Tambahan harga varian yang dipilih. Nilai berasal dari server, bukan hitungan klien.
  int tambahanHargaVarian(String nama) =>
      varianDenganNama(nama)?.tambahanHarga ?? 0;

  factory Produk.fromJson(Map<String, dynamic> json) {
    final varianRaw = json['varian'];
    final varian = varianRaw is List
        ? varianRaw
              .whereType<Map>()
              .map((item) =>
                  VarianProduk.fromJson(Map<String, dynamic>.from(item)))
              .toList()
        : <VarianProduk>[];

    return Produk(
      id: _bilangan(json['id']),
      nama: json['nama']?.toString().trim() ?? 'Menu Tanpa Nama',
      harga: _bilangan(json['harga']),
      kategori: json['kategori']?.toString().trim() ?? 'Makanan',
      stok: _bilangan(json['stok']),
      tersedia: _boole(json['tersedia'], nilaiAwal: true),
      deskripsi: json['deskripsi']?.toString(),
      bisaPedas: _boole(json['bisa_pedas'], nilaiAwal: false),
      waktuPersiapanMenit: _bilangan(json['waktu_persiapan_menit']),
      varian: varian,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'harga': harga,
        'kategori': kategori,
        'stok': stok,
        'tersedia': tersedia,
        'deskripsi': deskripsi,
        'bisa_pedas': bisaPedas,
        'waktu_persiapan_menit': waktuPersiapanMenit,
        'varian': varian.map((item) => item.toJson()).toList(),
      };

  Produk copyWith({
    int? id,
    String? nama,
    int? harga,
    String? kategori,
    int? stok,
    bool? tersedia,
    String? deskripsi,
    bool? bisaPedas,
    int? waktuPersiapanMenit,
    List<VarianProduk>? varian,
  }) {
    return Produk(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      harga: harga ?? this.harga,
      kategori: kategori ?? this.kategori,
      stok: stok ?? this.stok,
      tersedia: tersedia ?? this.tersedia,
      deskripsi: deskripsi ?? this.deskripsi,
      bisaPedas: bisaPedas ?? this.bisaPedas,
      waktuPersiapanMenit: waktuPersiapanMenit ?? this.waktuPersiapanMenit,
      varian: varian ?? this.varian,
    );
  }
}

/// Pembaca angka yang tahan terhadap perbedaan `int`/`num`/`String`.
int _bilangan(dynamic nilai) {
  if (nilai is int) return nilai;
  if (nilai is num) return nilai.toInt();

  return int.tryParse(nilai?.toString() ?? '') ?? 0;
}

/// Pembaca nilai boolean yang tahan terhadap `bool`, `0/1`, dan `"true"/"false"`.
bool _boole(dynamic nilai, {required bool nilaiAwal}) {
  return switch (nilai) {
    bool b => b,
    int i => i == 1,
    String s => s == '1' || s.toLowerCase() == 'true',
    _ => nilaiAwal,
  };
}
