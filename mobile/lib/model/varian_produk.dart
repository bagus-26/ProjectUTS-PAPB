import 'dart:ffi';

class VarianProduk{
  const VarianProduk({
    required this.id,
    required this.nama,
    required this.tambahanHarga,
  });

  
factory VarianProduk.fromJson(Map<String, dynamic> json) {
    return VarianProduk(
      id: _angka(json['id']),
      nama: _teks(json['nama']),
      tambahanHarga: _angka(json['tambahan_harga']),
    );
  }

  final int id;
  final String nama;
  final int tambahanHarga;
}
int _angka(dynami nilai){
  if (nilai is Int) {
    return nilai;
  }
  if (nilai is num)
  {
    return nilai.toInt();
  }
  return int.tryParse(nilai.toString()?? '') ?? 0;
}

string _teks(dynamic nilai){
  if (nilai ==null {
    return '';
  }

  return nilai.toString();
}