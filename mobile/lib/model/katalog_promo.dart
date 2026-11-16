import 'promo.dart';
import 'voucher_pelanggan.dart';

/// Ringkasan halaman Promo & Tukar Poin: saldo poin, katalog promo, dan
/// voucher yang sudah dimiliki pelanggan.
class KatalogPromo {
  final int poin;
  final List<Promo> promos;
  final List<VoucherPelanggan> vouchers;

  const KatalogPromo({
    this.poin = 0,
    this.promos = const [],
    this.vouchers = const [],
  });

  List<VoucherPelanggan> get voucherAktif =>
      vouchers.where((item) => item.aktif).toList(growable: false);

  bool sudahDimiliki(int promoId) =>
      vouchers.any((voucher) => voucher.promoId == promoId);

  factory KatalogPromo.fromJson(Map<String, dynamic> json) {
    final promosRaw = json['promos'];
    final vouchersRaw = json['vouchers'];

    return KatalogPromo(
      poin: _bilangan(json['poin']),
      promos: promosRaw is List
          ? promosRaw
              .whereType<Map>()
              .map((item) => Promo.fromJson(Map<String, dynamic>.from(item)))
              .toList(growable: false)
          : const [],
      vouchers: vouchersRaw is List
          ? vouchersRaw
              .whereType<Map>()
              .map((item) =>
                  VoucherPelanggan.fromJson(Map<String, dynamic>.from(item)))
              .toList(growable: false)
          : const [],
    );
  }
}

int _bilangan(dynamic nilai) {
  if (nilai is int) return nilai;
  if (nilai is num) return nilai.toInt();

  return int.tryParse(nilai?.toString() ?? '') ?? 0;
}

/// Hasil klaim kode atau penukaran poin: saldo poin terbaru + voucher baru.
class HasilTukarPromo {
  final int poin;
  final VoucherPelanggan voucher;

  const HasilTukarPromo({required this.poin, required this.voucher});

  factory HasilTukarPromo.fromJson(Map<String, dynamic> json) {
    final voucherRaw = json['voucher'];

    return HasilTukarPromo(
      poin: _bilangan(json['poin']),
      voucher: VoucherPelanggan.fromJson(
        voucherRaw is Map
            ? Map<String, dynamic>.from(voucherRaw)
            : const <String, dynamic>{},
      ),
    );
  }
}
