import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/custom_exercises_icon.dart';
import '../widgets/custom_rounds_icon.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            image: AssetImage('assets/images/bg-gradient.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildIconDisplay(),
                      SizedBox(height: 40.h),
                      _buildNumberSelector(),
                      SizedBox(height: 40.h),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.only(left: 26.w, right: 26.w, top: 28.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: SizedBox(
              width: 28.w,
              height: 28.w,
              child: SvgPicture.asset(
                'assets/images/back_arrow_icon.svg',
                width: 28.w,
                height: 28.w,
              ),
            ),
          ),
          Text(
            widget.title.toUpperCase(),
            style: GoogleFonts.lexend(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B2D51),
            ),
          ),
          SizedBox(width: 28.w),
        ],
      ),
    );
  }

  Widget _buildIconDisplay() {
    final bool isExercises = widget.iconType == 'exercises';
    final Color primaryColor = isExercises ? const Color(0xFF5D37E5) : const Color(0xFFF83A71);

    return Container(
      width: 120.w,
      height: 120.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: primaryColor,
          width: 4,
        ),
      ),
      child: Container(
        margin: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF900EBF),
          ),
          child: Center(
            child: isExercises
                ? CustomExercisesIcon(
                    size: 40.sp,
                    color: Colors.white,
                  )
                : CustomRoundsIcon(
                    size: 40.sp,
                    color: Colors.white,
                  ),
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
        SizedBox(width: 30.w),
        Container(
          width: 120.w,
          height: 120.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 4),
                blurRadius: 32,
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: GoogleFonts.lexendDeca(
                fontSize: 56.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B2D51),
              ),
            ),
          ),
        ),
        SizedBox(width: 30.w),
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

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, value);
      },
      child: Container(
        width: 200.w,
        height: 56.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6E3AFF), Color(0xFFDB1DCD)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 16,
              color: const Color(0xFF6E3AFF).withValues(alpha: 0.3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'SAVE',
            style: GoogleFonts.lexend(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
