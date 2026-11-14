import 'package:flutter/material.dart';
import '../umum/tema_warna.dart';
import '../umum/format_rupiah.dart';

/// Halaman Profil Pengguna (MakanYuk! - Kelompok 1)
/// Sesuai UI rancangan Screenshot 12
class HalamanProfil extends StatelessWidget {
  const HalamanProfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaWarna.latarKrem,
      appBar: AppBar(
        backgroundColor: TemaWarna.latarKrem,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: TemaWarna.teksUtama,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: TemaWarna.teksUtama),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Pengguna
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: TemaWarna.kremTua,
                  child: Icon(Icons.person, size: 36, color: TemaWarna.cokelatUtama),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Budi Santoso',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.stars_rounded, size: 16, color: Colors.amber),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '+62 812-3456-7890\nbudi.santoso@email.com',
                        style: TextStyle(
                          fontSize: 12,
                          color: TemaWarna.teksSekunder,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Dompet MakanYukPay & Reward
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MakanYukPay',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(formatRupiah(182400),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(height: 30, width: 1, color: TemaWarna.garisAbu),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Poin Reward',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                        SizedBox(height: 2),
                        Text('1.450 Pts',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Menu Pilihan Profil
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _itemMenu(
                  ikon: Icons.location_on_outlined,
                  judul: 'Alamat Pengiriman',
                  keterangan: 'Jl. Mawar No. 12 (2 Alamat)',
                ),
                const Divider(height: 1, indent: 56),
                _itemMenu(
                  ikon: Icons.payment_outlined,
                  judul: 'Metode Pembayaran',
                  keterangan: 'QRIS, E-Wallet, Virtual Account',
                ),
                const Divider(height: 1, indent: 56),
                _itemMenu(
                  ikon: Icons.receipt_long_outlined,
                  judul: 'Riwayat Pesanan',
                  keterangan: 'Daftar transaksi dan tagihan',
                ),
                const Divider(height: 1, indent: 56),
                _itemMenu(
                  ikon: Icons.discount_outlined,
                  judul: 'Voucher & Promo',
                  keterangan: '4 voucher siap dipakai',
                  badge: '4',
                ),
                const Divider(height: 1, indent: 56),
                _itemMenu(
                  ikon: Icons.help_outline_rounded,
                  judul: 'Pusat Bantuan',
                  keterangan: 'Hubungi CS & info aplikasi',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tombol Keluar
          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: TemaWarna.merahHabis,
              side: BorderSide(color: Colors.red.shade200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Keluar dari Akun',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _itemMenu({
    required IconData ikon,
    required String judul,
    required String keterangan,
    String? badge,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: TemaWarna.kremTua,
          shape: BoxShape.circle,
        ),
        child: Icon(ikon, color: TemaWarna.cokelatUtama, size: 20),
      ),
      title: Text(judul,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      subtitle: Text(keterangan,
          style: const TextStyle(fontSize: 12, color: TemaWarna.teksSekunder)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: TemaWarna.cokelatUtama,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
      onTap: () {},
    );
  }
}
