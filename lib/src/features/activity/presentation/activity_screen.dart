import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import '../../../../widgets/custom_calendar_icon.dart';
import '../../../../widgets/button_shape_clipper.dart';
import '../data/activity_repository.dart';
import '../domain/workout.dart';
import '../domain/activity.dart';
import '../domain/activity_stats.dart';
import '../../home/presentation/home_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import 'running_screen.dart';
import 'workout_screen.dart';
import '../../club/presentation/club_screen.dart';

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
    // ── Responsive Scale ──────────────────────────────────
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isTablet = screenWidth > 600;

    final double smallScale  = 0.85;
    final double mediumScale = 0.98;
    final double largeScale  = 1.05;
    final double tabletScale = 1.30;

    final double scale = isTablet
        ? tabletScale
        : screenHeight < 680
            ? smallScale
            : screenHeight < 850
                ? mediumScale
                : largeScale;
    
    final workoutHistoryAsync = ref.watch(workoutHistoryProvider);
    final activityListAsync = ref.watch(activityListProvider);
    
    final period = _selectedFilter == 'W' ? 'week' 
                 : _selectedFilter == 'M' ? 'month' 
                 : _selectedFilter == 'Y' ? 'year' 
                 : 'all';
    final statsAsync = ref.watch(activityStatsProvider(period));

    // Use unified list from activityListProvider AND workoutHistoryProvider
    final List<dynamic> allItems = [];
    if (activityListAsync.value != null) {
      allItems.addAll(activityListAsync.value!);
    }
    if (workoutHistoryAsync.value != null) {
      allItems.addAll(workoutHistoryAsync.value!);
    }
    
    // Deduplicate by ID
    final seenIds = <String>{};
    allItems.retainWhere((a) => seenIds.add(a.id));
    
    allItems.sort((a, b) => b.date.compareTo(a.date));

    // Filter by period
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final allActivities = allItems.where((a) {
      if (_selectedFilter == 'All') return true;
      final date = a.date as DateTime;
      
      if (_selectedFilter == 'W') {
        return date.isAfter(today.subtract(const Duration(days: 7)));
      } else if (_selectedFilter == 'M') {
        return date.isAfter(today.subtract(const Duration(days: 30)));
      } else if (_selectedFilter == 'Y') {
        return date.isAfter(today.subtract(const Duration(days: 365)));
      }
      return true;
    }).toList();

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
                SizedBox(height: 15.0 * scale),
                _buildHeader(context, isTablet, scale),
                SizedBox(height: 20.0 * scale),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0 * scale),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filter tabs
                          _buildFilterTabs(isTablet, scale),
                          SizedBox(height: 20.0 * scale),
                          
                            statsAsync.when(
                              data: (stats) => Column(
                                children: [
                                  _buildWeekCard(stats, isTablet, scale),
                                  SizedBox(height: 16.0 * scale),
                                  _buildWeeklyChart(stats.dailyStats, isTablet, scale),
                                ],
                              ),
                              loading: () => _buildStatsSkeleton(isTablet, scale),
                            error: (e, _) => Center(child: Text("Error loading stats: $e")),
                          ),
                          
                          SizedBox(height: 20.0 * scale),
                          // Recent Activities heading
                          Text(
                            'Recent Activities',
                            style: GoogleFonts.lexendDeca(
                              fontSize: 18.0 * scale,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF221F48),
                            ),
                          ),
                          SizedBox(height: 16.0 * scale),
                          // Activity List
                          activityListAsync.when(
                            data: (activities) {
                              final bool isBackgroundLoading = activityListAsync.isRefreshing || activityListAsync.isReloading;
                              
                              if (allActivities.isEmpty) {
                                if (isBackgroundLoading || workoutHistoryAsync.isRefreshing) {
                                  return Column(
                                    children: List.generate(3, (index) => Padding(
                                      padding: EdgeInsets.only(bottom: 16.0 * scale),
                                      child: _buildActivitySkeleton(scale),
                                    )),
                                  );
                                }
                                return Center(child: Padding(
                                  padding: EdgeInsets.all(20.0 * scale),
                                  child: Text("No recent activities", style: GoogleFonts.lexend(color: Colors.grey, fontSize: 14.0 * scale)),
                                ));
                              }

                              return Column(
                                children: [
                                  if (isBackgroundLoading && activities.isEmpty)
                                     ...List.generate(3, (index) => Padding(
                                      padding: EdgeInsets.only(bottom: 16.0 * scale),
                                      child: _buildActivitySkeleton(scale),
                                    ))
                                  else
                                    ...allActivities.map((activity) {
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 16.0 * scale),
                                        child: _buildActivityItem(activity, isTablet, scale),
                                      );
                                    }),
                                ],
                              );
                            },
                            loading: () => Column(
                              children: List.generate(3, (index) => Padding(
                                padding: EdgeInsets.only(bottom: 16.0 * scale),
                                child: _buildActivitySkeleton(scale),
                              )),
                            ),
                            error: (e, _) => Center(child: Text("Error loading activities: $e")),
                          ),
                          SizedBox(height: 120.0 * scale),
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
                  return;
                }

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
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
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
            'Activity',
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

  Widget _buildFilterTabs(bool isTablet, double scale) {
    final height = 60.0 * scale;
    final horizontalPadding = 17.0 * scale;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFF5F3F3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 32,
          ),
        ],
        borderRadius: BorderRadius.circular(15.0 * scale),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFilterButton('W', isTablet, scale),
            _buildFilterButton('M', isTablet, scale),
            _buildFilterButton('Y', isTablet, scale),
            _buildFilterButton('All', isTablet, scale),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text, bool isTablet, double scale) {
    final isSelected = _selectedFilter == text;
    final width = 64.0 * scale;
    final height = 40.0 * scale;
    final fontSize = 14.0 * scale;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedFilter = text;
        });
      },
      child: SizedBox(
        width: width,
        height: height,
        child: isSelected
            ? ClipPath(
                clipper: ButtonShapeClipper(),
                child: Container(
                  width: width,
                  height: height,
                  color: const Color(0xFF900EBF),
                  alignment: Alignment.center,
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
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
                    fontSize: fontSize,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildWeekCard(ActivityStats stats, bool isTablet, double scale) {
    // Format duration (seconds to MM:SS)
    final duration = Duration(seconds: stats.totalDuration);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';
    final cardHeight = 220.0 * scale;
    final hPadding = 18.0 * scale;

    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE8ECF4).withValues(alpha: 0.49),
        ),
        borderRadius: BorderRadius.circular(22.0 * scale),
      ),
      child: Stack(
        children: [
          // Header with calendar icon and "This Week"
          Positioned(
            left: hPadding,
            top: 22.0 * scale,
            child: Row(
              children: [
                CustomCalendarIcon(
                  size: 24.0 * scale,
                  color: const Color(0xFFF83A71),
                ),
                SizedBox(width: 7.0 * scale),
                Text(
                  _selectedFilter == 'W' ? 'This Week' 
                  : _selectedFilter == 'M' ? 'This Month' 
                  : _selectedFilter == 'Y' ? 'This Year'
                  : 'All Activities',
                  style: GoogleFonts.poppins(
                    fontSize: 19.0 * scale,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF221F48),
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          // Big number
          Positioned(
            left: hPadding - 1,
            top: 76.0 * scale,
            child: Text(
              stats.totalDistance.toStringAsFixed(2),
              style: GoogleFonts.poppins(
                fontSize: 51.0 * scale,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF221F48),
                height: 1.0,
              ),
            ),
          ),
          // Kilometers text
          Positioned(
            left: 159.0 * scale,
            top: 80.0 * scale,
            child: Text(
              'Kilometers',
              style: GoogleFonts.roboto(
                fontSize: 14.0 * scale,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF221F48),
                height: 2.2,
              ),
            ),
          ),
          // Stats row
          Positioned(
            left: hPadding + 3,
            bottom: 25.0 * scale,
            child: Row(
              children: [
                _buildStatColumn('Count', stats.activityCount.toString(), isTablet, scale),
                SizedBox(width: 50.0 * scale),
                _buildStatColumn('Avg pace', _formatPace(stats.averagePace), isTablet, scale),
                SizedBox(width: 50.0 * scale),
                _buildStatColumn('Time', timeStr, isTablet, scale),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, bool isTablet, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14.0 * scale,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF221F48),
          ),
        ),
        SizedBox(height: 2.0 * scale),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18.0 * scale,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF221F48),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(List<DailyStat> dailyStats, bool isTablet, double scale) {
    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final List<double> weeklyData = List.filled(7, 0.0);

    for (var stat in dailyStats) {
      try {
        final statDate = DateTime.parse(stat.date);
        final dayIndex = statDate.weekday % 7;
        if (dayIndex < 7) {
          // Aggregate distance for same day of week (works for week/month/year)
          weeklyData[dayIndex] += stat.distance;
        }
      } catch (e) {
        debugPrint("Error parsing stat date: ${stat.date}");
      }
    }

    // Calculate max distance from aggregated data for correct scaling
    double maxDistance = 5.0;
    for (var dist in weeklyData) {
      if (dist > maxDistance) {
        maxDistance = dist;
      }
    }
    maxDistance = (maxDistance * 1.2).ceilToDouble(); // Add 20% headroom
    if (maxDistance == 0) maxDistance = 5.0;

    return Container(
      width: double.infinity,
      height: 205.0 * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE8ECF4).withValues(alpha: 0.49),
        ),
        borderRadius: BorderRadius.circular(22.0 * scale),
      ),
      padding: EdgeInsets.fromLTRB(16.0 * scale, 20.0 * scale, 16.0 * scale, 10.0 * scale),
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
                              height: 1.0 * scale,
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
                            final dist = weeklyData[index];
                            final heightFactor = (dist / maxDistance).clamp(0.0, 1.0);
                            
                            return SizedBox(
                              width: 16.0 * scale,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  if (dist > 0)
                                    FractionallySizedBox(
                                      heightFactor: heightFactor,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF83A71),
                                          borderRadius: BorderRadius.circular(4.0 * scale),
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
                SizedBox(height: 8.0 * scale),
                // X-axis labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(dayLabels.length, (index) {
                     return SizedBox(
                       width: 16.0 * scale,
                       child: Text(
                         dayLabels[index],
                         style: _chartLabelStyle(isTablet, scale),
                         textAlign: TextAlign.center,
                       ),
                     );
                  }),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.0 * scale),
          // Right side: Y-axis labels
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${maxDistance.toInt()}', style: _chartLabelStyle(isTablet, scale)),
                    Text('${(maxDistance * 0.6).toInt()}', style: _chartLabelStyle(isTablet, scale)),
                    Text('${(maxDistance * 0.2).toInt()}', style: _chartLabelStyle(isTablet, scale)),
                    Text('0 km', style: _chartLabelStyle(isTablet, scale)),
                  ],
                ),
              ),
              // Spacer to align with chart area
              SizedBox(height: 8.0 * scale),
              Text('', style: _chartLabelStyle(isTablet, scale)),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _chartLabelStyle(bool isTablet, double scale) {
    return GoogleFonts.roboto(
      fontSize: 14.0 * scale,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF221F48),
      height: 2.2,
    );
  }

  String _formatPace(double pace) {
    if (pace == 0 || pace.isInfinite || pace.isNaN) return '0:00';
    final minutes = pace.toInt();
    final seconds = ((pace - minutes) * 60).toInt();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildActivityItem(dynamic activity, bool isTablet, double scale) {
    String day = '';
    String km = '';
    String pace = '';
    String time = '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = activity.date;

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      day = 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
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
      km = '${activity.distance.toStringAsFixed(2)} km';
      pace = _formatPace(activity.averagePace);
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
      isTablet: isTablet,
      scale: scale,
    );
  }

  Widget _buildActivityCard({
    required String day,
    required String kilometers,
    required String avgPace,
    required String time,
    required bool isTablet,
    required double scale,
  }) {
    final cardHeight = 140.0 * scale;
    final hPadding = 18.0 * scale;

    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE8ECF4).withValues(alpha: 0.49),
        ),
        borderRadius: BorderRadius.circular(22.0 * scale),
      ),
      child: Stack(
        children: [
          // Header with calendar icon and day name
          Positioned(
            left: hPadding,
            top: 22.0 * scale,
            child: Row(
              children: [
                CustomCalendarIcon(
                  size: 24.0 * scale,
                  color: const Color(0xFFF83A71),
                ),
                SizedBox(width: 7.0 * scale),
                Text(
                  day,
                  style: GoogleFonts.poppins(
                    fontSize: 18.0 * scale,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF221F48),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Stats row
          Positioned(
            left: hPadding + 3,
            bottom: 25.0 * scale,
            child: Row(
              children: [
                _buildActivityStat(kilometers.contains('Ex') ? 'Exercises' : 'Kilometers', kilometers, isTablet, scale),
                SizedBox(width: 56.0 * scale),
                _buildActivityStat(avgPace.contains('Rnds') ? 'Rounds' : 'Avg pace', avgPace, isTablet, scale),
                SizedBox(width: 56.0 * scale),
                _buildActivityStat('Time', time, isTablet, scale),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStat(String label, String value, bool isTablet, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12.0 * scale,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8B88B5),
          ),
        ),
        SizedBox(height: 2.0 * scale),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16.0 * scale,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF221F48),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSkeleton(bool isTablet, double scale) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Column(
        children: [
          // Week card skeleton
          _buildSkeletonBox(height: 220.0 * scale, borderRadius: 22.0 * scale),
          SizedBox(height: 16.0 * scale),
          // Chart skeleton
          _buildSkeletonBox(height: 205.0 * scale, borderRadius: 22.0 * scale),
        ],
      ),
    );
  }

  Widget _buildActivitySkeleton(double scale) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: _buildSkeletonBox(height: 140.0 * scale, borderRadius: 22.0 * scale),
    );
  }

  Widget _buildSkeletonBox({required double height, required double borderRadius}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
