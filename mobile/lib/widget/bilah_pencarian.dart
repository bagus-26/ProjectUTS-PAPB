import 'package:flutter/material.dart';
import '../umum/tema_warna.dart';

/// Widget bilah pencarian produk yang terintegrasi query parameter ?cari=
/// Sesuai UI MakanYuk! halaman katalog dan favorit
class BilahPencarian extends StatefulWidget {
  final String nilaiAwal;
  final ValueChanged<String> saatCari;
  final VoidCallback? saatFilterDitekan;
  final String petunjuk;

  /// Radius sudut kolom. `30` menghasilkan bentuk pill penuh (Home).
  final double radius;

  /// Menaruh ikon filter di dalam kolom pencarian, bukan sebagai tombol
  /// terpisah di sebelah kanan (Home).
  final bool filterDiDalam;

  /// Ikon tombol filter.
  final IconData ikonFilter;

  const BilahPencarian({
    super.key,
    this.nilaiAwal = '',
    required this.saatCari,
    this.saatFilterDitekan,
    this.petunjuk = 'Cari menu favoritmu...',
    this.radius = 16,
    this.filterDiDalam = false,
    this.ikonFilter = Icons.tune_rounded,
  });

  @override
  State<BilahPencarian> createState() => _BilahPencarianState();
}

class _BilahPencarianState extends State<BilahPencarian> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.nilaiAwal);
  }

  @override
  void didUpdateWidget(covariant BilahPencarian oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nilaiAwal != _controller.text && oldWidget.nilaiAwal != widget.nilaiAwal) {
      _controller.text = widget.nilaiAwal;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _bersihkan() {
    _controller.clear();
    widget.saatCari('');
    setState(() {});
  }

  Widget _tombolBersihkan() {
    return IconButton(
      icon: const Icon(Icons.close_rounded, size: 18),
      color: Colors.grey.shade600,
      tooltip: 'Bersihkan pencarian',
      onPressed: _bersihkan,
    );
  }

  Widget _tombolFilter() {
    return IconButton(
      icon: Icon(widget.ikonFilter, size: 21),
      color: TemaWarna.cokelatPekat,
      tooltip: 'Filter menu',
      onPressed: widget.saatFilterDitekan,
    );
  }

  Widget? _bangunSuffix() {
    final adaTeks = _controller.text.isNotEmpty;
    final adaFilter =
        widget.filterDiDalam && widget.saatFilterDitekan != null;

    if (!adaTeks && !adaFilter) return null;

    if (adaFilter) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (adaTeks) _tombolBersihkan(),
          _tombolFilter(),
        ],
      );
    }

    return _tombolBersihkan();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: TemaWarna.latarPutih,
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(color: TemaWarna.garisAbu),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: widget.saatCari,
              onChanged: (teks) {
                setState(() {});
                widget.saatCari(teks);
              },
              style: const TextStyle(
                fontSize: 14,
                color: TemaWarna.teksUtama,
              ),
              decoration: InputDecoration(
                hintText: widget.petunjuk,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade500,
                  size: 22,
                ),
                suffixIcon: _bangunSuffix(),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        if (!widget.filterDiDalam && widget.saatFilterDitekan != null) ...[
          const SizedBox(width: 10),
          InkWell(
            onTap: widget.saatFilterDitekan,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: TemaWarna.latarPutih,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TemaWarna.garisAbu),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                widget.ikonFilter,
                color: TemaWarna.cokelatPekat,
                size: 22,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

