import 'detail_pesanan.dart';
import 'pembayaran.dart';

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
  final int subtotal;
  final int? ongkosKirim;
  final int total;
  final int? kurirId;
  final String? namaKurir;
  final String? wilayahKurir;
  final String kodeMetode;
  final String? namaMetode;
  final String? dibuatPada;
  final Pembayaran? pembayaran;
  final List<DetailPesanan> items;

  const Pesanan({
    required this.id,
    required this.nomorPesanan,
    required this.status,
    required this.namaPenerima,
    required this.alamatPenerima,
    required this.subtotal,
    this.ongkosKirim,
    required this.total,
    this.kurirId,
    this.namaKurir,
    this.wilayahKurir,
    this.kodeMetode = '',
    this.namaMetode,
    this.dibuatPada,
    this.pembayaran,
    this.items = const [],
  });

  /// Label status untuk tampilan, mis. `menunggu_pembayaran` → `Menunggu Pembayaran`.
  String get labelStatus {
    final kata = status.replaceAll('_', ' ');
    if (kata.isEmpty) return status;

    return kata[0].toUpperCase() + kata.substring(1);
  }

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

    return Pesanan(
      id: _bilangan(json['id']),
      nomorPesanan: json['nomor_pesanan']?.toString() ?? '',
      status: json['status']?.toString() ?? 'menunggu_pembayaran',
      namaPenerima: json['nama_penerima']?.toString() ?? '',
      alamatPenerima: json['alamat_penerima']?.toString() ?? '',
      subtotal: _bilangan(json['subtotal']),
      ongkosKirim: json['ongkos_kirim'] == null
          ? null
          : _bilangan(json['ongkos_kirim']),
      total: _bilangan(json['total']),
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
      items: items,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nomor_pesanan': nomorPesanan,
        'status': status,
        'nama_penerima': namaPenerima,
        'alamat_penerima': alamatPenerima,
        'subtotal': subtotal,
        'ongkos_kirim': ongkosKirim,
        'total': total,
        'kurir_id': kurirId,
        'nama_kurir': namaKurir,
        'kode_metode': kodeMetode,
        'nama_metode': namaMetode,
        'created_at': dibuatPada,
        'pembayaran': pembayaran?.toJson(),
        'items': items.map((item) => item.toJson()).toList(),
      };
}

int _bilangan(dynamic nilai) {
  if (nilai is int) return nilai;
  if (nilai is num) return nilai.toInt();

  return int.tryParse(nilai?.toString() ?? '') ?? 0;
}
