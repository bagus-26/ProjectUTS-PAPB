
String FormatRupiah(int? nilai){
  final teks = nilai.toString();
  final hasil = StringBuffer();

  for (var i = 0; i < teks.length; i++) {
    if (i > 0 && (teks.length - i) % 3 == 0) {
      hasil.write('.');
    }

    hasil.write(teks[i]);
  }

  return 'Rp $hasil';
}