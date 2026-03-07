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
import '../../../generated/l10n/app_localizations.dart';

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
    
    final l10n = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isRTL ? 1.2 : 1.0;

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
                _buildHeader(context, isTablet, scale, l10n, isRTL, fontScale),
                SizedBox(height: 20.0 * scale),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0 * scale),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filter tabs
                          _buildFilterTabs(isTablet, scale, l10n, isRTL, fontScale),
                          SizedBox(height: 20.0 * scale),

                          statsAsync.when(
                            data: (stats) => Column(
                              children: [
                                _buildWeekCard(stats, isTablet, scale, l10n, isRTL, fontScale),
                                SizedBox(height: 16.0 * scale),
                                _buildWeeklyChart(stats.dailyStats, isTablet, scale, isRTL),
                              ],
                            ),
                            loading: () => _buildStatsSkeleton(isTablet, scale),
                            error: (e, _) => Center(child: Text("Error loading stats: $e")),
                          ),

                          SizedBox(height: 20.0 * scale),
                          // Recent Activities heading
                          Text(
                            l10n.recentActivities,
                            style: isRTL
                                ? GoogleFonts.cairo(
                                    fontSize: 18.0 * scale * fontScale,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF221F48),
                                  )
                                : GoogleFonts.lexendDeca(
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
                                  child: Text(
                                    l10n.noRecentActivities,
                                    style: isRTL
                                        ? GoogleFonts.cairo(color: Colors.grey, fontSize: 14.0 * scale * fontScale)
                                        : GoogleFonts.lexend(color: Colors.grey, fontSize: 14.0 * scale),
                                  ),
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
                                        child: _buildActivityItem(activity, isTablet, scale, l10n, isRTL, fontScale),
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



  Widget _buildHeader(BuildContext context, bool isTablet, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
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
                scaleX: isRTL ? 1.0 : -1.0,
                child: CustomArrowIcon(
                  size: arrowSize,
                  color: const Color(0xFF130F26),
                ),
              ),
            ),
          ),
          Text(
            l10n.activityTitle,
            style: isRTL
                ? GoogleFonts.cairo(
                    fontSize: 19.0 * scale * fontScale,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF24252C),
                  )
                : GoogleFonts.lexendDeca(
                    fontSize: 19.0 * scale,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF24252C),
                  ),
          ),
          SizedBox(width: iconContainerSize),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(bool isTablet, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final height = 60.0 * scale;
    final horizontalPadding = 17.0 * scale;

    final buttons = [
      _buildFilterButton('W', l10n.filterWeekLabel, isTablet, scale, isRTL, fontScale),
      _buildFilterButton('M', l10n.filterMonthLabel, isTablet, scale, isRTL, fontScale),
      _buildFilterButton('Y', l10n.filterYearLabel, isTablet, scale, isRTL, fontScale),
      _buildFilterButton('All', l10n.filterAllLabel, isTablet, scale, isRTL, fontScale),
    ];

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
          children: isRTL ? buttons.reversed.toList() : buttons,
        ),
      ),
    );
  }

  Widget _buildFilterButton(String filterKey, String label, bool isTablet, double scale, bool isRTL, double fontScale) {
    final isSelected = _selectedFilter == filterKey;
    final width = 64.0 * scale;
    final height = 40.0 * scale;
    final fontSize = 13.0 * scale;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedFilter = filterKey;
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
                    label,
                    style: isRTL
                        ? GoogleFonts.cairo(fontSize: fontSize * fontScale, fontWeight: FontWeight.w400, color: Colors.white)
                        : GoogleFonts.poppins(fontSize: fontSize, fontWeight: FontWeight.w400, color: Colors.white),
                  ),
                ),
              )
            : Container(
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: isRTL
                      ? GoogleFonts.cairo(fontSize: fontSize * fontScale, fontWeight: FontWeight.w400, color: Colors.black)
                      : GoogleFonts.poppins(fontSize: fontSize, fontWeight: FontWeight.w400, color: Colors.black),
                ),
              ),
      ),
    );
  }

  Widget _buildWeekCard(ActivityStats stats, bool isTablet, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final duration = Duration(seconds: stats.totalDuration);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';
    final cardHeight = 220.0 * scale;
    final hPadding = 18.0 * scale;

    final periodLabel = _selectedFilter == 'W' ? l10n.thisWeek
        : _selectedFilter == 'M' ? l10n.thisMonth
        : _selectedFilter == 'Y' ? l10n.thisYear
        : l10n.allActivitiesLabel;

    final statColumns = [
      _buildStatColumn(l10n.countLabel, stats.activityCount.toString(), isTablet, scale, isRTL, fontScale),
      SizedBox(width: 50.0 * scale),
      _buildStatColumn(l10n.avgPaceShort, _formatPace(stats.averagePace), isTablet, scale, isRTL, fontScale),
      SizedBox(width: 50.0 * scale),
      _buildStatColumn(l10n.timeLabel, timeStr, isTablet, scale, isRTL, fontScale),
    ];

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
          // Header with calendar icon and period label
          Positioned(
            left: isRTL ? null : hPadding,
            right: isRTL ? hPadding : null,
            top: 22.0 * scale,
            child: Row(
              children: isRTL
                  ? [
                      Text(
                        periodLabel,
                        style: GoogleFonts.cairo(
                          fontSize: 19.0 * scale * fontScale,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF221F48),
                          height: 1.15,
                        ),
                      ),
                      SizedBox(width: 7.0 * scale),
                      CustomCalendarIcon(size: 24.0 * scale, color: const Color(0xFFF83A71)),
                    ]
                  : [
                      CustomCalendarIcon(size: 24.0 * scale, color: const Color(0xFFF83A71)),
                      SizedBox(width: 7.0 * scale),
                      Text(
                        periodLabel,
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
            left: isRTL ? null : hPadding - 1,
            right: isRTL ? hPadding - 1 : null,
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
            left: isRTL ? null : 159.0 * scale,
            right: isRTL ? 159.0 * scale : null,
            top: 80.0 * scale,
            child: Text(
              l10n.kilometersLabel,
              style: isRTL
                  ? GoogleFonts.cairo(
                      fontSize: 14.0 * scale * fontScale,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF221F48),
                      height: 2.2,
                    )
                  : GoogleFonts.roboto(
                      fontSize: 14.0 * scale,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF221F48),
                      height: 2.2,
                    ),
            ),
          ),
          // Stats row
          Positioned(
            left: isRTL ? null : hPadding + 3,
            right: isRTL ? hPadding + 3 : null,
            bottom: 25.0 * scale,
            child: Row(
              children: isRTL ? statColumns.reversed.toList() : statColumns,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, bool isTablet, double scale, bool isRTL, double fontScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: isRTL
              ? GoogleFonts.cairo(fontSize: 14.0 * scale * fontScale, fontWeight: FontWeight.w400, color: const Color(0xFF221F48))
              : GoogleFonts.roboto(fontSize: 14.0 * scale, fontWeight: FontWeight.w400, color: const Color(0xFF221F48)),
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

  Widget _buildWeeklyChart(List<DailyStat> dailyStats, bool isTablet, double scale, bool isRTL) {
    final dayLabels = isRTL
        ? ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س']
        : ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
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
                    Text('0 ${isRTL ? 'كم' : 'km'}', style: _chartLabelStyle(isTablet, scale)),
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

  Widget _buildActivityItem(dynamic activity, bool isTablet, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    String day = '';
    String km = '';
    String pace = '';
    String time = '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = activity.date as DateTime;

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      day = l10n.todayLabel;
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      day = l10n.yesterdayLabel;
    } else {
      day = DateFormat('EEEE', isRTL ? 'ar' : 'en').format(date);
    }

    if (activity is Workout) {
      km = '${activity.exercises ?? 0} ${l10n.exLabel}';
      pace = '${activity.rounds ?? 0} ${l10n.roundsLabel}';
      final duration = Duration(seconds: activity.duration);
      final mins = duration.inMinutes;
      final secs = duration.inSeconds % 60;
      time = '$mins:${secs.toString().padLeft(2, '0')}';
    } else if (activity is Activity) {
      km = '${activity.distance.toStringAsFixed(2)} ${l10n.kmSuffix}';
      pace = _formatPace(activity.averagePace);
      final duration = Duration(seconds: activity.duration);
      final mins = duration.inMinutes;
      final secs = duration.inSeconds % 60;
      time = '$mins:${secs.toString().padLeft(2, '0')}';
    }

    final isWorkout = activity is Workout;
    return _buildActivityCard(
      day: day,
      kilometers: km,
      avgPace: pace,
      time: time,
      isTablet: isTablet,
      scale: scale,
      l10n: l10n,
      isRTL: isRTL,
      fontScale: fontScale,
      isWorkout: isWorkout,
    );
  }

  Widget _buildActivityCard({
    required String day,
    required String kilometers,
    required String avgPace,
    required String time,
    required bool isTablet,
    required double scale,
    required AppLocalizations l10n,
    required bool isRTL,
    required double fontScale,
    required bool isWorkout,
  }) {
    final cardHeight = 140.0 * scale;
    final hPadding = 18.0 * scale;

    final statsRow = [
      _buildActivityStat(isWorkout ? l10n.exercisesLabel : l10n.kilometersLabel, kilometers, isTablet, scale, isRTL, fontScale),
      SizedBox(width: 56.0 * scale),
      _buildActivityStat(isWorkout ? l10n.roundsLabel : l10n.avgPaceShort, avgPace, isTablet, scale, isRTL, fontScale),
      SizedBox(width: 56.0 * scale),
      _buildActivityStat(l10n.timeLabel, time, isTablet, scale, isRTL, fontScale),
    ];

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
            left: isRTL ? null : hPadding,
            right: isRTL ? hPadding : null,
            top: 22.0 * scale,
            child: Row(
              children: isRTL
                  ? [
                      Text(
                        day,
                        style: GoogleFonts.cairo(
                          fontSize: 18.0 * scale * fontScale,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF221F48),
                          height: 1.2,
                        ),
                      ),
                      SizedBox(width: 7.0 * scale),
                      CustomCalendarIcon(size: 24.0 * scale, color: const Color(0xFFF83A71)),
                    ]
                  : [
                      CustomCalendarIcon(size: 24.0 * scale, color: const Color(0xFFF83A71)),
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
            left: isRTL ? null : hPadding + 3,
            right: isRTL ? hPadding + 3 : null,
            bottom: 25.0 * scale,
            child: Row(
              children: isRTL ? statsRow.reversed.toList() : statsRow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStat(String label, String value, bool isTablet, double scale, bool isRTL, double fontScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: isRTL
              ? GoogleFonts.cairo(fontSize: 12.0 * scale * fontScale, fontWeight: FontWeight.w400, color: const Color(0xFF8B88B5))
              : GoogleFonts.roboto(fontSize: 12.0 * scale, fontWeight: FontWeight.w400, color: const Color(0xFF8B88B5)),
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
