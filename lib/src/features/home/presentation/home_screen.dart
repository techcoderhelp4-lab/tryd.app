import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../../widgets/custom_bottom_navigation.dart';
import '../../activity/presentation/running_screen.dart';
import '../../activity/presentation/activity_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../activity/presentation/workout_screen.dart';
import '../../club/presentation/club_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import '../../profile/data/user_repository.dart';
import '../../auth/domain/user.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../notifications/data/notification_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final userAsync = ref.watch(userProfileProvider);
    final activityAsync = ref.watch(activitySummaryProvider('month'));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            userAsync.when(
              data: (user) => SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(screenWidth, user),
                    SizedBox(height: 9.h),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.black.withOpacity(0.1),
                    ),
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.037),
                      child: Column(
                        children: [
                          _buildPointsCard(user.points ?? 0),
                          SizedBox(height: 8.h),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 0.037.sw),
                      child: _buildBannerCard(),
                    ),
                    activityAsync.when(
                      data: (activityData) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.037),
                        child: Column(
                          children: [
                            SizedBox(height: 8.h),
                            _buildCurrentMonthCard(activityData),
                            SizedBox(height: 16.h),
                            _buildStatsGrid(activityData),
                            SizedBox(height: 140.h),
                          ],
                        ),
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(20.0),
                        child:  Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, stack) => Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text('Failed to load stats', style: GoogleFonts.poppins(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Something went wrong', style: GoogleFonts.poppins(color: Colors.red)),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNavigation(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  if (index == 0) return;
                  
                  Widget? page;
                  switch (index) {
                    case 1: page = const RunningScreen(); break;
                    case 2: page = const RewardsScreen(); break;
                    case 3: page = const WorkoutScreen(); break;
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
      ),
    );
  }

  Widget _buildHeader(double screenWidth, User user) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        0.037.sw,
        24.h,
        0.037.sw,
        15.h,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFCCCCCC),
                image: DecorationImage(
                  image: user.profilePicture != null && user.profilePicture!.isNotEmpty
                      ? NetworkImage(user.profilePicture!)
                      : const AssetImage('assets/images/profile.png') as ImageProvider,
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
                  user.name,
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
          SizedBox(width: 8.w),
          _buildNotificationBell(),
        ],
      ),
    );
  }

  Widget _buildNotificationBell() {
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 30.sp,
              color: const Color(0xFF24252C),
            ),
            unreadCountAsync.when(
              data: (count) {
                if (count == 0) return const SizedBox.shrink();
                return Positioned(
                  right: -2.w,
                  top: -2.h,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF83A71),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16.w,
                      minHeight: 16.w,
                    ),
                    child: Center(
                      child: Text(
                        count > 9 ? '9+' : count.toString(),
                        style: GoogleFonts.lexendDeca(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard(int points) {
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
                    points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
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

  Widget _buildCurrentMonthCard(Map<String, dynamic> data) {
    final distance = data['distance']?.toStringAsFixed(2) ?? '0.00';
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ActivityScreen()),
        );
      },
      child: Container(
        height: 80.h,
        padding: EdgeInsets.symmetric(horizontal: 19.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFF5F3F3).withOpacity(0.62),
          ),
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 32,
              color: Colors.black.withOpacity(0.04),
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
                    '$distance km',
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
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> data) {
    final steps = data['steps']?.toString() ?? '0';
    final calories = data['calories']?.toString() ?? '0';
    final duration = data['duration'] ?? '0:00'; // Assuming backend returns formatted str or handle minutes
    final bpm = data['bpm']?.toString() ?? '0'; // Placeholder as BPM is usually real-time or avg

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
                  value: steps,
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
                  value: calories,
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
                  value: duration,
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
                  value: bpm,
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
