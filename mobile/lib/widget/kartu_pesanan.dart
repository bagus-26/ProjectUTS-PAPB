import 'package:flutter/material.dart';
import '../umum/format_rupiah.dart';
import '../umum/tema_warna.dart';

/// Widget kartu pesanan untuk riwayat pesanan
class KartuPesanan extends StatelessWidget {
  final String nomorPesanan;
  final String tanggal;
  final String status;
  final String namaProdukUtama;
  final int jumlahItem;
  final int totalHarga;
  final VoidCallback? onTap;

  const KartuPesanan({
    super.key,
    required this.nomorPesanan,
    required this.tanggal,
    required this.status,
    required this.namaProdukUtama,
    required this.jumlahItem,
    required this.totalHarga,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelesai = status.toLowerCase() == 'selesai';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: TemaWarna.garisAbu),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nomorPesanan,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelesai ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelesai ? Colors.green.shade700 : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tanggal,
                style: const TextStyle(fontSize: 11, color: TemaWarna.teksSekunder),
              ),
              const Divider(height: 16),
              Text(
                namaProdukUtama,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$jumlahItem Menu',
                    style: const TextStyle(fontSize: 12, color: TemaWarna.teksSekunder),
                  ),
                  Text(
                    formatRupiah(totalHarga),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: TemaWarna.cokelatUtama,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

