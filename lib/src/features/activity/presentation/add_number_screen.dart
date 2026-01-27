import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../widgets/custom_exercises_icon.dart';
import '../../../../widgets/custom_rounds_icon.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import '../../../../widgets/gradient_button.dart';
import '../../../../widgets/custom_bottom_navigation.dart';

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
  int _selectedIndex = 3;

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
            child: Column(
              children: [
                const SizedBox(height: 28),
                _buildTopBar(),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(height: 50.h),
                      _buildIconDisplay(),
                      SizedBox(height: 60.h),
                      _buildNumberSelector(),
                      SizedBox(height: 60.h),
                      _buildContinueButton(),
                    ],
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
                if (index == 0) {
                  Navigator.pop(context);
                } else {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 26.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Transform.scale(
                scaleX: -1,
                child: const CustomArrowIcon(
                  size: 24,
                  color: Color(0xFF130F26),
                ),
              ),
            ),
          ),
          Text(
            widget.title,
            style: GoogleFonts.lexendDeca(
              fontSize: 19.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF24252C),
            ),
          ),
          SizedBox(width: 40.w),
        ],
      ),
    );
  }

  Widget _buildIconDisplay() {
    final bool isExercises = widget.iconType == 'exercises';

    return Container(
      width: 148.w, // Matches AddTimeScreen sizes
      height: 148.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFFD66B),
          width: 2,
        ),
      ),
      child: Container(
        margin: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF900EBF),
        ),
        child: Center(
          child: isExercises
              ? CustomExercisesIcon(
                  size: 60.sp, // Reduced size
                  color: Colors.white,
                )
              : CustomRoundsIcon(
                  size: 60.sp, // Reduced size
                  color: Colors.white,
                ),
        ),
      ),
    );
  }

  Widget _buildNumberSelector() {
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
                fontSize: 60.sp,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(width: 40.w),
        // Number without background container
        Text(
          value.toString().padLeft(2, '0'),
          style: GoogleFonts.lexendDeca(
            fontSize: 56.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B2D51),
          ),
        ),
        SizedBox(width: 40.w),
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
                fontSize: 60.sp,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 36.w),
      child: GradientButton(
        text: 'Continue',
        onPressed: () {
          Navigator.pop(context, value);
        },
      ),
    );
  }
}
