import 'package:flutter/material.dart';
import '../model/produk.dart';
import '../umum/tema_warna.dart';
import '../widget/tombol_utama.dart';

/// Formulir Tambah/Ubah Produk (Kelompok 1: MakanYuk!)
class FormProduk extends StatefulWidget {
  final Produk? produk;

  const FormProduk({super.key, this.produk});

  @override
  State<FormProduk> createState() => _FormProdukState();
}

class _FormProdukState extends State<FormProduk> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaController;
  late final TextEditingController _hargaController;
  late final TextEditingController _stokController;
  late final TextEditingController _deskripsiController;
  String _kategori = 'Makanan';
  bool _tersedia = true;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.produk?.nama ?? '');
    _hargaController =
        TextEditingController(text: widget.produk?.harga.toString() ?? '');
    _stokController =
        TextEditingController(text: widget.produk?.stok.toString() ?? '10');
    _deskripsiController =
        TextEditingController(text: widget.produk?.deskripsi ?? '');
    _kategori = widget.produk?.kategori ?? 'Makanan';
    _tersedia = widget.produk?.tersedia ?? true;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  void _simpan() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUbah = widget.produk != null;

    return Scaffold(
      backgroundColor: TemaWarna.latarKrem,
      appBar: AppBar(
        title: Text(isUbah ? 'Ubah Menu' : 'Tambah Menu Baru'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Menu',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama menu wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hargaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga (Rupiah)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Harga harus lebih besar dari 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _kategori,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Makanan', child: Text('Makanan')),
                DropdownMenuItem(value: 'Minuman', child: Text('Minuman')),
                DropdownMenuItem(value: 'Snack', child: Text('Snack')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _kategori = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stokController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stok',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'Stok tidak boleh negatif';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deskripsiController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Menu (Opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Tersedia untuk Dipesan'),
              value: _tersedia,
              onChanged: (v) => setState(() => _tersedia = v),
            ),
            const SizedBox(height: 24),
            TombolUtama(
              teks: isUbah ? 'Simpan Perubahan' : 'Tambah Menu',
              onPressed: _simpan,
            ),
          ],
        ),
      ),
    );
  }
}
