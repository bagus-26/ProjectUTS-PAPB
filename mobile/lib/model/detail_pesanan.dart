/// Model detail pesanan (snapshot harga saat pembelian) sesuai PRD Bagian 5.
///
/// `harga_satuan`, `nama_produk`, dan `varian_nama` disalin oleh server saat
/// checkout, sehingga pesanan lama tidak berubah ketika harga produk berubah
/// (keputusan D-08).
class DetailPesanan {
  final int id;
  final int? produkId;
  final String namaProduk;
  final String? varianNama;
  final int hargaDasar;
  final int tambahanHarga;
  final int hargaSatuan;
  final int jumlah;
  final int subtotal;
  final String? tingkatPedas;
  final String? catatan;

  const DetailPesanan({
    required this.id,
    this.produkId,
    required this.namaProduk,
    this.varianNama,
    this.hargaDasar = 0,
    this.tambahanHarga = 0,
    required this.hargaSatuan,
    required this.jumlah,
    required this.subtotal,
    this.tingkatPedas,
    this.catatan,
  });

  String? get labelPedas => switch (tingkatPedas) {
    'tidak_pedas' => 'Tidak Pedas',
    'sedang' => 'Sedang',
    'pedas' => 'Pedas',
    'sangat_pedas' => 'Sangat Pedas',
    _ => null,
  };

  factory DetailPesanan.fromJson(Map<String, dynamic> json) {
    return DetailPesanan(
      id: _bilangan(json['id']),
      produkId: json['produk_id'] == null ? null : _bilangan(json['produk_id']),
      namaProduk:
          json['nama_produk']?.toString() ?? json['nama']?.toString() ?? 'Menu',
      varianNama: json['varian_nama']?.toString(),
      hargaDasar: _bilangan(json['harga_dasar']),
      tambahanHarga: _bilangan(json['tambahan_harga']),
      hargaSatuan: _bilangan(json['harga_satuan']),
      jumlah: _bilangan(json['jumlah']),
      subtotal: _bilangan(json['subtotal']),
      tingkatPedas: json['tingkat_pedas']?.toString(),
      catatan: json['catatan']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'produk_id': produkId,
        'nama_produk': namaProduk,
        'varian_nama': varianNama,
        'harga_dasar': hargaDasar,
        'tambahan_harga': tambahanHarga,
        'harga_satuan': hargaSatuan,
        'jumlah': jumlah,
        'subtotal': subtotal,
        'tingkat_pedas': tingkatPedas,
        'catatan': catatan,
      };
}

int _bilangan(dynamic nilai) {
  if (nilai is int) return nilai;
  if (nilai is num) return nilai.toInt();

  return int.tryParse(nilai?.toString() ?? '') ?? 0;
}
