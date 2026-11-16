/// Model promo sesuai `GET /api/promos` dan halaman Promo & Tukar Poin.
///
/// Promo dapat diklaim lewat kode (`code`) atau ditukar dengan poin
/// (`point_cost`). Nilai diskon berasal dari server dan tidak dihitung ulang
/// di klien.
class Promo {
  final int id;
  final String kode;
  final String judul;
  final String? deskripsi;
  final String tipeDiskon;
  final int nilaiDiskon;
  final String labelDiskon;
  final int minimalBelanja;
  final int biayaPoin;
  final bool aktif;

  const Promo({
    required this.id,
    required this.kode,
    required this.judul,
    this.deskripsi,
    this.tipeDiskon = 'fixed',
    required this.nilaiDiskon,
    this.labelDiskon = '',
    this.minimalBelanja = 0,
    this.biayaPoin = 0,
    this.aktif = true,
  });

  /// Promo poin dapat ditukar bila biaya poinnya lebih dari nol.
  bool get bisaDitukarPoin => biayaPoin > 0;

  /// Promo kode dapat diklaim gratis bila biaya poinnya nol.
  bool get bisaDiklaimKode => biayaPoin <= 0;

  String get labelTipe =>
      tipeDiskon == 'percent' ? 'Diskon persen' : 'Potongan nominal';

  factory Promo.fromJson(Map<String, dynamic> json) {
    return Promo(
      id: _bilangan(json['id']),
      kode: json['code']?.toString() ?? '',
      judul: json['title']?.toString() ?? 'Promo MakanYuk!',
      deskripsi: json['description']?.toString(),
      tipeDiskon: json['discount_type']?.toString() ?? 'fixed',
      nilaiDiskon: _bilangan(json['discount_value']),
      labelDiskon: json['label_diskon']?.toString() ?? '',
      minimalBelanja: _bilangan(json['min_order']),
      biayaPoin: _bilangan(json['point_cost']),
      aktif: _boole(json['is_active'], nilaiAwal: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': kode,
        'title': judul,
        'description': deskripsi,
        'discount_type': tipeDiskon,
        'discount_value': nilaiDiskon,
        'label_diskon': labelDiskon,
        'min_order': minimalBelanja,
        'point_cost': biayaPoin,
        'is_active': aktif,
      };

  /// Perkiraan potongan untuk pratinjau di klien. Server tetap menghitung
  /// nilai final saat checkout.
  int perkiraanDiskon(int subtotal) {
    if (subtotal <= 0 || subtotal < minimalBelanja) return 0;
    final nilai = tipeDiskon == 'percent'
        ? (subtotal * nilaiDiskon) ~/ 100
        : nilaiDiskon;
    if (nilai <= 0) return 0;
    return nilai > subtotal ? subtotal : nilai;
  }
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
