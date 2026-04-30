import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../widgets/custom_exercises_icon.dart';
import '../../../../widgets/custom_rounds_icon.dart';
import '../../../../widgets/gradient_button.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import 'package:tryd/src/generated/l10n/app_localizations.dart';
import '../../../../widgets/swipe_to_pop_wrapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shell/main_shell.dart' show mainNavTapProvider;

class AddNumberScreen extends ConsumerStatefulWidget {
  final String title;
  final int initialValue;
  final String iconType;
  final int minValue;
  final int maxValue;

  const AddNumberScreen({
    super.key,
    required this.title,
    required this.initialValue,
    required this.iconType,
    this.minValue = 1,
    this.maxValue = 99,
  });

  @override
  ConsumerState<AddNumberScreen> createState() => _AddNumberScreenState();
}

class _AddNumberScreenState extends ConsumerState<AddNumberScreen> {
  late int value;
  final int _selectedIndex = 3;
  Timer? _popTimer;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
  }

  void _increment() {
    setState(() {
      if (value < widget.maxValue) value++;
    });
    _startPopTimer();
  }

  void _decrement() {
    setState(() {
      if (value > widget.minValue) value--;
    });
    _startPopTimer();
  }

  @override
  void dispose() {
    _popTimer?.cancel();
    super.dispose();
  }

  void _startPopTimer() {
    _popTimer?.cancel();
    _popTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        Navigator.pop(context, value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isTablet = screenWidth > 600;
    final l10n = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isRTL ? 1.2 : 1.0;

    const double smallScale  = 0.85;
    const double mediumScale = 0.98;
    const double largeScale  = 1.05;
    const double tabletScale = 1.30;

    final double scale = isTablet
        ? tabletScale
        : screenHeight < 680
            ? smallScale
            : screenHeight < 850
                ? mediumScale
                : largeScale;

    return SwipeToPopWrapper(child: Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/bg-gradient.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(height: 10.0 * scale),
                _buildTopBar(isTablet, scale, isRTL, fontScale),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 120.0 * scale),
                      child: Column(
                        children: [
                          SizedBox(height: (isTablet ? 70.0 : 50.0) * scale),
                          _buildIconDisplay(scale),
                          SizedBox(height: (isTablet ? 70.0 : 60.0) * scale),
                          _buildNumberSelector(scale),
                          SizedBox(height: (isTablet ? 90.0 : 70.0) * scale),
                          _buildContinueButton(scale, l10n, isRTL, fontScale),
                          SizedBox(height: 20.0 * scale),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigation(
              currentIndex: _selectedIndex,
              onTap: (index) {
                if (index == 3) {
                  Navigator.of(context).pop();
                  return;
                }
                Navigator.of(context).popUntil((route) => route.isFirst);
                ref.read(mainNavTapProvider)?.call(index);
              },
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildTopBar(bool isTablet, double scale, bool isRTL, double fontScale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: (isTablet ? 20.0 : 26.0) * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: SizedBox(
              width: 40.0 * scale,
              height: 40.0 * scale,
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/back_arrow_icon.svg',
                  width: 24.0 * scale,
                  height: 24.0 * scale,
                  matchTextDirection: true,
                ),
              ),
            ),
          ),
          Text(
            widget.title,
            style: isRTL
                ? GoogleFonts.cairo(
                    fontSize: 19.0 * scale * fontScale,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF24252C),
                  )
                : GoogleFonts.lexendDeca(
                    fontSize: 19.0 * scale,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF24252C),
                  ),
          ),
          SizedBox(width: 40.0 * scale),
        ],
      ),
    );
  }

  Widget _buildIconDisplay(double scale) {
    final bool isExercises = widget.iconType == 'exercises';

    return Container(
      width: 148.0 * scale,
      height: 148.0 * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFFD66B),
          width: 2.0 * scale,
        ),
      ),
      child: Container(
        margin: EdgeInsets.all(12.0 * scale),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF900EBF),
        ),
        child: Center(
          child: isExercises
              ? CustomExercisesIcon(size: 60.0 * scale, color: Colors.white)
              : CustomRoundsIcon(size: 60.0 * scale, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildNumberSelector(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _decrement,
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF6E3AFF), Color(0xFFDB1DCD)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Text(
              '-',
              style: GoogleFonts.lexendDeca(
                fontSize: 60.0 * scale,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(width: 40.0 * scale),
        Text(
          value.toString().padLeft(2, '0'),
          style: GoogleFonts.lexendDeca(
            fontSize: 56.0 * scale,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B2D51),
          ),
        ),
        SizedBox(width: 40.0 * scale),
        GestureDetector(
          onTap: _increment,
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF6E3AFF), Color(0xFFDB1DCD)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Text(
              '+',
              style: GoogleFonts.lexendDeca(
                fontSize: 60.0 * scale,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 36.0 * scale),
      child: GradientButton(
        text: l10n.continueButton,
        onPressed: () {
          _popTimer?.cancel();
          Navigator.pop(context, value);
        },
        height: 58.0 * scale,
        textStyle: isRTL
            ? GoogleFonts.cairo(
                fontSize: 19.0 * fontScale,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}
