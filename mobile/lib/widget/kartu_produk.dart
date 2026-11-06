import 'package:flutter/material.dart';
import '../model/produk.dart';
import '../umum/tema_warna.dart';

/// Widget kartu item produk dalam katalog (Grid/List item)
/// Sesuai Kriteria 2: Penanda STOK HABIS jelas dan tombol tambah dimatikan
class KartuProduk extends StatelessWidget {
  final Produk produk;
  final VoidCallback onTap;
  final VoidCallback? onTambah;
  final VoidCallback? onFavorit;
  final bool isFavorit;

  const KartuProduk({
    super.key,
    required this.produk,
    required this.onTap,
    this.onTambah,
    this.onFavorit,
    this.isFavorit = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool siapPesan = produk.dapatDipesan;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Gambar Produk dengan Badge Kategori, Tombol Favorit & Overlay Stok Habis
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: TemaWarna.kremTua,
                          child: produk.gambar != null && produk.gambar!.isNotEmpty
                              ? Image.network(
                                  produk.gambar!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _placeholderGambar();
                                  },
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            TemaWarna.cokelatUtama,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : _placeholderGambar(),
                        ),
                      ),

                      // Badge Kategori di Pojok Kiri Atas
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(220),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            produk.kategori,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: TemaWarna.teksUtama,
                            ),
                          ),
                        ),
                      ),

                      // Tombol Favorit di Pojok Kanan Atas
                      if (onFavorit != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: onFavorit,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(230),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(15),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                              child: Icon(
                                isFavorit ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: isFavorit
                                    ? Colors.red
                                    : TemaWarna.teksSekunder,
                              ),
                            ),
                          ),
                        ),

                      // Overlay "STOK HABIS" jika stok = 0 atau tersedia = false
                      if (!siapPesan)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.black.withAlpha(140),
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(180),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withAlpha(100),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'STOK HABIS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 2. Rating & Terjual
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: TemaWarna.kuningBintang,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${produk.rating}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: siapPesan ? TemaWarna.teksUtama : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '(${produk.terjual})',
                      style: TextStyle(
                        fontSize: 11,
                        color: siapPesan ? TemaWarna.teksSekunder : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // 3. Nama Produk
                Text(
                  produk.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: siapPesan ? TemaWarna.teksUtama : Colors.grey.shade500,
                  ),
                ),

                const SizedBox(height: 8),

                // 4. Harga & Tombol Tambah (+)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      TemaWarna.formatRupiah(produk.harga),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: siapPesan ? TemaWarna.teksUtama : Colors.grey.shade400,
                        decoration:
                            siapPesan ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    // Tombol Tambah (+) dimatikan jika stok habis
                    InkWell(
                      onTap: siapPesan ? onTambah : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: siapPesan
                              ? TemaWarna.hitamTombol
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 20,
                          color: siapPesan ? Colors.white : Colors.grey.shade500,
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

  Widget _placeholderGambar() {
    return Center(
      child: Icon(
        produk.kategori.toLowerCase().contains('minum')
            ? Icons.local_cafe_rounded
            : (produk.kategori.toLowerCase().contains('snack')
                ? Icons.cookie_rounded
                : Icons.restaurant_rounded),
        size: 38,
        color: TemaWarna.cokelatMuda,
      ),
    );
  }
}

