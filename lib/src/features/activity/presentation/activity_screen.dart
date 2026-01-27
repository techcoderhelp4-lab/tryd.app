import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import '../../../../widgets/custom_calendar_icon.dart';
import '../../../../widgets/button_shape_clipper.dart';
import '../data/activity_repository.dart';
import '../domain/workout.dart';
import '../domain/activity.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});
  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  int _selectedIndex = 3; // Workout tab
  String _selectedFilter = 'W';

  @override
  Widget build(BuildContext context) {
    final workoutHistoryAsync = ref.watch(workoutHistoryProvider);
    final activityListAsync = ref.watch(activityListProvider);

    // Combine data
    final List<dynamic> allActivities = [];
    if (workoutHistoryAsync.value != null) allActivities.addAll(workoutHistoryAsync.value!);
    if (activityListAsync.value != null) allActivities.addAll(activityListAsync.value!);

    // Sort by date descending
    allActivities.sort((a, b) => b.date.compareTo(a.date));

    // Calculate weekly data (last 7 days from today, matching Sunday-Saturday)
    final weeklyData = _calculateWeeklyData(allActivities);
    final totalWeeklyKm = weeklyData.fold(0.0, (sum, val) => sum + val);

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
                SizedBox(height: 28.h),
                _buildHeader(context),
                SizedBox(height: 30.h),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filter tabs
                          _buildFilterTabs(),
                          SizedBox(height: 30.h),
                          // This Week card
                          _buildWeekCard(totalWeeklyKm),
                          SizedBox(height: 22.h),
                          // Weekly chart
                          _buildWeeklyChart(weeklyData),
                          SizedBox(height: 22.h),
                          // Recent Activities heading
                          Text(
                            'Recent Activities',
                            style: GoogleFonts.lexendDeca(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF221F48),
                            ),
                          ),
                          SizedBox(height: 22.h),
                          // Activity List
                          ...allActivities.map((activity) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 22.h),
                              child: _buildActivityItem(activity),
                            );
                          }),
                          if (allActivities.isEmpty)
                             Center(child: Padding(
                               padding: EdgeInsets.all(20.h),
                               child: Text("No recent activities", style: GoogleFonts.lexend(color: Colors.grey)),
                             )),
                          SizedBox(height: 140.h),
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
                if (index == 0) {
                  Navigator.pop(context);
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
    );
  }

  List<double> _calculateWeeklyData(List<dynamic> activities) {
    final List<double> data = List.filled(7, 0.0);
    final now = DateTime.now();
    // Find limits for 'This Week' (Sun to Sat of current week)
    // Dart DateTime.weekday: Mon=1, Sun=7.
    // We want matching array index: 0=Sun, 1=Mon, ..., 6=Sat
    
    // Calculate start of week (Sunday)
    final currentWeekday = now.weekday; // 1-7
    // If today is Sunday(7), we want to go back 0 days to get start? No, usually start is Sunday. 
    // If today is Mon(1), start was yesterday.
    // daysSinceSunday = weekday % 7. (Sun=7%7=0, Mon=1%7=1...)
    final daysSinceSunday = now.weekday % 7;
    final startOfWeek = now.subtract(Duration(days: daysSinceSunday));
    final startOfSunday = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day); // midnight Sunday

    for (var act in activities) {
      if (act is Activity && act.date.isAfter(startOfSunday)) {
        // Find which day of week
        final dayIndex = act.date.weekday % 7; // 0=Sun
        data[dayIndex] += act.distance;
      } else if (act is Workout && act.date.isAfter(startOfSunday)) {
        // Workouts don't strictly have 'distance', but we can add something or ignore
        // If workout has distance
        if (act.distance != null) {
          final dayIndex = act.date.weekday % 7;
          data[dayIndex] += act.distance!;
        }
      }
    }
    return data;
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 26.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40.w,
              height: 40.h,
              alignment: Alignment.center,
              child: Transform.scale(
                scaleX: -1,
                child: CustomArrowIcon(
                  size: 24.sp,
                  color: const Color(0xFF130F26),
                ),
              ),
            ),
          ),
          Text(
            'Activity',
            style: GoogleFonts.lexendDeca(
              fontSize: 19.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF24252C),
            ),
          ),
          SizedBox(width: 40.w), // Spacer for alignment
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      width: double.infinity,
      height: 57.h,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFF5F3F3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 4),
            blurRadius: 32,
          ),
        ],
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 17.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFilterButton('W'),
            _buildFilterButton('M'),
            _buildFilterButton('Y'),
            _buildFilterButton('All'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text) {
    final isSelected = _selectedFilter == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = text;
        });
      },
      child: SizedBox(
        width: 63.w,
        height: 40.h,
        child: isSelected
            ? ClipPath(
                clipper: ButtonShapeClipper(),
                child: Container(
                  width: 63.w,
                  height: 40.h,
                  color: const Color(0xFF900EBF),
                  alignment: Alignment.center,
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : Container(
                alignment: Alignment.center,
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildWeekCard(double totalKm) {
    return Container(
      width: double.infinity,
      height: 205.h,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE8ECF4).withOpacity(0.49),
        ),
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Stack(
        children: [
          // Header with calendar icon and "This Week"
          Positioned(
            left: 18.w,
            top: 22.h,
            child: Row(
              children: [
                CustomCalendarIcon(
                  size: 24.sp,
                  color: const Color(0xFFF83A71),
                ),
                SizedBox(width: 7.w),
                Text(
                  'This Week',
                  style: GoogleFonts.poppins(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF221F48),
                    height: 22 / 19,
                  ),
                ),
              ],
            ),
          ),
          // Big number
          Positioned(
            left: 17.w,
            top: 76.h,
            child: Text(
              totalKm.toStringAsFixed(2),
              style: GoogleFonts.poppins(
                fontSize: 51.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF221F48),
                height: 22 / 51,
              ),
            ),
          ),
          // Kilometers text
          Positioned(
            left: 159.w,
            top: 80.h,
            child: Text(
              'Kilometers',
              style: GoogleFonts.roboto(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF221F48),
                height: 31 / 14,
              ),
            ),
          ),
          // Stats row (Static for now as we don't have full weekly aggregates for pace/time easily available without more logic)
          Positioned(
            left: 21.w,
            top: 126.h,
            child: Row(
              children: [
                _buildStatColumn('Run', '1'),
                SizedBox(width: 56.w),
                _buildStatColumn('Avg pace', '5:30'),
                SizedBox(width: 56.w),
                _buildStatColumn('Time', '20:45'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF221F48),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF221F48),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(List<double> weeklyData) {
    const maxMiles = 3.0; // Fixed max for scale flexibility
    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      width: double.infinity,
      height: 205.h,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE8ECF4).withOpacity(0.49),
        ),
        borderRadius: BorderRadius.circular(22.r),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Chart bars and grid
          Expanded(
            child: Column(
              children: [
                // Chart area
                Expanded(
                  child: Stack(
                    children: [
                      // Horizontal grid lines
                      Positioned.fill(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(4, (index) {
                            return Container(
                              width: double.infinity,
                              height: 1.h,
                              color: const Color(0xFFE8ECF4),
                            );
                          }),
                        ),
                      ),
                      // Bars
                      Positioned.fill(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: List.generate(dayLabels.length, (index) {
                            final miles = weeklyData[index];
                            final heightFactor = (miles / maxMiles).clamp(0.0, 1.0);
                            
                            return SizedBox(
                              width: 16.w,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  if (miles > 0)
                                    FractionallySizedBox(
                                      heightFactor: heightFactor,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF83A71),
                                          borderRadius: BorderRadius.circular(4.r),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                // X-axis labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(dayLabels.length, (index) {
                     return SizedBox(
                       width: 16.w,
                       child: Text(
                         dayLabels[index],
                         style: _chartLabelStyle(),
                         textAlign: TextAlign.center,
                       ),
                     );
                  }),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          // Right side: Y-axis labels
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('3', style: _chartLabelStyle()),
                    Text('2', style: _chartLabelStyle()),
                    Text('1', style: _chartLabelStyle()),
                    Text('0 mi', style: _chartLabelStyle()),
                  ],
                ),
              ),
              // Spacer to align with chart area (matches X-axis labels height + spacing)
              SizedBox(height: 8.h),
              Text('', style: _chartLabelStyle()),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _chartLabelStyle() {
    return GoogleFonts.roboto(
      fontSize: 14.sp,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF221F48),
      height: 31 / 14,
    );
  }

  Widget _buildActivityItem(dynamic activity) {
    String day = '';
    String km = '';
    String pace = '';
    String time = '';

    final now = DateTime.now();
    final date = activity.date;

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      day = 'Today';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      day = 'Yesterday';
    } else {
      day = DateFormat('EEEE').format(date); // Sunday, Monday...
    }

    if (activity is Workout) {
      // Mapping for HIIT
      km = '${activity.exercises ?? 0} Ex';
      pace = '${activity.rounds ?? 0} Rnds';
      
      final duration = Duration(seconds: activity.duration);
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      time = '$minutes:${seconds.toString().padLeft(2, '0')}';

    } else if (activity is Activity) {
      km = '${activity.distance} km';
      // Calculate pace?
      pace = '5:30'; // Placeholder
      final duration = Duration(seconds: activity.duration);
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      time = '$minutes:${seconds.toString().padLeft(2, '0')}';
    }

    return _buildActivityCard(
      day: day,
      kilometers: km,
      avgPace: pace,
      time: time,
    );
  }

  Widget _buildActivityCard({
    required String day,
    required String kilometers,
    required String avgPace,
    required String time,
  }) {
    return Container(
      width: double.infinity,
      height: 126.h,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE8ECF4).withOpacity(0.49),
        ),
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Stack(
        children: [
          // Header with calendar icon and day name
          Positioned(
            left: 18.w,
            top: 22.h,
            child: Row(
              children: [
                CustomCalendarIcon(
                  size: 24.sp,
                  color: const Color(0xFFF83A71),
                ),
                SizedBox(width: 7.w),
                Text(
                  day,
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF221F48),
                    height: 22 / 18,
                  ),
                ),
              ],
            ),
          ),
          // Stats row
          Positioned(
            left: 21.w,
            top: 52.h,
            child: Row(
              children: [
                _buildActivityStat(kilometers.contains('Ex') ? 'Exercises' : 'Kilometers', kilometers),
                SizedBox(width: 56.w),
                _buildActivityStat(avgPace.contains('Rnds') ? 'Rounds' : 'Avg pace', avgPace),
                SizedBox(width: 56.w),
                _buildActivityStat('Time', time),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8B88B5),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF221F48),
          ),
        ),
      ],
    );
  }
}
