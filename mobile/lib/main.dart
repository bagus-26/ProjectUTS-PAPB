import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'halaman/halaman_utama.dart';
import 'umum/tema_warna.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const AplikasiMakanYuk());
}

/// Alias untuk kompatibilitas uji bawaan
typedef MyApp = AplikasiMakanYuk;

/// Root widget aplikasi MakanYuk! (Domain Makanan & Minuman Siap Saji - Kelompok 1)
class AplikasiMakanYuk extends StatelessWidget {
  const AplikasiMakanYuk({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MakanYuk!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: TemaWarna.latarKrem,
        colorScheme: ColorScheme.fromSeed(
          seedColor: TemaWarna.cokelatUtama,
          primary: TemaWarna.cokelatUtama,
          surface: TemaWarna.latarKrem,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: TemaWarna.latarKrem,
          foregroundColor: TemaWarna.teksUtama,
          elevation: 0,
        ),
        fontFamily: 'Roboto',
      ),
      home: const HalamanUtama(),
    );
  }
}
