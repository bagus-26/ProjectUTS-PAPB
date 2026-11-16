import 'promo.dart';

/// Voucher milik pelanggan hasil klaim kode atau penukaran poin.
///
/// Status `active` berarti siap dipakai saat checkout; `used` berarti sudah
/// terpakai pada pesanan yang selesai.
class VoucherPelanggan {
  final int id;
  final int promoId;
  final String status;
  final String? dibuatPada;
  final Promo? promo;

  const VoucherPelanggan({
    required this.id,
    required this.promoId,
    this.status = 'active',
    this.dibuatPada,
    this.promo,
  });

  bool get aktif => status == 'active';

  String get labelStatus => switch (status) {
        'active' => 'Siap dipakai',
        'used' => 'Sudah dipakai',
        _ => status,
      };

  factory VoucherPelanggan.fromJson(Map<String, dynamic> json) {
    final promoRaw = json['promo'];

    return VoucherPelanggan(
      id: _bilangan(json['id']),
      promoId: _bilangan(json['promo_id']),
      status: json['status']?.toString() ?? 'active',
      dibuatPada: json['created_at']?.toString(),
      promo: promoRaw is Map
          ? Promo.fromJson(Map<String, dynamic>.from(promoRaw))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'promo_id': promoId,
        'status': status,
        'created_at': dibuatPada,
        'promo': promo?.toJson(),
      };
}

int _bilangan(dynamic nilai) {
  if (nilai is int) return nilai;
  if (nilai is num) return nilai.toInt();

  return int.tryParse(nilai?.toString() ?? '') ?? 0;
}
