import 'package:flutter/material.dart';

import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../umum/keadaan_muat.dart';

const Color _warnaCokelat = Color(0xFF6D4C41);
const Color _warnaKrem = Color(0xFFFFF8F1);
const Color _warnaKremTua = Color(0xFFF2E4D5);

//tolong dibaca dulu bagian kodenya, ini sebagian dari infrastruktur aplikasi

int? _idProduk(Map<String, dynamic> produk) {
  final nilai = produk['id'];

  if (nilai is int) {
    return nilai;
  }

  return int.tryParse(nilai?.toString() ?? '');
}

String _teks(dynamic nilai, [String cadangan = '']) {
  if (nilai == null) {
    return cadangan;
  }

  final hasil = nilai.toString().trim();

  return hasil.isEmpty ? cadangan : hasil;
}

int _angka(dynamic nilai) {
  if (nilai is int) {
    return nilai;
  }

  if (nilai is num) {
    return nilai.toInt();
  }

  return int.tryParse(nilai?.toString() ?? '') ?? 0;
}

String _formatRupiah(int nilai) {
  final teks = nilai.toString();
  final hasil = StringBuffer();

  for (var i = 0; i < teks.length; i++) {
    if (i > 0 && (teks.length - i) % 3 == 0) {
      hasil.write('.');
    }

    hasil.write(teks[i]);
  }

  return 'Rp $hasil';
}

Map<String, dynamic> _peta(dynamic nilai) {
  if (nilai is Map<String, dynamic>) {
    return nilai;
  }

  if (nilai is Map) {
    return Map<String, dynamic>.from(nilai);
  }

  return <String, dynamic>{};
}

class FavoritLokal {
  FavoritLokal._();

  static final Map<int, Map<String, dynamic>> _tersimpan =
      <int, Map<String, dynamic>>{};

  static List<Map<String, dynamic>> get semua =>
      _tersimpan.values.toList(growable: false);

  static bool berisi(int id) => _tersimpan.containsKey(id);

  static void alihkan(Map<String, dynamic> produk) {
    final id = _idProduk(produk);

    if (id == null) {
      return;
    }

    if (_tersimpan.containsKey(id)) {
      _tersimpan.remove(id);
    } else {
      _tersimpan[id] = Map<String, dynamic>.from(produk);
    }
  }

  static void hapus(int id) {
    _tersimpan.remove(id);
  }
}

class HalamanMenuFavorit extends StatefulWidget {
  const HalamanMenuFavorit({super.key});

  @override
  State<HalamanMenuFavorit> createState() => _HalamanMenuFavoritState();
}

class _HalamanMenuFavoritState extends State<HalamanMenuFavorit> {
  Future<void> _bukaPemilih() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.9,
          child: _LembarPilihFavorit(
            saatBerubah: () {
              if (mounted) {
                setState(() {});
              }
            },
          ),
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _hapusFavorit(int id) {
    setState(() {
      FavoritLokal.hapus(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final favorit = FavoritLokal.semua;

    return Scaffold(
      backgroundColor: _warnaKrem,
      appBar: AppBar(
        title: const Text('Menu Favorit'),
        backgroundColor: _warnaKrem,
        foregroundColor: _warnaCokelat,
        surfaceTintColor: Colors.transparent,
      ),
      body: favorit.isEmpty
          ? _tampilanKosong()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: favorit.length,
              itemBuilder: (BuildContext context, int indeks) {
                final produk = favorit[indeks];

                return _KartuFavorit(
                  produk: produk,
                  saatDihapus: () {
                    final id = _idProduk(produk);

                    if (id != null) {
                      _hapusFavorit(id);
                    }
                  },
                );
              },
            ),
      floatingActionButton: favorit.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _bukaPemilih,
              backgroundColor: _warnaCokelat,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Favorit'),
            ),
    );
  }

  Widget _tampilanKosong() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: _warnaKremTua,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 44,
                color: _warnaCokelat,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum ada menu favorit',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _warnaCokelat,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tandai menu kesukaanmu supaya lebih mudah ditemukan lagi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: _warnaCokelat.withAlpha(170),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _bukaPemilih,
              style: FilledButton.styleFrom(
                backgroundColor: _warnaCokelat,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Pilih Menu Favorit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuFavorit extends StatelessWidget {
  const _KartuFavorit({required this.produk, required this.saatDihapus});

  final Map<String, dynamic> produk;
  final VoidCallback saatDihapus;

  @override
  Widget build(BuildContext context) {
    final nama = _teks(produk['nama'], 'Produk');
    final kategori = _teks(produk['kategori'], 'Menu');
    final harga = _angka(produk['harga']);
    final stok = _angka(produk['stok']);
    final tersedia = produk['tersedia'] != false && stok > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _warnaCokelat.withAlpha(18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: _warnaKremTua,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              kategori.toLowerCase().contains('minum')
                  ? Icons.local_drink_outlined
                  : Icons.restaurant_outlined,
              size: 30,
              color: _warnaCokelat,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _warnaCokelat,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  kategori,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: _warnaCokelat.withAlpha(150),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Text(
                      _formatRupiah(harga),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _warnaCokelat,
                      ),
                    ),
                    if (!tersedia) ...<Widget>[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(20),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Habis',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: saatDihapus,
            tooltip: 'Hapus dari favorit',
            icon: const Icon(Icons.favorite, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

class _LembarPilihFavorit extends StatefulWidget {
  const _LembarPilihFavorit({required this.saatBerubah});

  final VoidCallback saatBerubah;

  @override
  State<_LembarPilihFavorit> createState() => _LembarPilihFavoritState();
}

class _LembarPilihFavoritState extends State<_LembarPilihFavorit> {
  final LayananApi _layanan = LayananApi();
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  List<Map<String, dynamic>> _produk = <Map<String, dynamic>>[];
  String _pesanGalat = '';

  @override
  void initState() {
    super.initState();
    _muatProduk();
  }

  Future<void> _muatProduk() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _pesanGalat = '';
    });

    try {
      final data = await _layanan.ambil('/produk');
      final daftar = data is List
          ? data
                .map(_peta)
                .where((Map<String, dynamic> item) => item.isNotEmpty)
                .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) {
        return;
      }

      setState(() {
        _produk = daftar;
        _keadaan = daftar.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
      });
    } on GalatApi catch (galat) {
      if (!mounted) {
        return;
      }

      setState(() {
        _pesanGalat = galat.pesan;
        _keadaan = KeadaanMuat.galat;
      });
    }
  }

  void _alihkan(Map<String, dynamic> produk) {
    setState(() {
      FavoritLokal.alihkan(produk);
    });

    widget.saatBerubah();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _warnaKrem,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: _warnaCokelat.withAlpha(60),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Pilih Menu Favorit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _warnaCokelat,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Tutup',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(child: _isi()),
          ],
        ),
      ),
    );
  }

  Widget _isi() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const Center(child: CircularProgressIndicator());
      case KeadaanMuat.galat:
        return _tampilanGalat();
      case KeadaanMuat.kosong:
        return _tampilanKosong();
      case KeadaanMuat.berhasil:
        return _daftar();
    }
  }

  Widget _tampilanGalat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.cloud_off, size: 44, color: _warnaCokelat),
            const SizedBox(height: 12),
            Text(
              _pesanGalat.isEmpty ? 'Menu belum bisa dimuat.' : _pesanGalat,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _warnaCokelat),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _muatProduk,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tampilanKosong() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.restaurant_menu, size: 44, color: _warnaCokelat),
            const SizedBox(height: 12),
            const Text(
              'Belum ada produk yang bisa dipilih.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _warnaCokelat),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _muatProduk,
              icon: const Icon(Icons.refresh),
              label: const Text('Muat ulang'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _daftar() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _produk.length,
      itemBuilder: (BuildContext context, int indeks) {
        final produk = _produk[indeks];
        final id = _idProduk(produk);
        final dipilih = id != null && FavoritLokal.berisi(id);
        final nama = _teks(produk['nama'], 'Produk');
        final kategori = _teks(produk['kategori'], 'Menu');
        final harga = _angka(produk['harga']);
        final stok = _angka(produk['stok']);
        final tersedia = produk['tersedia'] != false && stok > 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: id == null ? null : () => _alihkan(produk),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _warnaKremTua,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        kategori.toLowerCase().contains('minum')
                            ? Icons.local_drink_outlined
                            : Icons.restaurant_outlined,
                        color: _warnaCokelat,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _warnaCokelat,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_formatRupiah(harga)} • '
                            '${tersedia ? 'Tersedia' : 'Habis'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _warnaCokelat.withAlpha(160),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      dipilih ? Icons.favorite : Icons.favorite_border,
                      color: dipilih
                          ? Colors.red
                          : _warnaCokelat.withAlpha(120),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}