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
    return Container(
      height: 122,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -3),
            blurRadius: 11.6,
            color: const Color(0xFF8394B7).withValues(alpha: 0.11),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 95,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 27,
            child: Container(
              height: 95,
              color: Colors.white,
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 34.485,
            top: 0,
            child: Container(
              width: 68.97,
              height: 70,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 27,
            top: 0,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFF900EBF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/crown_icon.svg',
                    width: 30,
                    height: 26,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 57,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildNavItem(
                  svgIcon: 'assets/images/home_icon.svg',
                  svgWidth: 19,
                  svgHeight: 17,
                  label: 'Home',
                  isActive: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _buildNavItem(
                  svgIcon: 'assets/images/run_icon.svg',
                  svgWidth: 16,
                  svgHeight: 18,
                  label: 'Run',
                  isActive: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                const SizedBox(width: 54),
                _buildNavItem(
                  svgIcon: 'assets/images/workout_icon.svg',
                  svgWidth: 17,
                  svgHeight: 16,
                  label: 'Workout',
                  isActive: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
                _buildNavItem(
                  svgIcon: 'assets/images/club_icon.svg',
                  svgWidth: 18,
                  svgHeight: 18,
                  label: 'Club',
                  isActive: currentIndex == 4,
                  onTap: () => onTap(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String svgIcon,
    required double svgWidth,
    required double svgHeight,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? const Color(0xFF900EBF) : const Color(0xFF8B88B5);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              svgIcon,
              width: svgWidth,
              height: svgHeight,
              colorFilter: ColorFilter.mode(
                color,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.lexend(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.5,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
