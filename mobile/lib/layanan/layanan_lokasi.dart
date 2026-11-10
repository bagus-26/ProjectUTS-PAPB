import 'package:geolocator/geolocator.dart';

class LayananLokasi {
  const LayananLokasi();

  static String? alamatPengirimanPilihan;

  Future<Position> ambilPosisiSaatIni() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LayananLokasiException(
        'Aktifkan layanan lokasi perangkat lalu coba lagi.',
      );
    }

    var izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) {
      izin = await Geolocator.requestPermission();
    }

    if (izin == LocationPermission.denied) {
      throw const LayananLokasiException(
        'Izin lokasi ditolak. Izinkan akses lokasi untuk menggunakan fitur ini.',
      );
    }

    if (izin == LocationPermission.deniedForever) {
      throw const LayananLokasiException(
        'Izin lokasi diblokir. Ubah izin aplikasi lewat Pengaturan perangkat.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  Future<String> ambilKoordinatSaatIni() async {
    final posisi = await ambilPosisiSaatIni();
    return 'Lokasi perangkat: ${posisi.latitude.toStringAsFixed(6)}, '
        '${posisi.longitude.toStringAsFixed(6)}';
  }
}

class LayananLokasiException implements Exception {
  final String pesan;

  const LayananLokasiException(this.pesan);

  @override
  String toString() => pesan;
}
