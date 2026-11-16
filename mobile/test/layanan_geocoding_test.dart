import 'package:flutter_test/flutter_test.dart';
import 'package:projek_makanyuk/layanan/layanan_geocoding.dart';

/// Uji jaringan nyata ke Nominatim (utama) dan Photon (cadangan).
/// Dibatalkan otomatis bila tidak ada koneksi internet.
void main() {
  const geocoding = LayananGeocoding();

  test('koordinat → alamat (mode otomatis)', () async {
    final hasil = await geocoding.balikArah(lintang: -7.9666, bujur: 112.6326);
    // ignore: avoid_print
    print('REVERSE: ${hasil?.alamat}');
    expect(hasil, isNotNull);
    expect(hasil!.alamat, isNotEmpty);
    expect(
      hasil.alamat.contains(RegExp(r'-?\d+\.\d+')),
      isFalse,
      reason: 'hasil harus alamat, bukan koordinat',
    );
  }, timeout: const Timeout(Duration(seconds: 40)));

  test('alamat → koordinat (mode manual)', () async {
    final hasil = await geocoding.cariAlamat('Jl. Ijen, Klojen, Malang');
    // ignore: avoid_print
    print('SEARCH : ${hasil?.alamat}');
    expect(hasil, isNotNull);
    expect(hasil!.alamat, isNotEmpty);
  }, timeout: const Timeout(Duration(seconds: 45)));
}
