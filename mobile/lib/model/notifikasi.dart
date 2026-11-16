/// Notifikasi lonceng pelanggan sesuai `GET /api/notifications`.
class Notifikasi {
  final int id;
  final String judul;
  final String pesan;
  final String tipe;
  final bool sudahDibaca;
  final String? dibuatPada;

  const Notifikasi({
    required this.id,
    required this.judul,
    required this.pesan,
    this.tipe = 'umum',
    this.sudahDibaca = false,
    this.dibuatPada,
  });

  factory Notifikasi.fromJson(Map<String, dynamic> json) {
    return Notifikasi(
      id: _bilangan(json['id']),
      judul: json['judul']?.toString() ?? 'Notifikasi',
      pesan: json['pesan']?.toString() ?? '',
      tipe: json['tipe']?.toString() ?? 'umum',
      sudahDibaca: _boole(json['is_read']),
      dibuatPada: json['created_at']?.toString(),
    );
  }
}

/// Bungkus `GET /api/notifications`: jumlah belum dibaca + daftar terbaru.
class DaftarNotifikasi {
  final int jumlahBelumDibaca;
  final List<Notifikasi> items;

  const DaftarNotifikasi({
    this.jumlahBelumDibaca = 0,
    this.items = const [],
  });

  factory DaftarNotifikasi.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];

    return DaftarNotifikasi(
      jumlahBelumDibaca: _bilangan(json['jumlah_belum_dibaca']),
      items: itemsRaw is List
          ? itemsRaw
              .whereType<Map>()
              .map((item) => Notifikasi.fromJson(Map<String, dynamic>.from(item)))
              .toList(growable: false)
          : const [],
    );
  }
}

int _bilangan(dynamic nilai) {
  if (nilai is int) return nilai;
  if (nilai is num) return nilai.toInt();

  return int.tryParse(nilai?.toString() ?? '') ?? 0;
}

bool _boole(dynamic nilai) {
  return switch (nilai) {
    bool b => b,
    int i => i == 1,
    String s => s == '1' || s.toLowerCase() == 'true',
    _ => false,
  };
}
