import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      color: Colors.transparent,
      child: SizedBox(
        height: 137,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Custom painted background using SVG path
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomPaint(
                size: Size(screenWidth, 137),
                painter: BottomNavPainter(),
              ),
            ),
            
            // Floating Action Button (Center)
            Positioned(
              top: 14.6,
              left: screenWidth / 2 - 27,
              child: GestureDetector(
                onTap: () => onTap(2),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF900EBF),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/images/crown_icon.svg',
                      width: 24,
                      height: 24,
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
              bottom: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildNavItem(
                    svgIcon: 'assets/images/home_icon.svg',
                    label: 'Home',
                    isActive: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _buildNavItem(
                    svgIcon: 'assets/images/run_icon.svg',
                    label: 'Run',
                    isActive: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  const SizedBox(width: 60), // Space for center FAB
                  _buildNavItem(
                    svgIcon: 'assets/images/workout_icon.svg',
                    label: 'Workout',
                    isActive: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                  _buildNavItem(
                    svgIcon: 'assets/images/club_icon.svg',
                    label: 'Club',
                    isActive: currentIndex == 4,
                    onTap: () => onTap(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String svgIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? const Color(0xFF900EBF) : const Color(0xFF8B88B5);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              svgIcon,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                color,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.lexend(
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF) // Light lavender/gray background
      ..style = PaintingStyle.fill;

    // Scale factor to fit the design to screen width
    final scaleX = size.width / 402;
    // ScaleY is implicitly handled by the container height constraints

    final path = Path();
    
    // SVG Path data scaled to screen width
    // Original: M366 41.6001C385.882 41.6001 402 57.7178 402 77.6001V135.6C402 136.152 401.552 136.6 401 136.6H1C0.447715 136.6 2.31527e-08 136.152 0 135.6V77.6001C4.5101e-07 57.7178 16.1178 41.6001 36 41.6001H141.239C155.319 41.6001 166.286 54.1923 175.839 64.5345C182.131 71.3451 191.075 75.6001 201 75.6001C210.925 75.6001 219.869 71.3451 226.161 64.5345C235.714 54.1923 246.681 41.6001 260.761 41.6001H366Z
    
    // Start point (top-right before curve)
    path.moveTo(366 * scaleX, 41.6);
    
    // Top right rounded corner
    path.cubicTo(
      385.882 * scaleX, 41.6,
      402 * scaleX, 57.7178,
      402 * scaleX, 77.6001,
    );
    
    // Right side down
    path.lineTo(402 * scaleX, 135.6);
    
    // Bottom right corner (slight curve)
    path.cubicTo(
      402 * scaleX, 136.152,
      401.552 * scaleX, 136.6,
      401 * scaleX, 136.6,
    );
    
    // Bottom line
    path.lineTo(1 * scaleX, 136.6);
    
    // Bottom left corner
    path.cubicTo(
      0.447715 * scaleX, 136.6,
      0, 136.152,
      0, 135.6,
    );
    
    // Left side up
    path.lineTo(0, 77.6001);
    
    // Top left rounded corner
    path.cubicTo(
      0, 57.7178,
      16.1178 * scaleX, 41.6001,
      36 * scaleX, 41.6001,
    );
    
    // Left flat section
    path.lineTo(141.239 * scaleX, 41.6001);
    
    // Left curve going up (towards center button)
    path.cubicTo(
      155.319 * scaleX, 41.6001,
      166.286 * scaleX, 54.1923,
      175.839 * scaleX, 64.5345,
    );
    
    path.cubicTo(
      182.131 * scaleX, 71.3451,
      191.075 * scaleX, 75.6001,
      201 * scaleX, 75.6001,
    );
    
    // Right curve coming down from center
    path.cubicTo(
      210.925 * scaleX, 75.6001,
      219.869 * scaleX, 71.3451,
      226.161 * scaleX, 64.5345,
    );
    
    path.cubicTo(
      235.714 * scaleX, 54.1923,
      246.681 * scaleX, 41.6001,
      260.761 * scaleX, 41.6001,
    );
    
    // Right flat section
    path.lineTo(366 * scaleX, 41.6001);
    
    path.close();

    // Draw multiple shadow layers for smooth outer shadow on all sides
    final shadowPaint1 = Paint()
      ..color = const Color.fromRGBO(131, 148, 183, 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    
    final shadowPaint2 = Paint()
      ..color = const Color.fromRGBO(131, 148, 183, 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    
    final shadowPaint3 = Paint()
      ..color = const Color.fromRGBO(131, 148, 183, 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Draw shadow layers
    canvas.drawPath(path, shadowPaint1);
    canvas.drawPath(path, shadowPaint2);
    canvas.drawPath(path, shadowPaint3);

    // Add subtle border
    final borderPaint = Paint()
      ..color = const Color.fromRGBO(131, 148, 183, 0.12)
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
