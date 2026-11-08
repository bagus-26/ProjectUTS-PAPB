import 'dart:async';

import 'package:flutter/material.dart';

import '../umum/tema_warna.dart';
import 'halaman_utama.dart';

class HalamanSplash extends StatefulWidget {
  const HalamanSplash({super.key});

  @override
  State<HalamanSplash> createState() => _HalamanSplashState();
}

class _HalamanSplashState extends State<HalamanSplash>
    with SingleTickerProviderStateMixin {
  Timer? _timerNavigasi;
  late final AnimationController _animasi = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

  late final Animation<double> _opasitas = CurvedAnimation(
    parent: _animasi,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _timerNavigasi = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HalamanUtama()),
      );
    });
  }

  @override
  void dispose() {
    _timerNavigasi?.cancel();
    _animasi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaWarna.latarKrem,
      body: Center(
        child: FadeTransition(
          opacity: _opasitas,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: const BoxDecoration(
                  color: TemaWarna.cokelatUtama,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'MakanYuk!',
                style: TextStyle(
                  color: TemaWarna.cokelatTua,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Menu lezat, tinggal pesan',
                style: TextStyle(color: TemaWarna.teksSekunder, fontSize: 14),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: TemaWarna.cokelatUtama,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
