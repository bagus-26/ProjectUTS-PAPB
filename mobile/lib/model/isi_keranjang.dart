import 'item_keranjang.dart';
import 'ringkasan_keranjang.dart';

/// Bentuk lengkap respons `GET /api/keranjang` (PRD Bagian 6.5):
/// `items`, `jumlah_item`, dan `ringkasan`.
class IsiKeranjang {
  final List<ItemKeranjang> items;
  final int jumlahItem;
  final RingkasanKeranjang ringkasan;

  const IsiKeranjang({
    required this.items,
    required this.jumlahItem,
    required this.ringkasan,
  });

  bool get kosong => items.isEmpty;

  factory IsiKeranjang.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];

    return IsiKeranjang(
      items: itemsRaw is List
          ? itemsRaw
                .whereType<Map>()
                .map((item) =>
                    ItemKeranjang.fromJson(Map<String, dynamic>.from(item)))
                .toList()
          : <ItemKeranjang>[],
      jumlahItem: _bilangan(json['jumlah_item']),
      ringkasan: json['ringkasan'] is Map
          ? RingkasanKeranjang.fromJson(
              Map<String, dynamic>.from(json['ringkasan'] as Map),
            )
          : const RingkasanKeranjang(subtotal: 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((item) => item.toJson()).toList(),
        'jumlah_item': jumlahItem,
        'ringkasan': ringkasan.toJson(),
      };
}

int _bilangan(dynamic nilai) {
  if (nilai is int) return nilai;
  if (nilai is num) return nilai.toInt();

  return int.tryParse(nilai?.toString() ?? '') ?? 0;
}
