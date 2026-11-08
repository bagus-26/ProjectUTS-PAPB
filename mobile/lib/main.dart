import 'package:flutter/material.dart';

import 'halaman/halaman_utama.dart';
import 'umum/tema_warna.dart';

void main() {
  runApp(const AplikasiMakanYuk());
}

/// Aplikasi MakanYuk! — Toko Makanan & Minuman Siap Saji (Kelompok 1).
class AplikasiMakanYuk extends StatelessWidget {
  const AplikasiMakanYuk({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MakanYuk!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: TemaWarna.cokelatUtama),
        scaffoldBackgroundColor: TemaWarna.latarKrem,
        appBarTheme: const AppBarTheme(
          backgroundColor: TemaWarna.latarKrem,
          foregroundColor: TemaWarna.teksUtama,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),
      home: const HalamanUtama(),
    );
  }
}
