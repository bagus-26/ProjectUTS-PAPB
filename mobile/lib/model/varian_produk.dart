class VarianProduk {
  const VarianProduk({
    required this.id,
    required this.nama,
    required this.tambahanHarga,
  });

  factory VarianProduk.fromJson(Map<String, dynamic> json) {
    return VarianProduk(
      id: _parseInteger(json['id']),
      nama: json['nama']?.toString() ?? '',
      tambahanHarga: _parseInteger(json['tambahan_harga']),
    );
  }

  final int id;
  final String nama;
  final int tambahanHarga;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'tambahan_harga': tambahanHarga,
      };
}

int _parseInteger(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
