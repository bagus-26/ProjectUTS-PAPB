import 'varian_produk.dart';

/// Model item keranjang sesuai respons `GET /api/keranjang` (PRD Bagian 6.5).
class ItemKeranjang {
  final int id;
  final int produkId;
  final String nama;
  final VarianProduk? varian;
  final String? tingkatPedas;
  final String? catatan;
  final int hargaSatuan;
  final int jumlah;
  final int subtotal;

  const ItemKeranjang({
    required this.id,
    required this.produkId,
    required this.nama,
    this.varian,
    this.tingkatPedas,
    this.catatan,
    required this.hargaSatuan,
    required this.jumlah,
    required this.subtotal,
  });

  /// Label tingkat pedas untuk tampilan, mis. `tidak_pedas` → `Tidak Pedas`.
  String? get labelPedas => switch (tingkatPedas) {
    'tidak_pedas' => 'Tidak Pedas',
    'sedang' => 'Sedang',
    'pedas' => 'Pedas',
    'sangat_pedas' => 'Sangat Pedas',
    _ => null,
  };

  factory ItemKeranjang.fromJson(Map<String, dynamic> json) {
    final varianRaw = json['varian'];

    return ItemKeranjang(
      id: _bilangan(json['id']),
      produkId: _bilangan(json['produk_id']),
      nama: json['nama']?.toString() ?? 'Menu',
      varian: varianRaw is Map
          ? VarianProduk.fromJson(Map<String, dynamic>.from(varianRaw))
          : null,
      tingkatPedas: json['tingkat_pedas']?.toString(),
      catatan: json['catatan']?.toString(),
      hargaSatuan: _bilangan(json['harga_satuan']),
      jumlah: _bilangan(json['jumlah']),
      subtotal: _bilangan(json['subtotal']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'produk_id': produkId,
        'nama': nama,
        'varian': varian?.toJson(),
        'tingkat_pedas': tingkatPedas,
        'catatan': catatan,
        'harga_satuan': hargaSatuan,
        'jumlah': jumlah,
        'subtotal': subtotal,
      };
}

int _bilangan(dynamic nilai) {
  if (nilai is int) return nilai;
  if (nilai is num) return nilai.toInt();

  return int.tryParse(nilai?.toString() ?? '') ?? 0;
}
