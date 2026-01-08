import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/custom_bottom_navigation.dart';
import 'running_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(screenWidth),
                  const SizedBox(height: 9),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.037),
                    child: Column(
                      children: [
                        _buildPointsCard(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: screenWidth * 0.037),
                    child: _buildBannerCard(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.037),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildCurrentMonthCard(),
                        const SizedBox(height: 16),
                        _buildStatsGrid(),
                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNavigation(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  if (index == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RunningScreen(),
                      ),
                    );
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
      ),
    );
  }

  Widget _buildHeader(double screenWidth) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.037,
        24,
        screenWidth * 0.037,
        15,
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 46,
              height: 46,
              child: SvgPicture.asset(
                'assets/images/profile.svg',
                fit: BoxFit.cover,
                semanticsLabel: 'Profile Picture',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello!',
                  style: GoogleFonts.lexendDeca(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.29,
                    color: const Color(0xFF24252C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Livia Vaccaro',
                  style: GoogleFonts.lexendDeca(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    height: 1.26,
                    color: const Color(0xFF24252C),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              const Icon(
                Icons.notifications,
                size: 24,
                color: Color(0xFF24252C),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF83A71),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard() {
    return SizedBox(
      height: 66,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 43.41,
              height: 44.86,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD66B),
                borderRadius: BorderRadius.circular(15.92),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/crown_icon.svg',
                  width: 25.32,
                  height: 21.71,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '12,450',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 0.92,
                      color: const Color(0xFF221F48),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your Available Points',
                    style: GoogleFonts.lexendDeca(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1,
                      color: const Color(0xFF221F48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: double.infinity,
        height: 200,
        child: Image.asset(
          'assets/images/banner.png',
          fit: BoxFit.cover,
          semanticLabel: 'Promotional Banner',
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFEEEEEE),
            child: const Center(
              child: Icon(Icons.broken_image),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentMonthCard() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFF5F3F3).withValues(alpha: 0.62),
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 32,
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE4FF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/runner_icon.svg',
                width: 16,
                height: 23,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Current Month',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.54,
                    color: const Color(0xFF24252C),
                  ),
                ),
                Text(
                  '10.00 km',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.16,
                    color: const Color(0xFF221F48),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.visibility,
            color: Color(0xFF900EBF),
            size: 23,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return SizedBox(
      height: 294,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 10) / 2;

          return Stack(
            children: [
              // Top row - Steps Count (left)
              Positioned(
                left: 0,
                top: 0,
                width: cardWidth,
                child: _buildStatCard(
                  backgroundColor: const Color(0xFFEBF9FC),
                  iconBackgroundColor: const Color(0xFFD0F5FD),
                  svgIcon: 'assets/images/footsteps_icon.svg',
                  svgWidth: 21,
                  svgHeight: 21,
                  iconColor: const Color(0xFF34CDFD),
                  value: '1278',
                  label: 'Steps Count',
                  height: 152,
                  iconTopPadding: 22,
                  leftPadding: 25,
                  valueLabelGap: 5,
                ),
              ),
              // Top row - Burned Calories (right)
              Positioned(
                right: 0,
                top: 0,
                width: cardWidth,
                child: _buildStatCard(
                  backgroundColor: const Color(0xFFFFF8E8),
                  iconBackgroundColor: const Color(0xFFFFE8BA),
                  svgIcon: 'assets/images/fire_icon.svg',
                  svgWidth: 16,
                  svgHeight: 21,
                  iconColor: const Color(0xFFFEB720),
                  value: '934',
                  label: 'Burned Calories',
                  height: 130,
                  iconTopPadding: 15,
                  leftPadding: 25,
                  valueLabelGap: 3,
                ),
              ),
              // Bottom row - Durations (left)
              Positioned(
                left: 0,
                top: 164,
                width: cardWidth,
                child: _buildStatCard(
                  backgroundColor: const Color(0xFFEFEAFC),
                  iconBackgroundColor: const Color(0xFFCDC0F4),
                  svgIcon: 'assets/images/clock_icon.svg',
                  svgWidth: 24,
                  svgHeight: 24,
                  iconColor: const Color(0xFF5D37E5),
                  value: '1:20',
                  label: 'Durations',
                  suffix: 'mins',
                  height: 130,
                  iconTopPadding: 16,
                  leftPadding: 25,
                  valueLabelGap: 3,
                ),
              ),
              // Bottom row - Average BPM (right)
              Positioned(
                right: 0,
                top: 142,
                width: cardWidth,
                child: _buildStatCard(
                  backgroundColor: const Color(0xFFFFECEB),
                  iconBackgroundColor: const Color(0xFFFBC7C1),
                  icon: Icons.favorite,
                  iconColor: const Color(0xFFFE413D),
                  value: '114',
                  label: 'Average BPM',
                  height: 152,
                  iconTopPadding: 23,
                  leftPadding: 25,
                  valueLabelGap: 5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required Color backgroundColor,
    required Color iconBackgroundColor,
    IconData? icon,
    String? svgIcon,
    required Color iconColor,
    required String value,
    required String label,
    required double height,
    required double iconTopPadding,
    required double leftPadding,
    required double valueLabelGap,
    String? suffix,
    double? svgWidth,
    double? svgHeight,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: leftPadding,
          top: iconTopPadding,
          right: 15,
          bottom: 15,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: svgIcon != null
                    ? SvgPicture.asset(
                        svgIcon,
                        width: svgWidth ?? 21,
                        height: svgHeight ?? 21,
                      )
                    : Icon(
                        icon!,
                        color: iconColor,
                        size: 21,
                      ),
              ),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 22 / 19,
                    color: Colors.black,
                  ),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 9),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      suffix,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 15 / 13,
                        color: const Color(0xFF8B88B5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: valueLabelGap),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 15 / 15,
                color: const Color(0xFF8B88B5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
