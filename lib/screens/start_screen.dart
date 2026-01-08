import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/gradient_button.dart';
import 'login_screen.dart';

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
                const Spacer(flex: 53),
                Expanded(
                  flex: 47,
                  child: _buildContentSection(context, screenWidth),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(BuildContext context, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.082),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildHeadline(),
          const SizedBox(height: 35),
          _buildSubtitle(),
          const SizedBox(height: 40),
          _buildButton(context),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildHeadline() {
    return Text(
      'Every step brings you closer to your goals and greater rewards.',
      textAlign: TextAlign.center,
      style: GoogleFonts.lexendDeca(
        fontSize: 24,
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
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: _secondaryTextColor,
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return GradientButton(
      text: "Let's Start",
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      },
    );
  }
}
