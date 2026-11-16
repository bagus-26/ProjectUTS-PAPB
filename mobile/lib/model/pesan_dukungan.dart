/// Satu pesan pada percakapan CS (`support_messages`).
///
/// `sender_role` bernilai `user` untuk pesan pelanggan dan `admin` untuk
/// balasan CS. Halaman bantuan menyegarkan daftar ini setiap 5 detik.
class PesanDukungan {
  final int id;
  final String peranPengirim;
  final String pesan;
  final bool sudahDibaca;
  final String? dibuatPada;

  const PesanDukungan({
    required this.id,
    required this.peranPengirim,
    required this.pesan,
    this.sudahDibaca = false,
    this.dibuatPada,
  });

  bool get dariAdmin => peranPengirim == 'admin';

  String get waktu {
    final teks = dibuatPada;
    if (teks == null || teks.isEmpty) return '';
    final waktu = DateTime.tryParse(teks);
    if (waktu == null) return '';
    final lokal = waktu.toLocal();
    final jam = lokal.hour.toString().padLeft(2, '0');
    final menit = lokal.minute.toString().padLeft(2, '0');
    return '$jam:$menit';
  }

  factory PesanDukungan.fromJson(Map<String, dynamic> json) {
    return PesanDukungan(
      id: _bilangan(json['id']),
      peranPengirim: json['sender_role']?.toString() ?? 'user',
      pesan: json['message']?.toString() ?? '',
      sudahDibaca: _boole(json['is_read']),
      dibuatPada: json['created_at']?.toString(),
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
