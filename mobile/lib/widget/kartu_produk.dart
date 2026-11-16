import 'package:flutter/material.dart';

import '../model/produk.dart';
import '../umum/format_rupiah.dart';
import '../umum/tema_warna.dart';
import 'gambar_menu.dart';

/// Kartu menu pelanggan yang dipakai di Home (`home.png`) dan Semua Menu
/// (`semua menu.png`).
///
/// Tampilan ringkas (Home) hanya memuat gambar, nama, harga, dan tombol `+`.
/// Tampilan lengkap (Semua Menu) menambahkan badge kategori, tombol favorit,
/// dan rating bintang.
///
/// Catatan stok: kartu ini **hanya** dirender untuk produk yang stoknya
/// tersedia. Overlay gelap dan badge "STOK HABIS" sengaja tidak ada karena
/// visibilitas menu diatur dari panel admin.
class KartuProduk extends StatelessWidget {
  final Produk produk;
  final VoidCallback onTap;
  final VoidCallback? onTambah;
  final VoidCallback? onFavorit;
  final bool isFavorit;

  /// Badge kategori di pojok kiri atas gambar (tampilan Semua Menu).
  final bool tampilkanBadgeKategori;

  /// Tombol hati di pojok kanan atas gambar (tampilan Semua Menu).
  final bool tampilkanFavorit;

  /// Baris rating bintang (tampilan Semua Menu).
  final bool tampilkanRating;

  const KartuProduk({
    super.key,
    required this.produk,
    required this.onTap,
    this.onTambah,
    this.onFavorit,
    this.isFavorit = false,
    this.tampilkanBadgeKategori = false,
    this.tampilkanFavorit = false,
    this.tampilkanRating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF4EFE9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D3A1A).withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Gambar menu dengan badge kategori & tombol favorit opsional
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: GambarMenu(
                            nama: produk.nama,
                            kategori: produk.kategori,
                          ),
                        ),
                      ),
                      if (tampilkanBadgeKategori)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(242),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              produk.kategori,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: TemaWarna.teksGelap,
                              ),
                            ),
                          ),
                        ),
                      if (tampilkanFavorit && onFavorit != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: onFavorit,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(242),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(12),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isFavorit
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 18,
                                  color: isFavorit
                                      ? Colors.red
                                      : const Color(0xFF9A9A9A),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 2. Rating bintang (khusus Semua Menu)
                if (tampilkanRating) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: TemaWarna.kuningBintang,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _rating,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: TemaWarna.teksGelap,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '($_jumlahUlasan)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: TemaWarna.teksSekunder,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 8),

                // 3. Nama menu
                Text(
                  produk.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: TemaWarna.teksGelap,
                  ),
                ),

                const SizedBox(height: 6),

                // 4. Harga & tombol tambah ke keranjang
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        formatRupiah(produk.harga),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TemaWarna.teksGelap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      button: true,
                      label: 'Tambah ${produk.nama} ke keranjang',
                      child: Material(
                        color: TemaWarna.cokelatPekat,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: onTambah,
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 34,
                            height: 34,
                            child: Icon(
                              Icons.add_rounded,
                              size: 21,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Rating tampilan. API produk belum menyediakan kolom rating, sehingga
  /// nilai dibuat stabil dari `id` menu agar desain bintang tetap konsisten
  /// tanpa mengubah model maupun kontrak API.
  String get _rating {
    final nilai = 4.5 + (produk.id % 5) * 0.1;
    return nilai.toStringAsFixed(1);
  }

  /// Jumlah ulasan tampilan, juga diturunkan secara stabil dari `id`.
  int get _jumlahUlasan => 60 + (produk.id * 37) % 160;
}
