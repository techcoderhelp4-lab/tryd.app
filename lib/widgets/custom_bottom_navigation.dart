import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../src/features/activity/presentation/running_screen.dart';
import '../src/generated/l10n/app_localizations.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

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
    
    final navHeight = 137.0 * scale;

    return RepaintBoundary(
      child: Container(
        color: Colors.transparent,
        child: SizedBox(
          height: navHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Custom painted background using SVG path
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CustomPaint(
                  size: Size(screenWidth, navHeight),
                  painter: BottomNavPainter(scale: scale),
                ),
              ),
              
              // Floating Action Button (Center)
              Positioned(
                top: 14.6 * scale,
                left: screenWidth / 2 - (27 * scale),
                child: GestureDetector(
                  onTap: () async { await onTap(2); },
                  child: Container(
                    width: 54.0 * scale,
                    height: 54.0 * scale,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF900EBF),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/crown_icon.svg',
                        width: 24.0 * scale,
                        height: 24.0 * scale,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Navigation Items
              Positioned(
                left: 0,
                right: 0,
                bottom: 24.0 * scale,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildNavItem(
                      svgIcon: 'assets/images/home_icon.svg',
                      label: l10n.navHome,
                      isActive: currentIndex == 0,
                      onTap: () async { await onTap(0); },
                      scale: scale,
                      isRTL: isRTL,
                    ),
                    _buildNavItem(
                      svgIcon: 'assets/images/run_icon.svg',
                      label: l10n.navRun,
                      isActive: currentIndex == 1,
                      onTap: () async { await onTap(1); },
                      scale: scale,
                      isRTL: isRTL,
                    ),
                    SizedBox(width: 60.0 * scale), // Space for center FAB
                    _buildNavItem(
                      svgIcon: 'assets/images/workout_icon.svg',
                      label: l10n.navWorkout,
                      isActive: currentIndex == 3,
                      onTap: () async { await onTap(3); },
                      scale: scale,
                      isRTL: isRTL,
                    ),
                    _buildNavItem(
                      svgIcon: 'assets/images/club_icon.svg',
                      label: l10n.navClub,
                      isActive: currentIndex == 4,
                      onTap: () async { await onTap(4); },
                      scale: scale,
                      isRTL: isRTL,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String svgIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required double scale,
    required bool isRTL,
  }) {
    final color = isActive ? const Color(0xFF900EBF) : const Color(0xFF8B88B5);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60.0 * scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              svgIcon,
              width: 24.0 * scale,
              height: 24.0 * scale,
              colorFilter: ColorFilter.mode(
                color,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(height: 4.0 * scale),
            Text(
              label,
              style: isRTL
                  ? GoogleFonts.tajawal(
                      fontSize: 12.0 * scale,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.5,
                    )
                  : GoogleFonts.tajawal(
                      fontSize: 12.0 * scale,
                      fontWeight: FontWeight.w700,
                      color: color,
                      height: 1.5,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavPainter extends CustomPainter {
  final double scale;
  
  BottomNavPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF) // Light lavender/gray background
      ..style = PaintingStyle.fill;

    // Scale factor to fit the design to screen width
    final scaleX = size.width / 402;
    final scaleY = scale; // Use the provided scale factor for vertical dimensions

    final path = Path();
    
    // SVG Path data scaled to screen width
    // Original: M366 41.6001C385.882 41.6001 402 57.7178 402 77.6001V135.6C402 136.152 401.552 136.6 401 136.6H1C0.447715 136.6 2.31527e-08 136.152 0 135.6V77.6001C4.5101e-07 57.7178 16.1178 41.6001 36 41.6001H141.239C155.319 41.6001 166.286 54.1923 175.839 64.5345C182.131 71.3451 191.075 75.6001 201 75.6001C210.925 75.6001 219.869 71.3451 226.161 64.5345C235.714 54.1923 246.681 41.6001 260.761 41.6001H366Z
    
    // Start point (top-right before curve)
    path.moveTo(366 * scaleX, 41.6 * scaleY);
    
    // Top right rounded corner
    path.cubicTo(
      385.882 * scaleX, 41.6 * scaleY,
      402 * scaleX, 57.7178 * scaleY,
      402 * scaleX, 77.6001 * scaleY,
    );
    
    // Right side down
    path.lineTo(402 * scaleX, 135.6 * scaleY);
    
    // Bottom right corner (slight curve)
    path.cubicTo(
      402 * scaleX, 136.152 * scaleY,
      401.552 * scaleX, 136.6 * scaleY,
      401 * scaleX, 136.6 * scaleY,
    );
    
    // Bottom line
    path.lineTo(1 * scaleX, 136.6 * scaleY);
    
    // Bottom left corner
    path.cubicTo(
      0.447715 * scaleX, 136.6 * scaleY,
      0, 136.152 * scaleY,
      0, 135.6 * scaleY,
    );
    
    // Left side up
    path.lineTo(0, 77.6001 * scaleY);
    
    // Top left rounded corner
    path.cubicTo(
      0, 57.7178 * scaleY,
      16.1178 * scaleX, 41.6001 * scaleY,
      36 * scaleX, 41.6001 * scaleY,
    );
    
    // Left flat section
    path.lineTo(141.239 * scaleX, 41.6001 * scaleY);
    
    // Left curve going up (towards center button)
    path.cubicTo(
      155.319 * scaleX, 41.6001 * scaleY,
      166.286 * scaleX, 54.1923 * scaleY,
      175.839 * scaleX, 64.5345 * scaleY,
    );
    
    path.cubicTo(
      182.131 * scaleX, 71.3451 * scaleY,
      191.075 * scaleX, 75.6001 * scaleY,
      201 * scaleX, 75.6001 * scaleY,
    );
    
    // Right curve coming down from center
    path.cubicTo(
      210.925 * scaleX, 75.6001 * scaleY,
      219.869 * scaleX, 71.3451 * scaleY,
      226.161 * scaleX, 64.5345 * scaleY,
    );
    
    path.cubicTo(
      235.714 * scaleX, 54.1923 * scaleY,
      246.681 * scaleX, 41.6001 * scaleY,
      260.761 * scaleX, 41.6001 * scaleY,
    );
    
    // Right flat section
    path.lineTo(366 * scaleX, 41.6001 * scaleY);
    
    path.close();

    // Shadow layers — opacity raised so the white shape is visible on white backgrounds
    final shadowPaint1 = Paint()
      ..color = const Color.fromRGBO(131, 148, 183, 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    final shadowPaint2 = Paint()
      ..color = const Color.fromRGBO(131, 148, 183, 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final shadowPaint3 = Paint()
      ..color = const Color.fromRGBO(131, 148, 183, 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Draw shadow layers
    canvas.drawPath(path, shadowPaint1);
    canvas.drawPath(path, shadowPaint2);
    canvas.drawPath(path, shadowPaint3);

    // Visible border
    final borderPaint = Paint()
      ..color = const Color.fromRGBO(131, 148, 183, 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw the path with fill
    canvas.drawPath(path, paint);
    
    // Draw the border
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

