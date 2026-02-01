import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../../widgets/gradient_button.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/signup_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  static const Color _backgroundColor = Color(0xFFFFFFFF);
  static const Color _primaryTextColor = Color(0xFF24252C);
  static const Color _secondaryTextColor = Color(0xFF6E6A7C);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

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
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildHeadline(),
                            SizedBox(height: 10.h),
                            _buildSubtitle(),
                            SizedBox(height: 32.h),
                            _buildButton(context),
                            SizedBox(height: 30.h),
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

  Widget _buildHeadline() {
    return Text(
      'Every step brings you closer to your goals and greater rewards.',
      textAlign: TextAlign.center,
      style: GoogleFonts.lexendDeca(
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: _primaryTextColor,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'This productive tool is designed to help you better manage your task project-wise conveniently!',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: _secondaryTextColor,
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return GradientButton(
      text: "Get Started",
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SignupScreen(),
          ),
        );
      },
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: _secondaryTextColor,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          },
          child: Text(
            "Sign In",
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFF83A71),
            ),
          ),
        ),
      ],
    );
  }
}
