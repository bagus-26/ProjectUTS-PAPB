/// Klasifikasi 5 jenis galat sesuai spesifikasi rubrik Kriteria 6 UTS
enum JenisGalat {
  /// Server mati atau mode pesawat (SocketException)
  tidakAdaSambungan,

  /// Jaringan lambat / batas waktu 10 detik terlampaui (TimeoutException)
  batasWaktu,

  /// Validasi input gagal dari Laravel (HTTP 422)
  validasi,

  /// Bentrok keadaan, misalnya stok habis / penolakan bisnis (HTTP 409)
  bentrok,

  /// Galat internal server Laravel (HTTP 500)
  galatServer,

  /// Sumber daya tidak ditemukan (HTTP 404)
  tidakDitemukan,

  /// Galat tak terduga lainnya
  umum,
}

/// Kelas pengecualian (Exception) untuk menangani galat API secara terstruktur
class GalatApi implements Exception {
  final String pesan;
  final int? kodeStatus;
  final JenisGalat jenis;
  final Map<String, List<String>>? errors;

  const GalatApi({
    required this.pesan,
    required this.jenis,
    this.kodeStatus,
    this.errors,
  });

  /// Galat ketika koneksi internet terputus atau backend tidak menyala
  factory GalatApi.tidakAdaSambungan([String? pesanTambahan]) {
    return GalatApi(
      pesan: pesanTambahan ??
          'Sambungan ke server gagal. Pastikan jaringan internet aktif dan server backend berjalan.',
      jenis: JenisGalat.tidakAdaSambungan,
    );
  }

  /// Galat ketika permintaan melebihi batas waktu (10 detik)
  factory GalatApi.batasWaktu() {
    return const GalatApi(
      pesan:
          'Server tidak membalas dalam batas waktu yang ditentukan. Silakan periksa jaringan dan coba lagi.',
      jenis: JenisGalat.batasWaktu,
      kodeStatus: 408,
    );
  }

  /// Galat validasi 422 dari Laravel dengan daftar error per kolom
  factory GalatApi.validasi({
    String? pesan,
    Map<String, List<String>>? errors,
  }) {
    return GalatApi(
      pesan: pesan ?? 'Data yang dikirimkan tidak valid atau belum lengkap.',
      jenis: JenisGalat.validasi,
      kodeStatus: 422,
      errors: errors,
    );
  }

  /// Galat bentrok status 409 (misal stok habis atau pesanan di luar jam buka)
  factory GalatApi.bentrok(String pesan) {
    return GalatApi(
      pesan: pesan,
      jenis: JenisGalat.bentrok,
      kodeStatus: 409,
    );
  }

  /// Galat server internal 500 (tanpa membocorkan jejak debug / stack trace)
  factory GalatApi.galatServer([String? pesan]) {
    return GalatApi(
      pesan: pesan ??
          'Terjadi masalah pada server. Tim kami sedang menanganinya, silakan coba lagi.',
      jenis: JenisGalat.galatServer,
      kodeStatus: 500,
    );
  }

  /// Galat 404 sumber daya tidak ditemukan
  factory GalatApi.tidakDitemukan([String? pesan]) {
    return GalatApi(
      pesan: pesan ?? 'Menu atau data yang dicari tidak ditemukan.',
      jenis: JenisGalat.tidakDitemukan,
      kodeStatus: 404,
    );
  }

  /// Galat umum lainnya
  factory GalatApi.umum([String? pesan]) {
    return GalatApi(
      pesan: pesan ?? 'Terjadi kesalahan. Silakan coba lagi nanti.',
      jenis: JenisGalat.umum,
    );
  }

  @override
  String toString() => pesan;
}

