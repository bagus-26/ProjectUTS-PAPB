/// Pemformat rupiah untuk seluruh tampilan aplikasi.
///
/// Hanya memformat **penampilan** angka; tidak pernah menghitung uang.
/// Seluruh nilai uang (harga, subtotal, ongkir, total) berasal dari server
/// sesuai pagar pengaman PRD Bagian 4.3 butir 1.
///
/// Contoh: `18000` → `Rp 18.000`
String formatRupiah(int nilai) {
  final teks = nilai.abs().toString();
  final hasil = StringBuffer();

  for (var i = 0; i < teks.length; i++) {
    if (i > 0 && (teks.length - i) % 3 == 0) {
      hasil.write('.');
    }
    hasil.write(teks[i]);
  }

  return '${nilai < 0 ? '-' : ''}Rp $hasil';
}
