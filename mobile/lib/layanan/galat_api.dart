class GalatApi implements Exception {
  const GalatApi(this.pesan);

  final String pesan;

  @override
  String toString() => pesan;
}

class GalatSambungan extends GalatApi {
  const GalatSambungan() : super('Sambungan ke server gagal.');
}

class GalatBatasWaktu extends GalatApi {
  const GalatBatasWaktu() : super('Server tidak membalas. Silakan coba lagi.');
}

class GalatValidasi extends GalatApi {
  const GalatValidasi(super.pesan, this.errors);

  final Map<String, List<String>> errors;
}

class GalatBentrok extends GalatApi {
  const GalatBentrok(super.pesan, this.data);

  final Map<String, dynamic>? data;
}

class GalatServer extends GalatApi {
  const GalatServer() : super('Terjadi kesalahan pada server.');
}

class GalatTidakDitemukan extends GalatApi {
  const GalatTidakDitemukan() : super('Data tidak ditemukan.');
}

class GalatUmum extends GalatApi {
  const GalatUmum(super.pesan);
}
