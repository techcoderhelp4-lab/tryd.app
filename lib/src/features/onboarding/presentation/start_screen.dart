import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../../widgets/gradient_button.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../../generated/l10n/app_localizations.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  static const Color _backgroundColor = Color(0xFFFFFFFF);
  static const Color _primaryTextColor = Color(0xFF24252C);
  static const Color _secondaryTextColor = Color(0xFF6E6A7C);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isTablet = screenWidth > 600;

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

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/start.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              cacheWidth: null,
              cacheHeight: null,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 42),
                Expanded(
                  flex: 58,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0 * scale),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildHeadline(scale, l10n, isRTL),
                            SizedBox(height: 10.0 * scale),
                            _buildSubtitle(scale, l10n, isRTL),
                            SizedBox(height: 32.0 * scale),
                            _buildButton(context, scale, l10n),
                            SizedBox(height: 30.0 * scale),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // _buildContentSection is no longer needed as independent widget since we moved it inline for better Spacer access
  // or we can keep it if we structure it right, but inline inside SliverFillRemaining is easier for the Spacer.
  // We will keep helper methods for headline, subtitle etc.

  Widget _buildHeadline(double scale, AppLocalizations l10n, bool isRTL) {
    return Text(
      l10n.startHeadline,
      textAlign: TextAlign.center,
      style: isRTL
          ? GoogleFonts.tajawal(
              fontSize: 24.0 * scale,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: _primaryTextColor,
            )
          : GoogleFonts.tajawal(
              fontSize: 24.0 * scale,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: _primaryTextColor,
              letterSpacing: -0.2,
            ),
    );
  }

  Widget _buildSubtitle(double scale, AppLocalizations l10n, bool isRTL) {
    return Text(
      l10n.startSubtitle,
      textAlign: TextAlign.center,
      style: isRTL
          ? GoogleFonts.tajawal(
              fontSize: 14.0 * scale,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: _secondaryTextColor,
            )
          : GoogleFonts.tajawal(
              fontSize: 14.0 * scale,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: _secondaryTextColor,
            ),
    );
  }

  Widget _buildButton(BuildContext context, double scale, AppLocalizations l10n) {
    return GradientButton(
      text: l10n.getStarted,
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AuthScreen(),
          ),
        );
      },
      height: 58.0 * scale,
    );
  }

  Widget _buildLoginLink(BuildContext context, double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: GoogleFonts.tajawal(
            fontSize: 14.0 * scale,
            fontWeight: FontWeight.w600,
            color: _secondaryTextColor,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AuthScreen(),
              ),
            );
          },
          child: Text(
            "Sign In",
            style: GoogleFonts.tajawal(
              fontSize: 14.0 * scale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFF83A71),
            ),
          ),
        ),
      ],
    );
  }
}

