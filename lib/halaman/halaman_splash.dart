import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../umum/tema_warna.dart';

/// Halaman Splash Screen aplikasi Makan Yuk!
/// Berdasarkan referensi desain PDF dengan visual makanan Indonesia,
/// palet warna Cream (#FFF4E5), Cokelat (#7A3518), dan Orange (#F59A23),
/// serta animasi fade-in & slide-up yang halus.
class HalamanSplash extends StatefulWidget {
  /// Widget halaman onboarding pertama / tujuan berikutnya (opsional)
  final Widget? halamanBerikutnya;

  /// Nama rute halaman onboarding (opsional, default: '/onboarding')
  final String? ruteBerikutnya;

  /// Callback ketika loading splash selesai (opsional)
  final VoidCallback? onSelesai;

  const HalamanSplash({
    super.key,
    this.halamanBerikutnya,
    this.ruteBerikutnya,
    this.onSelesai,
  });

  @override
  State<HalamanSplash> createState() => _HalamanSplashState();
}

class _HalamanSplashState extends State<HalamanSplash>
    with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final AnimationController _floatController;
  late final AnimationController _loadingController;

  late final Animation<double> _logoFadeAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _taglineFadeAnimation;
  late final Animation<Offset> _foodSlideAnimation;
  late final Animation<double> _foodFadeAnimation;
  late final Animation<double> _chipsFadeAnimation;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // Pastikan status bar transparan dan ikon gelap
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFFF4E5),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Controller untuk animasi masuk (entry animations)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Animasi logo fade-in & smooth scale
    _logoFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // Animasi tagline fade-in
    _taglineFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 0.85, curve: Curves.easeOut),
    );

    // Animasi ilustrasi makanan slide-up
    _foodSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.28),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _foodFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
    );

    // Animasi badge/chip makanan pendamping
    _chipsFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    // Controller untuk efek mengambang dinamis (gentle floating)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Controller untuk loading indicator
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Jalankan animasi masuk
    _animController.forward();

    // Pengalihan otomatis setelah 2.8 detik ke halaman onboarding pertama
    _navigationTimer = Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;

      if (widget.onSelesai != null) {
        widget.onSelesai!();
        return;
      }

      if (widget.halamanBerikutnya != null) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 650),
            pageBuilder: (context, animation, secondaryAnimation) =>
                widget.halamanBerikutnya!,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.05, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              final tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                ),
              );
            },
          ),
        );
        return;
      }

      // Jika ada rute tujuan (default '/onboarding' atau sesuai ruteBerikutnya)
      final rute = widget.ruteBerikutnya ?? '/onboarding';
      try {
        Navigator.of(context).pushReplacementNamed(rute);
      } catch (_) {
        // Fallback aman
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animController.dispose();
    _floatController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 244, 227), // #FFF4E3
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ornamen gelombang latar belakang (reproduksi presisi dari PDF)
          CustomPaint(
            size: Size(size.width, size.height),
            painter: const _GelombangBackgroundPainter(),
          ),

          // 2. Konten utama responsif
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double logoWidth =
                    (constraints.maxWidth * 0.58).clamp(200.0, 270.0);
                final double foodWidth =
                    (constraints.maxWidth * 0.96).clamp(320.0, 480.0);

                return Column(
                  children: [
                    // Spasi fleksibel atas
                    const Spacer(flex: 2),

                    // --- BAGIAN LOGO & TAGLINE TENGAH ---
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _logoFadeAnimation,
                          child: Transform.scale(
                            scale: _logoScaleAnimation.value,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo Makan Yuk! dengan chef hat
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: TemaWarna.cokelat
                                            .withValues(alpha: 0.06),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/images/logo_makan_yuk.png',
                                    width: logoWidth,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback elegan jika gambar belum termuat
                                      return _buildFallbackLogo(logoWidth);
                                    },
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Tagline: "Makanan & Minuman Siap Saji"
                                FadeTransition(
                                  opacity: _taglineFadeAnimation,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: TemaWarna.orange.withValues(alpha: 0.25),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: TemaWarna.cokelat
                                              .withValues(alpha: 0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'Makanan & Minuman Siap Saji',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.4,
                                        color: TemaWarna.cokelat, // #7A3518
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 1),

                    // --- BAGIAN ILUSTRASI MAKANAN INDONESIA (HERO) ---
                    SlideTransition(
                      position: _foodSlideAnimation,
                      child: FadeTransition(
                        opacity: _foodFadeAnimation,
                        child: AnimatedBuilder(
                          animation: _floatController,
                          builder: (context, child) {
                            final floatOffset =
                                math.sin(_floatController.value * math.pi) * 6.0;
                            return Transform.translate(
                              offset: Offset(0, floatOffset),
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                clipBehavior: Clip.none,
                                children: [
                                  // Bayangan lembut piring/mangkuk
                                  Positioned(
                                    bottom: 12,
                                    child: Container(
                                      width: foodWidth * 0.72,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        boxShadow: [
                                          BoxShadow(
                                            color: TemaWarna.cokelat
                                                .withValues(alpha: 0.25),
                                            blurRadius: 36,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Mangkuk Nasi Goreng Spesial dengan partikel terbang
                                  SizedBox(
                                    width: foodWidth,
                                    height: foodWidth * 0.88,
                                    child: Image.asset(
                                      'assets/images/nasi_goreng_splash.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),

                                  // Chip Makanan Pendamping Kiri: Mie Goreng
                                  Positioned(
                                    left: 14,
                                    top: 18,
                                    child: FadeTransition(
                                      opacity: _chipsFadeAnimation,
                                      child: _buildFoodBadge(
                                        title: 'Mie Goreng',
                                        subtitle: 'Khas Nusantara',
                                        assetPath:
                                            'assets/images/mie_goreng.png',
                                        iconFallback: '🍜',
                                        isLeft: true,
                                      ),
                                    ),
                                  ),

                                  // Chip Makanan Pendamping Kanan: Es Teh Manis
                                  Positioned(
                                    right: 14,
                                    top: 6,
                                    child: FadeTransition(
                                      opacity: _chipsFadeAnimation,
                                      child: _buildFoodBadge(
                                        title: 'Es Teh',
                                        subtitle: 'Segar & Manis',
                                        assetPath: 'assets/images/es_teh.png',
                                        iconFallback: '🧊',
                                        isLeft: false,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // --- BAGIAN LOADING INDICATOR DI BAWAH ---
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated smooth pill loading bar
                          _buildSmoothLoadingBar(),

                          const SizedBox(height: 12),

                          // Teks status loading friendly & premium
                          Text(
                            'Menyiapkan hidangan lezatmu...',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: TemaWarna.cokelat.withValues(alpha: 0.75),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Badge / Chip makanan pendamping (Mie Goreng & Es Teh)
  Widget _buildFoodBadge({
    required String title,
    required String subtitle,
    required String assetPath,
    required String iconFallback,
    required bool isLeft,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TemaWarna.orange.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: TemaWarna.cokelat.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: TemaWarna.cream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      iconFallback,
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: TemaWarna.cokelat,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: TemaWarna.orange.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Loading indicator halus berbentuk kapsul gradien
  Widget _buildSmoothLoadingBar() {
    return Container(
      width: 130,
      height: 6,
      decoration: BoxDecoration(
        color: TemaWarna.cokelat.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _loadingController,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 1.0,
            child: ShaderMask(
              shaderCallback: (rect) {
                final double value = _loadingController.value;
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    TemaWarna.orange.withValues(alpha: 0.1),
                    TemaWarna.orange,
                    TemaWarna.cokelat,
                    TemaWarna.orange.withValues(alpha: 0.1),
                  ],
                  stops: [
                    (value - 0.35).clamp(0.0, 1.0),
                    (value - 0.1).clamp(0.0, 1.0),
                    value.clamp(0.0, 1.0),
                    (value + 0.25).clamp(0.0, 1.0),
                  ],
                ).createShader(rect);
              },
              blendMode: BlendMode.srcIn,
              child: Container(
                decoration: BoxDecoration(
                  color: TemaWarna.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Fallback tampilan teks logo jika gambar tidak tersedia
  Widget _buildFallbackLogo(double width) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.restaurant_menu_rounded,
          size: width * 0.32,
          color: TemaWarna.cokelat,
        ),
        const SizedBox(height: 6),
        const Text(
          'Makan Yuk!',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: TemaWarna.cokelat,
          ),
        ),
      ],
    );
  }
}

/// CustomPainter untuk menggambar ornamen gelombang organik dari referensi PDF
class _GelombangBackgroundPainter extends CustomPainter {
  const _GelombangBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Dimensi kanvas acuan PDF: 390 x 844 (aspek rasio smartphone standar)
    final double sx = size.width / 390.0;
    final double sy = size.height / 844.0;

    // 1. Ornamen Gelombang Kanan Atas (#B9692D / Terracotta Cokelat)
    final Paint waveTopPaint = Paint()
      ..color = const Color(0xFFB8502A)
      ..style = PaintingStyle.fill;

    final Path waveTop = Path();
    waveTop.moveTo(150.8 * sx, 0);
    waveTop.lineTo(390.0 * sx, 0);
    waveTop.lineTo(390.0 * sx, 133.0 * sy);
    waveTop.cubicTo(
      335.92 * sx,
      112.0 * sy,
      339.04 * sx,
      84.0 * sy,
      279.76 * sx,
      85.0 * sy,
    );
    waveTop.cubicTo(
      217.36 * sx,
      87.0 * sy,
      147.68 * sx,
      75.0 * sy,
      150.8 * sx,
      0,
    );
    waveTop.close();
    canvas.drawPath(waveTop, waveTopPaint);

    // 2. Ornamen Gelombang Kiri Bawah Utama (Warna Terracotta Cerah)
    final Paint waveBottomLightPaint = Paint()
      ..color = const Color(0xFFB86D30)
      ..style = PaintingStyle.fill;

    final Path waveBottomLight = Path();
    waveBottomLight.moveTo(0, 487.0 * sy);
    waveBottomLight.cubicTo(
      107.76 * sx,
      506.0 * sy,
      118.69 * sx,
      588.5 * sy,
      53.88 * sx,
      626.0 * sy,
    );
    waveBottomLight.cubicTo(
      3.59 * sx,
      661.0 * sy,
      200.69 * sx,
      759.5 * sy,
      334.79 * sx,
      752.5 * sy,
    );
    waveBottomLight.cubicTo(
      444.95 * sx,
      740.5 * sy,
      359.2 * sx,
      684.0 * sy,
      449.0 * sx,
      660.0 * sy,
    );
    waveBottomLight.lineTo(449.0 * sx, 844.0 * sy);
    waveBottomLight.lineTo(0, 844.0 * sy);
    waveBottomLight.close();
    canvas.drawPath(waveBottomLight, waveBottomLightPaint);

    // 3. Ornamen Gelombang Kiri Bawah Lapisan Dalam (Warna Cokelat Tua #7A3518)
    final Paint waveBottomDarkPaint = Paint()
      ..color = const Color(0xFF7A3518)
      ..style = PaintingStyle.fill;

    final Path waveBottomDark = Path();
    waveBottomDark.moveTo(0, 715.0 * sy);
    waveBottomDark.cubicTo(
      121.9 * sx,
      660.0 * sy,
      249.2 * sx,
      810.0 * sy,
      401.0 * sx,
      730.0 * sy,
    );
    waveBottomDark.lineTo(401.0 * sx, 860.0 * sy);
    waveBottomDark.lineTo(0, 860.0 * sy);
    waveBottomDark.close();
    canvas.drawPath(waveBottomDark, waveBottomDarkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
