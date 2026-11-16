/// Model metode pembayaran aktif sesuai `GET /api/metode-pembayaran`
/// (PRD Bagian 5 & 6.3). Kode yang dikenal: `xendit_qris`, `xendit_ewallet`,
/// `xendit_va`, dan `xendit_kartu`.
class MetodePembayaran {
  final int id;
  final String kode;
  final String nama;
  final bool aktif;

  const MetodePembayaran({
    required this.id,
    required this.kode,
    required this.nama,
    this.aktif = true,
  });

  factory MetodePembayaran.fromJson(Map<String, dynamic> json) {
    return MetodePembayaran(
      id: _bilangan(json['id']),
      kode: json['kode']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      aktif: _boole(json['aktif'], nilaiAwal: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kode': kode,
        'nama': nama,
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
