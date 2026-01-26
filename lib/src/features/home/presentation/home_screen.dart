import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../../widgets/custom_bottom_navigation.dart';
import '../../activity/presentation/running_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../activity/presentation/workout_screen.dart';
import '../../club/presentation/club_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';

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
                  SizedBox(height: 9.h),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.037),
                    child: Column(
                      children: [
                        _buildPointsCard(),
                        SizedBox(height: 8.h),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 0.037.sw),
                    child: _buildBannerCard(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.037),
                    child: Column(
                      children: [
                        SizedBox(height: 8.h),
                        _buildCurrentMonthCard(),
                        SizedBox(height: 16.h),
                        _buildStatsGrid(),
                        SizedBox(height: 140.h),
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
                  if (index == 0) {
                    // Already on home screen, do nothing
                  } else if (index == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RunningScreen(),
                      ),
                    );
                  } else if (index == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RewardsScreen(),
                      ),
                    );
                  } else if (index == 3) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkoutScreen(),
                      ),
                    );
                  } else if (index == 4) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClubScreen(),
                      ),
                    );
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
        0.037.sw,
        24.h,
        0.037.sw,
        15.h,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Container(
              width: 46.w,
              height: 46.h,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/profile.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello!',
                  style: GoogleFonts.lexendDeca(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    height: 1.29,
                    color: const Color(0xFF24252C),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Livia Vaccaro',
                  style: GoogleFonts.lexendDeca(
                    fontSize: 19.sp,
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
              Icon(
                Icons.notifications,
                size: 24.sp,
                color: const Color(0xFF24252C),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8.w,
                  height: 8.h,
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
      height: 66.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
        child: Row(
          children: [
            Container(
              width: 43.41.w,
              height: 44.86.h,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD66B),
                borderRadius: BorderRadius.circular(15.92.r),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/crown_icon.svg',
                  width: 25.32.w,
                  height: 21.71.h,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '12,450',
                    style: GoogleFonts.poppins(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w600,
                      height: 0.92,
                      color: const Color(0xFF221F48),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Your Available Points',
                    style: GoogleFonts.lexendDeca(
                      fontSize: 14.sp,
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
      borderRadius: BorderRadius.circular(22.r),
      child: SizedBox(
        width: double.infinity,
        height: 200.h,
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
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 19.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFF5F3F3).withValues(alpha: 0.62),
        ),
        borderRadius: BorderRadius.circular(15.r),
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
            width: 43.w,
            height: 43.h,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE4FF),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/runner_icon.svg',
                width: 16.w,
                height: 23.h,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Current Month',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    height: 1.54,
                    color: const Color(0xFF24252C),
                  ),
                ),
                Text(
                  '10.00 km',
                  style: GoogleFonts.poppins(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.16,
                    color: const Color(0xFF221F48),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.visibility,
            color: const Color(0xFF900EBF),
            size: 23.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return SizedBox(
      height: 294.h,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 10.w) / 2;

          return Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                width: cardWidth,
                child: _buildStatCard(
                  backgroundColor: const Color(0xFFEBF9FC),
                  iconBackgroundColor: const Color(0xFFD0F5FD),
                  svgIcon: 'assets/images/footsteps_icon.svg',
                  svgWidth: 21.w,
                  svgHeight: 21.h,
                  iconColor: const Color(0xFF34CDFD),
                  value: '1278',
                  label: 'Steps Count',
                  height: 152.h,
                  iconTopPadding: 22.h,
                  leftPadding: 25.w,
                  valueLabelGap: 5.h,
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                width: cardWidth,
                child: _buildStatCard(
                  backgroundColor: const Color(0xFFFFF8E8),
                  iconBackgroundColor: const Color(0xFFFFE8BA),
                  svgIcon: 'assets/images/fire_icon.svg',
                  svgWidth: 16.w,
                  svgHeight: 21.h,
                  iconColor: const Color(0xFFFEB720),
                  value: '934',
                  label: 'Burned Calories',
                  height: 130.h,
                  iconTopPadding: 15.h,
                  leftPadding: 25.w,
                  valueLabelGap: 3.h,
                ),
              ),
              Positioned(
                left: 0,
                top: 164.h,
                width: cardWidth,
                child: _buildStatCard(
                  backgroundColor: const Color(0xFFEFEAFC),
                  iconBackgroundColor: const Color(0xFFCDC0F4),
                  svgIcon: 'assets/images/clock_icon.svg',
                  svgWidth: 24.w,
                  svgHeight: 24.h,
                  iconColor: const Color(0xFF5D37E5),
                  value: '1:20',
                  label: 'Durations',
                  suffix: 'mins',
                  height: 130.h,
                  iconTopPadding: 16.h,
                  leftPadding: 25.w,
                  valueLabelGap: 3.h,
                ),
              ),
              Positioned(
                right: 0,
                top: 142.h,
                width: cardWidth,
                child: _buildStatCard(
                  backgroundColor: const Color(0xFFFFECEB),
                  iconBackgroundColor: const Color(0xFFFBC7C1),
                  icon: Icons.favorite,
                  iconColor: const Color(0xFFFE413D),
                  value: '114',
                  label: 'Average BPM',
                  height: 152.h,
                  iconTopPadding: 23.h,
                  leftPadding: 25.w,
                  valueLabelGap: 5.h,
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
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: leftPadding,
          top: iconTopPadding,
          right: 15.w,
          bottom: 15.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 43.w,
              height: 43.h,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: svgIcon != null
                    ? SvgPicture.asset(
                        svgIcon,
                        width: svgWidth ?? 21.w,
                        height: svgHeight ?? 21.h,
                      )
                    : Icon(
                        icon!,
                        color: iconColor,
                        size: 21.sp,
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
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w700,
                    height: 22 / 19,
                    color: Colors.black,
                  ),
                ),
                if (suffix != null) ...[
                  SizedBox(width: 9.w),
                  Padding(
                    padding: EdgeInsets.only(bottom: 3.h),
                    child: Text(
                      suffix,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
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
                fontSize: 15.sp,
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
