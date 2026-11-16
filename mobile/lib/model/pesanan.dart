import 'detail_pesanan.dart';
import 'pembayaran.dart';
import 'voucher_pelanggan.dart';

/// Status pesanan sesuai state machine PRD Bagian 6.7.
const Set<String> statusSah = {
  'menunggu_pembayaran',
  'menunggu_konfirmasi',
  'dibayar',
  'diproses',
  'dikirim',
  'selesai',
  'dibatalkan',
};

/// Model pesanan sesuai tabel `pesanan` (PRD Bagian 5) dan
/// `GET /api/pesanan/{id}` (PRD Bagian 6.3).
class Pesanan {
  final int id;
  final String nomorPesanan;
  final String status;
  final String namaPenerima;
  final String alamatPenerima;
  final String? phone;
  final String? region;
  final String? streetAddress;
  final String? detailNote;
  final String? label;
  final double? latitude;
  final double? longitude;
  final int subtotal;
  final int? ongkosKirim;
  final int diskon;
  final int total;
  final int poinDiberikan;
  final int? kurirId;
  final String? namaKurir;
  final String? wilayahKurir;
  final String kodeMetode;
  final String? namaMetode;
  final String? dibuatPada;
  final Pembayaran? pembayaran;
  final VoucherPelanggan? voucher;
  final List<DetailPesanan> items;

  const Pesanan({
    required this.id,
    required this.nomorPesanan,
    required this.status,
    required this.namaPenerima,
    required this.alamatPenerima,
    this.phone,
    this.region,
    this.streetAddress,
    this.detailNote,
    this.label,
    this.latitude,
    this.longitude,
    required this.subtotal,
    this.ongkosKirim,
    this.diskon = 0,
    required this.total,
    this.poinDiberikan = 0,
    this.kurirId,
    this.namaKurir,
    this.wilayahKurir,
    this.kodeMetode = '',
    this.namaMetode,
    this.dibuatPada,
    this.pembayaran,
    this.voucher,
    this.items = const [],
  });

  /// Label status untuk tampilan, mis. `menunggu_pembayaran` → `Menunggu Pembayaran`.
  String get labelStatus {
    final kata = status.replaceAll('_', ' ');
    if (kata.isEmpty) return status;

    return kata[0].toUpperCase() + kata.substring(1);
  }

  /// Alamat lengkap: jalan, wilayah, dan patokan bila tersedia.
  String get alamatLengkap {
    final bagian = <String>[
      (streetAddress ?? '').trim(),
      (region ?? '').trim(),
      (detailNote ?? '').trim(),
    ].where((teks) => teks.isNotEmpty).toList();

    if (bagian.isEmpty) return alamatPenerima;

    return bagian.join(', ');
  }

  String get labelAlamat =>
      (label == null || label!.trim().isEmpty) ? 'Alamat' : label!.trim();

  bool get punyaKoordinat => latitude != null && longitude != null;

  /// Transisi sah berikutnya menurut PRD Bagian 6.7 (untuk tombol pembayaran).
  String? get statusBerikutnya => switch (status) {
    'menunggu_pembayaran' => 'menunggu_konfirmasi',
    'menunggu_konfirmasi' => 'dibayar',
    'dibayar' => 'diproses',
    'diproses' => 'dikirim',
    'dikirim' => 'selesai',
    _ => null,
  };

  bool get dapatDibayar => status == 'menunggu_pembayaran';

  factory Pesanan.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] ?? json['detail'];
    final items = itemsRaw is List
        ? itemsRaw
              .whereType<Map>()
              .map((item) =>
                  DetailPesanan.fromJson(Map<String, dynamic>.from(item)))
              .toList()
        : <DetailPesanan>[];

    final kurirRaw = json['kurir'];
    final kurirMap = kurirRaw is Map
        ? Map<String, dynamic>.from(kurirRaw)
        : <String, dynamic>{};

    final metodeRaw = json['metode_pembayaran'];
    final metodeMap = metodeRaw is Map
        ? Map<String, dynamic>.from(metodeRaw)
        : <String, dynamic>{};

    final pembayaranRaw = json['pembayaran'];
    final pembayaran = pembayaranRaw is Map
        ? Pembayaran.fromJson(Map<String, dynamic>.from(pembayaranRaw))
        : null;

    final voucherRaw = json['voucher'];
    final voucher = voucherRaw is Map
        ? VoucherPelanggan.fromJson(Map<String, dynamic>.from(voucherRaw))
        : null;

    return Pesanan(
      id: _bilangan(json['id']),
      nomorPesanan: json['nomor_pesanan']?.toString() ?? '',
      status: json['status']?.toString() ?? 'menunggu_pembayaran',
      namaPenerima: json['nama_penerima']?.toString() ?? '',
      alamatPenerima: json['alamat_penerima']?.toString() ?? '',
      phone: json['phone']?.toString(),
      region: json['region']?.toString(),
      streetAddress: json['street_address']?.toString(),
      detailNote: json['detail_note']?.toString(),
      label: json['label']?.toString(),
      latitude: _pecahan(json['latitude']),
      longitude: _pecahan(json['longitude']),
      subtotal: _bilangan(json['subtotal']),
      ongkosKirim: json['ongkos_kirim'] == null
          ? null
          : _bilangan(json['ongkos_kirim']),
      diskon: _bilangan(json['discount_amount']),
      total: _bilangan(json['total']),
      poinDiberikan: _bilangan(json['poin_diberikan']),
      kurirId: json['kurir_id'] == null
          ? (kurirMap['id'] == null ? null : _bilangan(kurirMap['id']))
          : _bilangan(json['kurir_id']),
      namaKurir: kurirMap['nama']?.toString() ??
          json['nama_kurir']?.toString(),
      wilayahKurir: kurirMap['wilayah']?.toString(),
      kodeMetode: metodeRaw is String
          ? metodeRaw
          : (metodeMap['kode']?.toString() ??
                json['kode_metode']?.toString() ??
                ''),
      namaMetode: metodeMap['nama']?.toString() ??
          json['nama_metode']?.toString(),
      dibuatPada: json['created_at']?.toString() ??
          json['dibuat_pada']?.toString() ??
          json['tanggal']?.toString(),
      pembayaran: pembayaran,
      voucher: voucher,
      items: items,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nomor_pesanan': nomorPesanan,
        'status': status,
        'nama_penerima': namaPenerima,
        'alamat_penerima': alamatPenerima,
        'phone': phone,
        'region': region,
        'street_address': streetAddress,
        'detail_note': detailNote,
        'label': label,
        'latitude': latitude,
        'longitude': longitude,
        'subtotal': subtotal,
        'ongkos_kirim': ongkosKirim,
        'discount_amount': diskon,
        'total': total,
        'poin_diberikan': poinDiberikan,
        'kurir_id': kurirId,
        'nama_kurir': namaKurir,
        'kode_metode': kodeMetode,
        'nama_metode': namaMetode,
        'created_at': dibuatPada,
        'pembayaran': pembayaran?.toJson(),
        'voucher': voucher?.toJson(),
        'items': items.map((item) => item.toJson()).toList(),
      };
}

int _bilangan(dynamic nilai) {
  if (nilai is int) return nilai;
  if (nilai is num) return nilai.toInt();

  return int.tryParse(nilai?.toString() ?? '') ?? 0;
}

double? _pecahan(dynamic nilai) {
  if (nilai == null) return null;
  if (nilai is num) return nilai.toDouble();

  return double.tryParse(nilai.toString());
}
