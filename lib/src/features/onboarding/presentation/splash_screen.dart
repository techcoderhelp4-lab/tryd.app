import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryd/src/features/home/presentation/home_screen.dart';
import 'start_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color _gradientStartColor = Color(0xFF910EBF);
  static const Color _gradientEndColor = Color(0xFFFD3C6F);
  static const double _gradientAngleDegrees = 10.82;
  static const double _logoWidthRatio = 0.55;
  static const Duration _animationDuration = Duration(milliseconds: 1200);
  static const Duration _displayDuration = Duration(milliseconds: 2500);

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    // Preload token in parallel with splash display
    final prefsFuture = SharedPreferences.getInstance();
    await Future.delayed(_displayDuration);
    if (!mounted) return;

    final prefs = await prefsFuture;
    final token = prefs.getString('auth_token');

    if (mounted) {
      if (token != null && token.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const StartScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isTablet = screenWidth > 600;

    // Responsive scales aligned with recent UI polish
    const double smallScale  = 0.78;
    const double mediumScale = 0.88;
    const double largeScale  = 0.90;
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
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: child,
                ),
              );
            },
            child: Image.asset(
              'assets/images/logo-full-white.png',
              width: (screenWidth * _logoWidthRatio) * scale,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
            ),
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
