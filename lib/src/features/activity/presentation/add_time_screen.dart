import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import '../../../../widgets/custom_clock_icon.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;
import '../../../../widgets/gradient_button.dart';
import '../../home/presentation/home_screen.dart';
import 'running_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import 'workout_screen.dart';
import '../../club/presentation/club_screen.dart';

class AddTimeScreen extends StatefulWidget {
  final String title;
  final int initialSeconds;

  const AddTimeScreen({
    super.key,
    required this.title,
    required this.initialSeconds,
  });

  @override
  State<AddTimeScreen> createState() => _AddTimeScreenState();
}

class _AddTimeScreenState extends State<AddTimeScreen> {
  int _selectedIndex = 3; // Workout tab
  int _currentSeconds = 600; // Default 10 minutes (600 seconds)

  @override
  void initState() {
    super.initState();
    // Initialize with passed value if available, or default, snap to nearest 15
    int initial = widget.initialSeconds;
    if (initial <= 0) initial = 600;
    _currentSeconds = (initial / 15).round() * 15;
    if (_currentSeconds < 15) _currentSeconds = 15;
    if (_currentSeconds > 3600) _currentSeconds = 3600;
  }

  void _updateTime(double position, double width) {
    // Map position to 15s - 60 minutes (3600s)
    final normalizedPosition = (position / width).clamp(0.0, 1.0);
    
    // Calculate total seconds, snapped to 15s intervals
    int seconds = (normalizedPosition * 3600 / 15).round() * 15;
    
    // Clamp between 15s and 60m
    seconds = seconds.clamp(15, 3600);
    
    if (_currentSeconds != seconds) {
      setState(() {
        _currentSeconds = seconds;
      });
    }
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
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 28),
                _buildHeader(context),
                const SizedBox(height: 50),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Clock icon
                      _buildClockIcon(),
                      const SizedBox(height: 80),
                      // Time display
                      _buildTimeDisplay(),
                      const SizedBox(height: 48),
                      // Waveform slider
                      _buildWaveformSlider(),
                      const SizedBox(height: 48),
                      // Continue button
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
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
            'Add Time',
            style: GoogleFonts.lexendDeca(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF24252C),
            ),
          ),
          const SizedBox(width: 40), // Spacer for alignment
        ],
      ),
    );
  }

  Widget _buildClockIcon() {
    return Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFFD66B),
          width: 2,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF900EBF),
        ),
        child: const Center(
          child: CustomClockIcon(
            size: 80,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDisplay() {
    int minutes = _currentSeconds ~/ 60;
    int seconds = _currentSeconds % 60;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: GoogleFonts.lexend(
            fontSize: 40,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF221F48),
            height: 17 / 40,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'mins',
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF221F48),
            height: 31 / 14,
          ),
        ),
      ],
    );
  }

  Widget _buildWaveformSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              _updateTime(details.localPosition.dx, 370);
            },
            onTapDown: (details) {
              _updateTime(details.localPosition.dx, 370);
            },
            child: SizedBox(
              width: 370,
              height: 52,
              child: CustomPaint(
                size: const Size(370, 52),
                painter: _WaveformPainter(progress: _currentSeconds / 3600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              _updateTime(details.localPosition.dx, 370);
            },
            onTapDown: (details) {
              _updateTime(details.localPosition.dx, 370);
            },
            child: SizedBox(
              width: 370,
              height: 17,
              child: Stack(
                children: [
                  Positioned(
                    left: ((_currentSeconds / 3600) * 370 - 8.5).clamp(0.0, 370.0 - 17.0),
                    child: CustomPaint(
                      size: const Size(17, 17),
                      painter: _TrianglePainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: GradientButton(
        text: 'Continue',
        onPressed: () {
          // Return duration in seconds
          Navigator.pop(context, _currentSeconds);
        },
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  _WaveformPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final spacing = 5.0;
    final totalBars = 74;
    double x = 0;

    // Map progress to bar position
    final selectedBarIndex = (progress * (totalBars - 1)).round();

    for (int i = 0; i < totalBars; i++) {
      // Calculate distance from selected bar
      final distanceFromSelected = (i - selectedBarIndex).abs();

      // Determine bar height based on distance from selection with smooth gradients
      double barHeight;
      if (i == selectedBarIndex) {
        barHeight = 52; // Main selected bar
      } else if (distanceFromSelected == 1) {
        barHeight = 38; // Immediately adjacent
      } else if (distanceFromSelected == 2) {
        barHeight = 32; // Close to selected
      } else if (distanceFromSelected == 3) {
        barHeight = 28; // Near selected
      } else if (distanceFromSelected <= 5) {
        barHeight = 24; // Medium-close
      } else if (distanceFromSelected <= 8) {
        barHeight = 20; // Medium distance
      } else if (i % 5 == 0) {
        barHeight = 22; // Every 5th bar slightly taller
      } else if (i % 10 == 0) {
        barHeight = 26; // Every 10th bar even taller
      } else {
        barHeight = 16; // Default short bars
      }

      // Determine color based on distance from selection with smooth transitions
      if (i == selectedBarIndex) {
        paint.color = const Color(0xFFFF004A);
        paint.strokeWidth = 2.5;
      } else if (distanceFromSelected == 1) {
        paint.color = const Color(0xFFFC1857);
        paint.strokeWidth = 2;
      } else if (distanceFromSelected <= 3) {
        paint.color = const Color(0xFFF95383);
        paint.strokeWidth = 1.5;
      } else if (distanceFromSelected <= 6) {
        paint.color = const Color(0xFFFC7EA0);
        paint.strokeWidth = 1.2;
      } else {
        paint.color = const Color(0xFFFF96B5);
        paint.strokeWidth = 1;
      }

      // Special case: if value is minimum (15s ~= 0 on large scale), don't hide the bar
      if (progress < 0.01 && i == 0) {
         paint.color = const Color(0xFFFF004A);
         paint.strokeWidth = 2.5;
         barHeight = 52;
      }

      final y1 = (size.height - barHeight) / 2;
      final y2 = y1 + barHeight;

      canvas.drawLine(
        Offset(x, y1),
        Offset(x, y2),
        paint,
      );

      x += spacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF83A71)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
