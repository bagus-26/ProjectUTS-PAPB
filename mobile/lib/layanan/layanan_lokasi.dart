import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LayananLokasi {
  const LayananLokasi();

  static final ValueNotifier<String?> alamatPengirimanNotifier =
      ValueNotifier<String?>(null);
  static final ValueNotifier<String?> namaPenerimaNotifier =
      ValueNotifier<String?>(null);

  static String? get alamatPengirimanPilihan => alamatPengirimanNotifier.value;
  static set alamatPengirimanPilihan(String? nilai) {
    if (alamatPengirimanNotifier.value != nilai) {
      alamatPengirimanNotifier.value = nilai;
    }
  }

  static String? get namaPenerimaPilihan => namaPenerimaNotifier.value;
  static set namaPenerimaPilihan(String? nilai) {
    if (namaPenerimaNotifier.value != nilai) {
      namaPenerimaNotifier.value = nilai;
    }
  }

  Future<Position> ambilPosisiSaatIni() async {
    bool serviceEnabled = false;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      serviceEnabled = true;
    }

    if (!serviceEnabled) {
      throw const LayananLokasiException(
        'Layanan lokasi (GPS) tidak aktif. Silakan aktifkan GPS perangkat lalu coba lagi.',
      );
    }

    var izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) {
      izin = await Geolocator.requestPermission();
    }

    if (izin == LocationPermission.denied) {
      throw const LayananLokasiException(
        'Izin lokasi ditolak. Berikan izin lokasi untuk menggunakan fitur ini.',
      );
    }

    if (izin == LocationPermission.deniedForever) {
      throw const LayananLokasiException(
        'Izin lokasi diblokir permanen. Aktifkan izin lokasi lewat Pengaturan aplikasi.',
      );
    }

    // 1. Coba ambil posisi saat ini dengan akurasi medium (cepat, bekerja di dalam ruangan & emulator)
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 7),
        ),
      );
    } catch (e1) {
      debugPrint(
        '[LayananLokasi] getCurrentPosition medium gagal ($e1), mencoba getLastKnownPosition...',
      );
    }

    // 2. Fallback: gunakan posisi terakhir yang diketahui perangkat (instan)
    try {
      final terakhir = await Geolocator.getLastKnownPosition();
      if (terakhir != null) {
        return terakhir;
      }
    } catch (e2) {
      debugPrint('[LayananLokasi] getLastKnownPosition gagal: $e2');
    }

    // 3. Fallback kedua: coba akurasi rendah (low)
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e3) {
      debugPrint('[LayananLokasi] getCurrentPosition low gagal: $e3');
    }

    throw const LayananLokasiException(
      'Sinyal lokasi/GPS tidak terdeteksi (waktu habis). Pastikan GPS aktif atau Anda dapat mengetuk langsung titik lokasi di peta.',
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
