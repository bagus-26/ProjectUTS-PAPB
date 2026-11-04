import 'package:flutter/material.dart';

import 'konfigurasi/konfigurasi.dart';
import 'layanan/galat_api.dart';
import 'layanan/layanan_api.dart';

void main() {
  runApp(const AplikasiWarung());
}

class AplikasiWarung extends StatelessWidget {
  const AplikasiWarung({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Makan Yuk !',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: const HalamanUjiSambung(),
    );
  }
}

class HalamanUjiSambung extends StatefulWidget {
  const HalamanUjiSambung({super.key});

  @override
  State<HalamanUjiSambung> createState() => _HalamanUjiSambungState();
}

class _HalamanUjiSambungState extends State<HalamanUjiSambung> {
  final LayananApi _layanan = LayananApi();
  bool _sedangMuat = false;
  String _pesan = 'Tekan tombol untuk menguji sambungan ke server.';

  Future<void> _ujiSambung() async {
    setState(() {
      _sedangMuat = true;
      _pesan = 'Menghubungi server...';
    });

    try {
      final data = await _layanan.ambil('/produk');
      final jumlah = data is List ? data.length : 0;

      if (!mounted) {
        return;
      }

      setState(() {
        _pesan = 'Sambungan berhasil. $jumlah produk diterima dari server.';
      });
    } on GalatApi catch (galat) {
      if (!mounted) {
        return;
      }

      setState(() {
        _pesan = galat.pesan;
      });
    } finally {
      if (mounted) {
        setState(() {
          _sedangMuat = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fondasi Flutter — Kelompok 1')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('Alamat server:'),
            const SizedBox(height: 4),
            Text(Konfigurasi.baseUrl),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _sedangMuat ? null : _ujiSambung,
              child: Text(_sedangMuat ? 'Memuat...' : 'Uji Sambung'),
            ),
            const SizedBox(height: 24),
            Text(_pesan),
          ],
        ),
      ),
    );
  }
}
