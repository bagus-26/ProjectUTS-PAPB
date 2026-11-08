import 'package:flutter/material.dart';
import '../layanan/galat_api.dart';
import '../layanan/layanan_api.dart';
import '../model/produk.dart';
import '../umum/tema_warna.dart';
import '../widget/tombol_utama.dart';

/// Formulir Tambah/Ubah Produk (Kelompok 1: MakanYuk!)
///
/// Menyimpan lewat `POST /api/produk` (tambah) atau `PUT /api/produk/{id}`
/// (ubah) sesuai PRD 7.1 baris Kelola Produk:
/// * 422 tampil **per kolom** di bawah input yang bersangkutan,
/// * tombol mati + spinner selama request (satu ketukan = satu simpan),
/// * pop dengan hasil `true` hanya setelah respons sukses.
class FormProduk extends StatefulWidget {
  final Produk? produk;

  const FormProduk({super.key, this.produk});

  @override
  State<FormProduk> createState() => _FormProdukState();
}

class _FormProdukState extends State<FormProduk> {
  final LayananApi _layanan = LayananApi();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaController;
  late final TextEditingController _hargaController;
  late final TextEditingController _stokController;
  late final TextEditingController _deskripsiController;
  late final TextEditingController _persiapanController;

  String _kategori = 'Makanan';
  bool _tersedia = true;
  bool _bisaPedas = false;

  bool _sedangSimpan = false;

  /// Pesan galat 422 per kolom (PRD 7.3) untuk tampil di bawah input.
  Map<String, String> _galatPerKolom = {};

  bool get _isUbah => widget.produk != null;

  @override
  void initState() {
    super.initState();
    final produk = widget.produk;
    _namaController = TextEditingController(text: produk?.nama ?? '');
    _hargaController =
        TextEditingController(text: produk?.harga.toString() ?? '');
    _stokController =
        TextEditingController(text: produk?.stok.toString() ?? '10');
    _deskripsiController = TextEditingController(text: produk?.deskripsi ?? '');
    _persiapanController = TextEditingController(
      text: (produk?.waktuPersiapanMenit ?? 15).toString(),
    );
    _kategori = produk?.kategori ?? 'Makanan';
    _tersedia = produk?.tersedia ?? true;
    _bisaPedas = produk?.bisaPedas ?? false;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    _deskripsiController.dispose();
    _persiapanController.dispose();
    super.dispose();
  }

  /// `POST /api/produk` atau `PUT /api/produk/{id}`.
  /// 422 → pesan per kolom; galat lain → snackbar; sukses → `pop(true)`.
  Future<void> _simpan() async {
    if (_sedangSimpan) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Flag diset SEBELUM await agar tombol mati sejak ketukan pertama.
    setState(() {
      _sedangSimpan = true;
      _galatPerKolom = {};
    });

    final String nama = _namaController.text.trim();
    final int harga = int.tryParse(_hargaController.text.trim()) ?? 0;
    final int stok = int.tryParse(_stokController.text.trim()) ?? 0;
    final String deskripsi = _deskripsiController.text.trim();
    final int persiapan =
        int.tryParse(_persiapanController.text.trim()) ?? 15;

    try {
      if (_isUbah) {
        await _layanan.ubahProduk(
          id: widget.produk!.id,
          nama: nama,
          harga: harga,
          kategori: _kategori,
          stok: stok,
          tersedia: _tersedia,
          deskripsi: deskripsi.isEmpty ? null : deskripsi,
          bisaPedas: _bisaPedas,
          waktuPersiapanMenit: persiapan,
        );
      } else {
        await _layanan.tambahProduk(
          nama: nama,
          harga: harga,
          kategori: _kategori,
          stok: stok,
          tersedia: _tersedia,
          deskripsi: deskripsi.isEmpty ? null : deskripsi,
          bisaPedas: _bisaPedas,
          waktuPersiapanMenit: persiapan,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on GalatApi catch (g) {
      if (!mounted) return;
      _tanganiGalat(g);
    } catch (_) {
      if (!mounted) return;
      _tampilkanGalat(GalatApi.umum());
    } finally {
      if (mounted) setState(() => _sedangSimpan = false);
    }
  }

  /// 422 → pesan per kolom di bawah inputnya; 404/409/galat lain → snackbar.
  void _tanganiGalat(GalatApi g) {
    if (g.jenis == JenisGalat.validasi && g.errors != null) {
      setState(() {
        _galatPerKolom = g.errors!.map(
          (kolom, pesan) => MapEntry(kolom, pesan.join('\n')),
        );
      });
    }
    _tampilkanGalat(g);
  }

  void _tampilkanGalat(GalatApi g) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: TemaWarna.merahHabis,
          duration: const Duration(seconds: 4),
          content: Text(g.pesan),
        ),
      );
  }

  void _bersihkanGalatKolom() {
    if (_galatPerKolom.isEmpty) return;
    setState(() => _galatPerKolom = {});
  }

  InputDecoration _dekorasi(String label, String? hint, String kolom) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: _galatPerKolom[kolom],
      labelStyle: const TextStyle(fontSize: 13, color: TemaWarna.teksSekunder),
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      filled: true,
      fillColor: TemaWarna.abuMuda,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TemaWarna.garisAbu),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TemaWarna.garisAbu),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TemaWarna.cokelatUtama, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TemaWarna.merahHabis),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaWarna.latarKrem,
      appBar: AppBar(
        backgroundColor: TemaWarna.latarKrem,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _isUbah ? 'Ubah Menu' : 'Tambah Menu Baru',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: TemaWarna.teksUtama,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _namaController,
              enabled: !_sedangSimpan,
              decoration: _dekorasi('Nama Menu', 'Contoh: Nasi Goreng', 'nama'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama menu wajib diisi' : null,
              onChanged: (_) => _bersihkanGalatKolom(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hargaController,
              enabled: !_sedangSimpan,
              keyboardType: TextInputType.number,
              decoration: _dekorasi('Harga (Rupiah)', 'Contoh: 25000', 'harga'),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return 'Harga harus lebih besar dari 0';
                return null;
              },
              onChanged: (_) => _bersihkanGalatKolom(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _kategori,
              decoration: _dekorasi('Kategori', null, 'kategori'),
              items: const [
                DropdownMenuItem(value: 'Makanan', child: Text('Makanan')),
                DropdownMenuItem(value: 'Minuman', child: Text('Minuman')),
                DropdownMenuItem(value: 'Snack', child: Text('Snack')),
              ],
              onChanged: _sedangSimpan
                  ? null
                  : (v) {
                      if (v != null) {
                        setState(() {
                          _kategori = v;
                          _bersihkanGalatKolom();
                        });
                      }
                    },
            ),
            if (_galatPerKolom.containsKey('kategori')) ...[
              const SizedBox(height: 6),
              Text(
                _galatPerKolom['kategori']!,
                style: const TextStyle(
                  fontSize: 12,
                  color: TemaWarna.merahHabis,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _stokController,
              enabled: !_sedangSimpan,
              keyboardType: TextInputType.number,
              decoration: _dekorasi('Stok', 'Contoh: 30', 'stok'),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n < 0) return 'Stok tidak boleh negatif';
                return null;
              },
              onChanged: (_) => _bersihkanGalatKolom(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _persiapanController,
              enabled: !_sedangSimpan,
              keyboardType: TextInputType.number,
              decoration: _dekorasi(
                'Waktu Persiapan (menit)',
                'Contoh: 15',
                'waktu_persiapan_menit',
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n <= 0) {
                  return 'Waktu persiapan harus lebih besar dari 0';
                }
                return null;
              },
              onChanged: (_) => _bersihkanGalatKolom(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deskripsiController,
              enabled: !_sedangSimpan,
              maxLines: 3,
              decoration: _dekorasi(
                'Deskripsi Menu (Opsional)',
                'Ceritakan menu ini secara singkat',
                'deskripsi',
              ),
              validator: (v) => (v != null && v.trim().length > 500)
                  ? 'Deskripsi maksimal 500 karakter'
                  : null,
              onChanged: (_) => _bersihkanGalatKolom(),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Tersedia untuk Dipesan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Menu disembunyikan dari pembeli bila dimatikan',
                style: TextStyle(fontSize: 12, color: TemaWarna.teksSekunder),
              ),
              value: _tersedia,
              activeThumbColor: TemaWarna.cokelatUtama,
              onChanged: _sedangSimpan
                  ? null
                  : (v) => setState(() {
                        _tersedia = v;
                        _bersihkanGalatKolom();
                      }),
            ),
            if (_galatPerKolom.containsKey('tersedia')) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _galatPerKolom['tersedia']!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: TemaWarna.merahHabis,
                  ),
                ),
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Bisa Pedas',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Pembeli dapat memilih tingkat kepedasan',
                style: TextStyle(fontSize: 12, color: TemaWarna.teksSekunder),
              ),
              value: _bisaPedas,
              activeThumbColor: TemaWarna.cokelatUtama,
              onChanged: _sedangSimpan
                  ? null
                  : (v) => setState(() {
                        _bisaPedas = v;
                        _bersihkanGalatKolom();
                      }),
            ),
            if (_galatPerKolom.containsKey('bisa_pedas')) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _galatPerKolom['bisa_pedas']!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: TemaWarna.merahHabis,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            TombolUtama(
              teks: _isUbah ? 'Simpan Perubahan' : 'Tambah Menu',
              warnaLatar: TemaWarna.cokelatUtama,
              sedangMemuat: _sedangSimpan,
              onPressed: _sedangSimpan ? null : _simpan,
            ),
          ],
        ),
      ),
    );
  }
}
