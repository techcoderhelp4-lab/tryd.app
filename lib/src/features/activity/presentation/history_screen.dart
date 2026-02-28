import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import '../../../../widgets/custom_calendar_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/activity_repository.dart';
import '../domain/workout.dart';
import '../../home/presentation/home_screen.dart';
import 'running_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import 'workout_screen.dart';
import '../../club/presentation/club_screen.dart';
import '../../../../widgets/skeleton_loading.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _selectedIndex = 3; // History/Workout tab

  @override
  Widget build(BuildContext context) {
    // ── Responsive Scale ──────────────────────────────────
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

    final workoutHistoryAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
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
                SizedBox(height: 15.0 * scale),
                _buildHeader(context, isTablet, scale),
                SizedBox(height: 30.0 * scale),
                Expanded(
                  child: workoutHistoryAsync.when(
                    data: (history) => history.isEmpty 
                      ? Center(child: Text("No workouts yet", style: GoogleFonts.lexend(color: Colors.grey, fontSize: 14.0 * scale)))
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 20.0 * scale),
                          itemCount: history.length,
                          separatorBuilder: (_, __) => SizedBox(height: 15.0 * scale),
                          itemBuilder: (context, index) {
                            return _buildHistoryCard(history[index], isTablet, scale);
                          },
                        ),
                    loading: () => HistorySkeletonLoading(scale: scale, isTablet: isTablet),
                    error: (e, _) => Center(child: Text("Error: $e")),
                  ),
                ),
                SizedBox(height: 120.0 * scale),
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

  Widget _buildHeader(BuildContext context, bool isTablet, double scale) {
    final horizontalPadding = 30.0 * scale;
    final iconContainerSize = 45.0 * scale;
    final arrowSize = 24.0 * scale;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: iconContainerSize,
              height: iconContainerSize,
              alignment: Alignment.center,
              child: Transform.scale(
                scaleX: -1,
                child: CustomArrowIcon(
                  size: arrowSize,
                  color: const Color(0xFF130F26),
                ),
              ),
            ),
          ),
          Text(
            'History',
            style: GoogleFonts.lexendDeca(
              fontSize: 19.0 * scale,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF24252C),
            ),
          ),
          SizedBox(width: iconContainerSize), // Spacer for alignment
        ],
      ),
    );
  }

  String _formatDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    }
    return DateFormat('dd MMM yyyy').format(date);
  }

  Widget _buildHistoryCard(Workout workout, bool isTablet, double scale) {
    final padding = 18.0 * scale;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE8ECF4).withValues(alpha: 0.49),
        ),
        borderRadius: BorderRadius.circular(22.0 * scale),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomCalendarIcon(
                  size: 24.0 * scale,
                  color: const Color(0xFFF83A71),
                ),
                SizedBox(width: 7 * scale),
                Text(
                  _formatDay(workout.date),
                  style: GoogleFonts.poppins(
                    fontSize: 19.0 * scale,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF221F48),
                    height: 1.15,
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.0 * scale),
            _buildStatsRow(workout, isTablet, scale),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(Workout workout, bool isTablet, double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildStatItem('Work', '${workout.workDuration ?? 0}s', isTablet, scale),
        _buildStatItem('Rest', '${workout.restDuration ?? 0}s', isTablet, scale),
        _buildStatItem('Ex', '${workout.exercises ?? 0}', isTablet, scale),
        _buildStatItem('Rounds', '${workout.rounds ?? 0}', isTablet, scale),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, bool isTablet, double scale) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14.0 * scale,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF221F48),
            height: 2.2,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 24.0 * scale,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF221F48),
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
