import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shell/main_shell.dart';
import 'start_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Color _gradientStartColor = Color(0xFF910EBF);
  static const Color _gradientEndColor = Color(0xFFFD3C6F);
  static const double _gradientAngleDegrees = 10.82;
  static const double _logoWidthRatio = 0.55;

  late AnimationController _logoController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _logoController.forward();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    final prefsFuture = SharedPreferences.getInstance();
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final prefs = await prefsFuture;
    final token = prefs.getString('auth_token');
    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainShell()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const StartScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isTablet = screenWidth > 600;

    const double smallScale = 0.78;
    const double mediumScale = 0.88;
    const double largeScale = 0.90;
    const double tabletScale = 1.20;

    final double scale = isTablet
        ? tabletScale
        : screenHeight < 680
            ? smallScale
            : screenHeight < 850
                ? mediumScale
                : largeScale;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: _calculateGradientBegin(_gradientAngleDegrees),
            end: _calculateGradientEnd(_gradientAngleDegrees),
            colors: const [_gradientStartColor, _gradientEndColor],
          ),
        ),
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Logo — centered, fade + scale + slide up
              Center(
                child: AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) => FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: child,
                      ),
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/logo-full-white.png',
                    width: (screenWidth * _logoWidthRatio) * scale,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                  ),
                ),
              ),

              // Modern loading dots — pinned to bottom center
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: Center(
                  child: const _FluidLoader(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Alignment _calculateGradientBegin(double degrees) {
    final radians = degrees * math.pi / 180;
    return Alignment(-math.sin(radians), math.cos(radians));
  }

  Alignment _calculateGradientEnd(double degrees) {
    final radians = degrees * math.pi / 180;
    return Alignment(math.sin(radians), -math.cos(radians));
  }
}

class _FluidLoader extends StatefulWidget {
  const _FluidLoader();

  @override
  State<_FluidLoader> createState() => _FluidLoaderState();
}

class _FluidLoaderState extends State<_FluidLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(72, 32),
          painter: _WavePainter(_controller.value),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.t);

  final double t;

  static const int _bars = 5;
  static const double _barW = 4.0;
  static const double _radius = 2.0;
  static const double _minH = 4.0;
  static const double _maxH = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final spacing = size.width / _bars;
    final cy = size.height / 2;

    for (int i = 0; i < _bars; i++) {
      // Each bar's phase offset creates the wave ripple
      final phase = (i / _bars) - t;
      final sine = math.sin(phase * 2 * math.pi); // -1 → 1
      final norm = (sine + 1) / 2; // 0 → 1

      final barH = _minH + (_maxH - _minH) * norm;
      final cx = spacing * i + spacing / 2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: _barW,
          height: barH,
        ),
        const Radius.circular(_radius),
      );

      // Opacity also rides the wave
      paint.color = Colors.white.withValues(alpha: 0.35 + 0.65 * norm);
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.t != t;
}
