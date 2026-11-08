/// Model ringkasan belanja sesuai respons `GET /api/keranjang` (PRD Bagian 6.5).
///
/// `ongkos_kirim` dan `total` hanya terisi bila permintaan membawa `?kurir_id=`.
/// Keduanya dihitung **oleh server**; Flutter tidak pernah menjumlahkan sendiri
/// (keputusan D-06 dan pagar pengaman PRD Bagian 4.3 butir 1).
class RingkasanKeranjang {
  final int subtotal;
  final int? ongkosKirim;
  final int? total;

  const RingkasanKeranjang({
    required this.subtotal,
    this.ongkosKirim,
    this.total,
  });

  factory RingkasanKeranjang.fromJson(Map<String, dynamic> json) {
    return RingkasanKeranjang(
      subtotal: _bilangan(json['subtotal']),
      ongkosKirim: json['ongkos_kirim'] == null
          ? null
          : _bilangan(json['ongkos_kirim']),
      total: json['total'] == null ? null : _bilangan(json['total']),
    );
  }

  Map<String, dynamic> toJson() => {
        'subtotal': subtotal,
        'ongkos_kirim': ongkosKirim,
        'total': total,
      };
}

int _bilangan(dynamic nilai) {
  if (nilai is int) return nilai;
  if (nilai is num) return nilai.toInt();

  return int.tryParse(nilai?.toString() ?? '') ?? 0;
}
