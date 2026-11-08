/// Model kurir internal toko sesuai `GET /api/kurir` (PRD Bagian 5 & 6.3).
class Kurir {
  final int id;
  final String nama;
  final String wilayah;
  final int tarif;
  final bool aktif;

  const Kurir({
    required this.id,
    required this.nama,
    required this.wilayah,
    required this.tarif,
    this.aktif = true,
  });

  factory Kurir.fromJson(Map<String, dynamic> json) {
    return Kurir(
      id: _bilangan(json['id']),
      nama: json['nama']?.toString() ?? 'Kurir',
      wilayah: json['wilayah']?.toString() ?? '',
      tarif: _bilangan(json['tarif']),
      aktif: _boole(json['aktif'], nilaiAwal: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'wilayah': wilayah,
        'tarif': tarif,
        'aktif': aktif,
      };
}

int _bilangan(dynamic nilai) {
  if (nilai is int) return nilai;
  if (nilai is num) return nilai.toInt();

  return int.tryParse(nilai?.toString() ?? '') ?? 0;
}

bool _boole(dynamic nilai, {required bool nilaiAwal}) {
  return switch (nilai) {
    bool b => b,
    int i => i == 1,
    String s => s == '1' || s.toLowerCase() == 'true',
    _ => nilaiAwal,
  };
}
