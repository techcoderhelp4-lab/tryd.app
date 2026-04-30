import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../../../widgets/custom_calendar_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/activity_repository.dart';
import '../domain/workout.dart';
import '../../../shell/main_shell.dart' show mainNavTapProvider;
import '../../../../widgets/skeleton_loading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tryd/src/generated/l10n/app_localizations.dart';
import '../../../../widgets/swipe_to_pop_wrapper.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isTablet = screenWidth > 600;
    final l10n = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isRTL ? 1.2 : 1.0;

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

    return SwipeToPopWrapper(child: Scaffold(
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
                _buildHeader(context, isTablet, scale, l10n, isRTL, fontScale),
                SizedBox(height: 30.0 * scale),
                Expanded(
                  child: workoutHistoryAsync.when(
                    data: (history) {
                      final sorted = [...history]..sort((a, b) => b.date.compareTo(a.date));
                      return sorted.isEmpty
                        ? Center(
                            child: Text(
                              l10n.noWorkoutsYet,
                              style: _textStyle(isRTL,
                                size: 14.0 * scale * fontScale,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.symmetric(horizontal: 20.0 * scale),
                            itemCount: sorted.length,
                            separatorBuilder: (_, __) => SizedBox(height: 15.0 * scale),
                            itemBuilder: (context, index) {
                              return _buildHistoryCard(sorted[index], isTablet, scale, l10n, isRTL, fontScale);
                            },
                          );
                    },
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
                if (index == 3) return;
                Navigator.of(context).popUntil((route) => route.isFirst);
                ref.read(mainNavTapProvider)?.call(index);
              },
            ),
          ),
        ],
      ),
    ));
  }

  TextStyle _textStyle(bool isRTL, {required double size, FontWeight weight = FontWeight.w400, Color color = Colors.black, double? height}) {
    return isRTL
        ? GoogleFonts.cairo(fontSize: size, fontWeight: weight, color: color, height: height)
        : GoogleFonts.lexend(fontSize: size, fontWeight: weight, color: color, height: height);
  }

  Widget _buildHeader(BuildContext context, bool isTablet, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final horizontalPadding = 30.0 * scale;
    final iconContainerSize = 45.0 * scale;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: SvgPicture.asset(
              'assets/images/back_arrow_icon.svg',
              width: 32.0 * scale,
              height: 32.0 * scale,
              matchTextDirection: true,
            ),
          ),
          Text(
            l10n.historyTitle,
            style: isRTL
                ? GoogleFonts.cairo(
                    fontSize: 19.0 * scale * fontScale,
                    fontWeight: FontWeight.w700,
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

  String _formatDay(DateTime date, AppLocalizations l10n, bool isRTL) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return l10n.todayLabel;
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return l10n.yesterdayLabel;
    }
    final locale = isRTL ? 'ar' : 'en';
    return DateFormat('dd MMM yyyy', locale).format(date);
  }

  Widget _buildHistoryCard(Workout workout, bool isTablet, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
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
                  _formatDay(workout.date, l10n, isRTL),
                  style: isRTL
                      ? GoogleFonts.cairo(
                          fontSize: 19.0 * scale * fontScale,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF221F48),
                          height: 1.15,
                        )
                      : GoogleFonts.poppins(
                          fontSize: 19.0 * scale,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF221F48),
                          height: 1.15,
                        ),
                ),
              ],
            ),
            SizedBox(height: 18.0 * scale),
            _buildStatsRow(workout, isTablet, scale, l10n, isRTL, fontScale),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(Workout workout, bool isTablet, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final items = isRTL
        ? [
            _buildStatItem(l10n.roundsLabel, '${workout.rounds ?? 0}', isTablet, scale, isRTL, fontScale),
            _buildStatItem(l10n.exLabel, '${workout.exercises ?? 0}', isTablet, scale, isRTL, fontScale),
            _buildStatItem(l10n.restLabel, '${workout.restDuration ?? 0}s', isTablet, scale, isRTL, fontScale),
            _buildStatItem(l10n.workLabel, '${workout.workDuration ?? 0}s', isTablet, scale, isRTL, fontScale),
          ]
        : [
            _buildStatItem(l10n.workLabel, '${workout.workDuration ?? 0}s', isTablet, scale, isRTL, fontScale),
            _buildStatItem(l10n.restLabel, '${workout.restDuration ?? 0}s', isTablet, scale, isRTL, fontScale),
            _buildStatItem(l10n.exLabel, '${workout.exercises ?? 0}', isTablet, scale, isRTL, fontScale),
            _buildStatItem(l10n.roundsLabel, '${workout.rounds ?? 0}', isTablet, scale, isRTL, fontScale),
          ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: items,
    );
  }

  Widget _buildStatItem(String label, String value, bool isTablet, double scale, bool isRTL, double fontScale) {
    return Column(
      children: [
        Text(
          label,
          style: _textStyle(isRTL,
            size: 14.0 * scale * fontScale,
            weight: FontWeight.w400,
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
