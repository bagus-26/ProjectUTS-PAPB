/// Profil pelanggan sesuai `GET /api/profil`.
///
/// Berisi identitas kontak, saldo poin reward, jumlah voucher aktif, serta
/// penghitung pesan CS dan notifikasi yang belum dibaca.
class ProfilPelanggan {
  final int id;
  final String nama;
  final String? phone;
  final String? email;
  final int poin;
  final int voucherAktif;
  final int pesanBelumDibaca;
  final int notifikasiBelumDibaca;

  const ProfilPelanggan({
    required this.id,
    required this.nama,
    this.phone,
    this.email,
    this.poin = 0,
    this.voucherAktif = 0,
    this.pesanBelumDibaca = 0,
    this.notifikasiBelumDibaca = 0,
  });

  String get inisial {
    final bersih = nama.trim();
    if (bersih.isEmpty) return 'P';
    return bersih.substring(0, 1).toUpperCase();
  }

  factory ProfilPelanggan.fromJson(Map<String, dynamic> json) {
    return ProfilPelanggan(
      id: _bilangan(json['id']),
      nama: json['nama']?.toString() ?? 'Pelanggan',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      poin: _bilangan(json['poin']),
      voucherAktif: _bilangan(json['voucher_aktif']),
      pesanBelumDibaca: _bilangan(json['pesan_belum_dibaca']),
      notifikasiBelumDibaca: _bilangan(json['notifikasi_belum_dibaca']),
    );
  }
}

int _bilangan(dynamic nilai) {
  if (nilai is int) return nilai;
  if (nilai is num) return nilai.toInt();

  return int.tryParse(nilai?.toString() ?? '') ?? 0;
}
