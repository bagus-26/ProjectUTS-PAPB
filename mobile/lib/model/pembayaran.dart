/// Ringkasan pembayaran Xendit pada respons `GET /api/pesanan/{id}`,
/// `POST /api/checkout`, dan `POST /api/pesanan/{id}/pembayaran`.
///
/// Objek ini bernilai `null` untuk pesanan yang memakai metode non-Xendit.
class Pembayaran {
  final String? kanal;
  final String? invoiceId;
  final String? invoiceUrl;
  final String? status;
  final String? dibayarPada;

  const Pembayaran({
    this.kanal,
    this.invoiceId,
    this.invoiceUrl,
    this.status,
    this.dibayarPada,
  });

  /// `PAID`/`SETTLED` berarti Xendit sudah menerima pembayaran.
  bool get sudahDibayar => status == 'PAID' || status == 'SETTLED';

  /// Invoice kedaluwarsa; pelanggan perlu membuat tautan pembayaran baru.
  bool get kedaluwarsa => status == 'EXPIRED';

  bool get punyaTautan => invoiceUrl != null && invoiceUrl!.trim().isNotEmpty;

  factory Pembayaran.fromJson(Map<String, dynamic> json) {
    return Pembayaran(
      kanal: _teks(json['kanal']),
      invoiceId: _teks(json['invoice_id']),
      invoiceUrl: _teks(json['invoice_url']),
      status: _teks(json['status']),
      dibayarPada: _teks(json['dibayar_pada']),
    );
  }

  Map<String, dynamic> toJson() => {
    'kanal': kanal,
    'invoice_id': invoiceId,
    'invoice_url': invoiceUrl,
    'status': status,
    'dibayar_pada': dibayarPada,
  };
}

String? _teks(dynamic nilai) {
  if (nilai == null) return null;

  final teks = nilai.toString().trim();

  return teks.isEmpty ? null : teks;
}
