import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import '../../../../widgets/custom_calendar_icon.dart';
import '../../../../widgets/button_shape_clipper.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  int _selectedIndex = 3; // Workout tab
  String _selectedFilter = 'W';
  // Weekly activity data (miles per day: S, M, T, W, T, F, S)
  final List<double> _weeklyData = [0, 2.5, 0, 0, 0, 0, 0];

  @override
  Widget build(BuildContext context) {
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
                          _buildWeekCard(),
                          SizedBox(height: 22.h),
                          // Weekly chart
                          _buildWeeklyChart(),
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
                          // Today card
                          _buildActivityCard(
                            day: 'Today',
                            kilometers: '05:00',
                            avgPace: '0:00',
                            time: '20:45',
                          ),
                          SizedBox(height: 22.h),
                          // November 2025 heading
                          Text(
                            'November 2025',
                            style: GoogleFonts.lexendDeca(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF221F48),
                            ),
                          ),
                          SizedBox(height: 22.h),
                          // Sunday card
                          _buildActivityCard(
                            day: 'Sunday',
                            kilometers: '05:00',
                            avgPace: '0:00',
                            time: '20:45',
                          ),
                          SizedBox(height: 22.h),
                          // Monday card
                          _buildActivityCard(
                            day: 'Monday',
                            kilometers: '05:00',
                            avgPace: '0:00',
                            time: '20:45',
                          ),
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

  Widget _buildWeekCard() {
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
              '10:05',
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
          // Stats row
          Positioned(
            left: 21.w,
            top: 126.h,
            child: Row(
              children: [
                _buildStatColumn('Run', '1'),
                SizedBox(width: 56.w),
                _buildStatColumn('Avg pace', '0:00'),
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

  Widget _buildWeeklyChart() {
    const maxMiles = 3.0;
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

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
                            final miles = _weeklyData[index];
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
                _buildActivityStat('Kilometers', kilometers),
                SizedBox(width: 56.w),
                _buildActivityStat('Avg pace', avgPace),
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
