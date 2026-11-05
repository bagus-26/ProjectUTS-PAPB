import 'package:flutter/material.dart';
import '../umum/tema_warna.dart';

/// Widget tombol utama aksi dengan status muat dan nonaktif
class TombolUtama extends StatelessWidget {
  final String teks;
  final VoidCallback? onPressed;
  final bool sedangMemuat;
  final IconData? ikon;
  final Color? warnaLatar;
  final Color? warnaTeks;
  final double tinggi;

  const TombolUtama({
    super.key,
    required this.teks,
    required this.onPressed,
    this.sedangMemuat = false,
    this.ikon,
    this.warnaLatar,
    this.warnaTeks,
    this.tinggi = 52,
  });

  @override
  Widget build(BuildContext context) {
    final bool bisaDitekan = onPressed != null && !sedangMemuat;
    final latar = warnaLatar ?? TemaWarna.hitamTombol;
    final teksColor = warnaTeks ?? Colors.white;

    return SizedBox(
      height: tinggi,
      width: double.infinity,
      child: FilledButton(
        onPressed: bisaDitekan ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: latar,
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: teksColor,
          disabledForegroundColor: Colors.grey.shade500,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: sedangMemuat
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(teksColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    teks,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: bisaDitekan ? teksColor : Colors.grey.shade500,
                    ),
                  ),
                  if (ikon != null) ...[
                    const SizedBox(width: 8),
                    Icon(ikon, size: 18),
                  ],
                ],
              ),
      ),
    );
  }
}

