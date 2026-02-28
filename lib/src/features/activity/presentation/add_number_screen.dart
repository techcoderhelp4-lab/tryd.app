import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/custom_exercises_icon.dart';
import '../../../../widgets/custom_rounds_icon.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import '../../../../widgets/gradient_button.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../home/presentation/home_screen.dart';
import 'running_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import '../../club/presentation/club_screen.dart';

class AddNumberScreen extends StatefulWidget {
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
  State<AddNumberScreen> createState() => _AddNumberScreenState();
}

class _AddNumberScreenState extends State<AddNumberScreen> {
  late int value;
  final int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
  }

  void _increment() {
    setState(() {
      if (value < widget.maxValue) value++;
    });
  }

  void _decrement() {
    setState(() {
      if (value > widget.minValue) value--;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ── Responsive Scale ──────────────────────────────────
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient image
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
                _buildTopBar(isTablet, scale),
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
                          _buildContinueButton(scale),
                          SizedBox(height: 20.0 * scale),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
           // Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigation(
              currentIndex: _selectedIndex,
              onTap: (index) {
                if (index == 3) {
                  Navigator.pop(context);
                  return;
                }
                
                Widget? page;
                switch (index) {
                  case 0: page = const HomeScreen(); break;
                  case 1: page = const RunningScreen(); break;
                  case 2: page = const RewardsScreen(); break;
                  case 4: page = const ClubScreen(); break;
                }
                
                if (page != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => page!),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isTablet, double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: (isTablet ? 20.0 : 26.0) * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40.0 * scale,
              height: 40.0 * scale,
              alignment: Alignment.center,
              child: Transform.scale(
                scaleX: -1,
                child: CustomArrowIcon(
                  size: 24.0 * scale,
                  color: const Color(0xFF130F26),
                ),
              ),
            ),
          ),
          Text(
            widget.title,
            style: GoogleFonts.lexendDeca(
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
      width: 148.0 * scale, // Matches AddTimeScreen sizes
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
              ? CustomExercisesIcon(
                  size: 60.0 * scale, // Reduced size
                  color: Colors.white,
                )
              : CustomRoundsIcon(
                  size: 60.0 * scale, // Reduced size
                  color: Colors.white,
                ),
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
        // Number without background container
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

  Widget _buildContinueButton(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 36.0 * scale),
      child: GradientButton(
        text: 'Continue',
        onPressed: () {
          Navigator.pop(context, value);
        },
        height: 58.0 * scale,
      ),
    );
  }
}
