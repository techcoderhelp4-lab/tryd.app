import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../../../widgets/custom_clock_icon.dart';
import '../../../../widgets/gradient_button.dart';
import '../../home/presentation/home_screen.dart';
import 'running_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import '../../club/presentation/club_screen.dart';
import '../../../../core/utils/responsive_utils.dart';
import 'package:tryd/src/generated/l10n/app_localizations.dart';

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
  final int _selectedIndex = 3; // Workout tab
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
    // ── Responsive Scale ──────────────────────────────────
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isTablet = screenWidth > 600;

    const double smallScale  = 0.85;
    const double mediumScale = 0.98;
    const double largeScale  = 0.95;
    const double tabletScale = 1.30;

    final double scale = isTablet
        ? tabletScale
        : screenHeight < 680
            ? smallScale
            : screenHeight < 850
                ? mediumScale
                : largeScale;

    final l10n = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isRTL ? 1.2 : 1.0;

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
            bottom: false,
            child: Column(
              children: [
                SizedBox(height: 10.0 * scale),
                _buildHeader(context, isTablet, scale, isRTL, fontScale),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 120.0 * scale),
                      child: Column(
                        children: [
                          SizedBox(height: (isTablet ? 40.0 : 30.0) * scale),
                          _buildClockIcon(scale),
                          SizedBox(height: (isTablet ? 40.0 : 30.0) * scale),
                          _buildTimeDisplay(scale, l10n, isRTL, fontScale),
                          SizedBox(height: (isTablet ? 50.0 : 40.0) * scale),
                          _buildWaveformSlider(scale),
                          SizedBox(height: (isTablet ? 50.0 : 40.0) * scale),
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

  Widget _buildHeader(BuildContext context, bool isTablet, double scale, bool isRTL, double fontScale) {
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
                child: Transform.scale(
                  scaleX: isRTL ? -1.0 : 1.0,
                  child: SvgPicture.asset(
                    'assets/images/back_arrow_icon.svg',
                    width: 24.0 * scale,
                    height: 24.0 * scale,
                  ),
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

  Widget _buildClockIcon(double scale) {
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
          child: CustomClockIcon(
            size: 80.0 * scale,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
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
            fontSize: 40.0 * scale,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF221F48),
          ),
        ),
        SizedBox(width: 8.0 * scale),
        Text(
          l10n.minsSuffix,
          style: isRTL
              ? GoogleFonts.cairo(
                  fontSize: 14.0 * scale * fontScale,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF221F48),
                )
              : GoogleFonts.roboto(
                  fontSize: 14.0 * scale,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF221F48),
                ),
        ),
      ],
    );
  }

  Widget _buildWaveformSlider(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.0 * scale),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          
          return Column(
            children: [
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  _updateTime(details.localPosition.dx, width);
                },
                onTapDown: (details) {
                  _updateTime(details.localPosition.dx, width);
                },
                child: SizedBox(
                  width: width,
                  height: 52.0 * scale,
                  child: CustomPaint(
                    size: Size(width, 52.0 * scale),
                    painter: _WaveformPainter(progress: _currentSeconds / 3600, scale: scale),
                  ),
                ),
              ),
              SizedBox(height: 12.0 * scale),
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  _updateTime(details.localPosition.dx, width);
                },
                onTapDown: (details) {
                  _updateTime(details.localPosition.dx, width);
                },
                child: SizedBox(
                  width: width,
                  height: 17.0 * scale,
                  child: Stack(
                    children: [
                      // Arrow indicator position
                      Positioned(
                        left: ((_currentSeconds / 3600) * width - 8.5 * scale).clamp(0.0, width - 17.0 * scale),
                        child: CustomPaint(
                          size: Size(17.0 * scale, 17.0 * scale),
                          painter: _TrianglePainter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildContinueButton(double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 36.0 * scale),
      child: GradientButton(
        text: l10n.continueButton,
        onPressed: () {
          Navigator.pop(context, _currentSeconds);
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

class _WaveformPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double scale;

  _WaveformPainter({required this.progress, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1 * scale
      ..strokeCap = StrokeCap.round;

    final spacing = size.width / 74; // Dynamic spacing based on width
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
        barHeight = 52.0 * scale; // Main selected bar
      } else if (distanceFromSelected == 1) {
        barHeight = 38.0 * scale; // Immediately adjacent
      } else if (distanceFromSelected == 2) {
        barHeight = 32.0 * scale; // Close to selected
      } else if (distanceFromSelected == 3) {
        barHeight = 28.0 * scale; // Near selected
      } else if (distanceFromSelected <= 5) {
        barHeight = 24.0 * scale; // Medium-close
      } else if (distanceFromSelected <= 8) {
        barHeight = 20.0 * scale; // Medium distance
      } else if (i % 5 == 0) {
        barHeight = 22.0 * scale; // Every 5th bar slightly taller
      } else if (i % 10 == 0) {
        barHeight = 26.0 * scale; // Every 10th bar even taller
      } else {
        barHeight = 16.0 * scale; // Default short bars
      }

      // Determine color based on distance from selection with smooth transitions
      if (i == selectedBarIndex) {
        paint.color = const Color(0xFFFF004A);
        paint.strokeWidth = 2.5 * scale;
      } else if (distanceFromSelected == 1) {
        paint.color = const Color(0xFFFC1857);
        paint.strokeWidth = 2 * scale;
      } else if (distanceFromSelected <= 3) {
        paint.color = const Color(0xFFF95383);
        paint.strokeWidth = 1.5 * scale;
      } else if (distanceFromSelected <= 6) {
        paint.color = const Color(0xFFFC7EA0);
        paint.strokeWidth = 1.2 * scale;
      } else {
        paint.color = const Color(0xFFFF96B5);
        paint.strokeWidth = 1 * scale;
      }

      // Special case: if value is minimum (15s ~= 0 on large scale), don't hide the bar
      if (progress < 0.01 && i == 0) {
         paint.color = const Color(0xFFFF004A);
         paint.strokeWidth = 2.5 * scale;
         barHeight = 52.0 * scale;
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
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => true;
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
