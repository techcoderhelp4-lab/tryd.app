import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import 'leaderboard_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/challenge.dart';
import 'package:intl/intl.dart';
import '../../../../widgets/swipe_to_pop_wrapper.dart';
import '../../../shell/main_shell.dart' show mainNavTapProvider;

class MyChallengeScreen extends ConsumerStatefulWidget {
  final Challenge challenge;
  const MyChallengeScreen({super.key, required this.challenge});

  @override
  ConsumerState<MyChallengeScreen> createState() => _MyChallengeScreenState();
}

class _MyChallengeScreenState extends ConsumerState<MyChallengeScreen> {
  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;
    final isTablet = screenWidth > 600;

    // ── Responsive Scale ──────────────────────────────────
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

    final l10n = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isRTL ? 1.2 : 1.0;

    return SwipeToPopWrapper(child: Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background with bg-gradient.png
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg-gradient.png'),
                fit: BoxFit.cover,
                opacity: 0.8,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // App bar
                    _buildAppBar(context, scale, l10n, isRTL, fontScale),
                    SizedBox(height: 30.0 * scale),
                    // Content
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.0 * scale),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Active challenge card
                          _buildActiveChallengeCard(context, challenge, scale, isTablet, l10n, isRTL, fontScale),
                          SizedBox(height: 15.0 * scale),
                          // Details card
                          _buildDetailsCard(context, challenge, scale, l10n, isRTL, fontScale),
                          SizedBox(height: 15.0 * scale),
                          // Leaderboard button
                          _buildLeaderboardButton(context, challenge, scale, l10n, isRTL, fontScale),
                          SizedBox(height: 15.0 * scale),
                          // Unlock Rewards heading
                          Text(
                            l10n.unlockRewards,
                            style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                              fontSize: 18.0 * scale * fontScale,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF221F48),
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 15.0 * scale),
                          // Reward card
                          _buildRewardCard(context, challenge, scale, l10n, isRTL, fontScale),
                          SizedBox(height: 120.0 * scale),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigation(
              currentIndex: 4,
              onTap: (index) {
                if (index == 4) {
                  Navigator.pop(context);
                  return;
                }
                Navigator.of(context).popUntil((route) => route.isFirst);
                ref.read(mainNavTapProvider)?.call(index);
              },
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildAppBar(BuildContext context, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 26.0 * scale, vertical: 28.0 * scale),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: SvgPicture.asset(
              'assets/images/back_arrow_icon.svg',
              width: 42.0 * scale,
              height: 42.0 * scale,
              matchTextDirection: true,
            ),
          ),
          Expanded(
            child: Text(
              l10n.myChallengeTitle,
              textAlign: TextAlign.center,
              style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                fontSize: 19.0 * scale * fontScale,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF24252C),
                height: 1.2,
              ),
            ),
          ),
          SizedBox(width: 24.0 * scale),
        ],
      ),
    );
  }

  Widget _buildActiveChallengeCard(BuildContext context, Challenge challenge, double scale, bool isTablet, AppLocalizations l10n, bool isRTL, double fontScale) {
    final now = DateTime.now();
    final hasEnded = challenge.endDate.isBefore(now);
    final isUpcoming = challenge.startDate.isAfter(now);
    final timeLeft = challenge.endDate.difference(now).inDays;

    // Dynamic badge text and color
    String badgeText;
    Color badgeColor;
    String timeText;

    if (hasEnded) {
      badgeText = isRTL ? 'التحدي انتهى' : 'Challenge Ended';
      badgeColor = const Color(0xFFFF5252).withValues(alpha: 0.67);
      timeText = isRTL
          ? 'انتهى ${DateFormat('dd MMM yyyy', 'ar').format(challenge.endDate)}'
          : 'Ended ${DateFormat('dd MMM yyyy').format(challenge.endDate)}';
    } else if (isUpcoming) {
      final daysToStart = challenge.startDate.difference(now).inDays;
      badgeText = isRTL ? 'تحدٍّ قادم' : 'Upcoming Challenge';
      badgeColor = const Color(0xFFFFAA00).withValues(alpha: 0.67);
      timeText = isRTL ? 'يبدأ في $daysToStart أيام' : 'Starts in $daysToStart days';
    } else {
      badgeText = isRTL ? 'تحدٍّ نشط' : 'Active Challenge';
      badgeColor = const Color(0xFF4FFD5B).withValues(alpha: 0.67);
      timeText = isRTL ? '$timeLeft أيام متبقية' : '$timeLeft Days Remaining';
    }

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 146.0 * scale),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isRTL ? Alignment.centerRight : Alignment.centerLeft,
          end: isRTL ? Alignment.centerLeft : Alignment.centerRight,
          colors: const [Color(0xFF910EBF), Color(0xFFFD3B6E)],
        ),
        borderRadius: BorderRadius.circular(24.0 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20.0 * scale,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.0 * scale, 22.0 * scale, 29.0 * scale, 22.0 * scale),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.0 * scale, vertical: 4.0 * scale),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(185.0 * scale),
                    ),
                    child: Text(
                      badgeText,
                      style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                        fontSize: 10.0 * scale * fontScale,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0 * scale),
                  // Title
                  Text(
                    challenge.title,
                    style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                      fontSize: 18.0 * scale * fontScale,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 16.0 * scale),
                  // Time info
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_filled,
                        color: Colors.white,
                        size: 18.0 * scale,
                      ),
                      SizedBox(width: 8.0 * scale),
                      Flexible(
                        child: Text(
                          timeText,
                          style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                            fontSize: 14.0 * scale * fontScale,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.0 * scale),
            // Circular progress indicator
            _buildCircularProgress(context, challenge.userProgress, challenge.targetKm, scale),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularProgress(BuildContext context, double current, double total, double scale) {
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    // Format current value - use compact format for large values
    String currentText;
    if (current >= 1000) {
      currentText = '${(current / 1000).toStringAsFixed(1)}K';
    } else if (current >= 100) {
      currentText = current.toStringAsFixed(0);
    } else {
      currentText = current.toStringAsFixed(1);
    }

    // Format total value
    String totalText;
    if (total >= 1000) {
      totalText = '${(total / 1000).toStringAsFixed(0)}K KM';
    } else {
      totalText = '${total.toInt()}KM';
    }

    return Center(
      child: SizedBox(
        width: 82.0 * scale,
        height: 82.0 * scale,
        child: Stack(
          children: [
            // Pink track (full circle)
            SizedBox(
              width: 82.0 * scale,
              height: 82.0 * scale,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 10.0 * scale,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF60A3)),
              ),
            ),
            // Progress arc on top
            Transform.rotate(
              angle: -1.5708, // start from 12 o'clock
              child: SizedBox(
                width: 82.0 * scale,
                height: 82.0 * scale,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10.0 * scale,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE8DEFF)),
                ),
              ),
            ),
            // Center text
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentText,
                    style: GoogleFonts.tajawal(
                      fontSize: 12.0 * scale,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 2.0 * scale),
                  Text(
                    totalText,
                    style: GoogleFonts.tajawal(
                      fontSize: 11.0 * scale,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
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

  Widget _buildDetailsCard(BuildContext context, Challenge challenge, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final dateFormat = DateFormat('d MMM', isRTL ? 'ar' : 'en');
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.0 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF5F3F3).withValues(alpha: 0.62)),
        borderRadius: BorderRadius.circular(15.0 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: Offset(0, 4.0 * scale),
            blurRadius: 32.0 * scale,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow(context, l10n.totalDistance, '${challenge.targetKm.toStringAsFixed(0)} ${l10n.kmLabel}', scale, isRTL, fontScale),
          SizedBox(height: 7.0 * scale),
          _buildDetailRow(context, isRTL ? 'المدة' : 'Duration', '${dateFormat.format(challenge.startDate)} - ${dateFormat.format(challenge.endDate)}', scale, isRTL, fontScale),
          SizedBox(height: 7.0 * scale),
          _buildDetailRow(context, l10n.participantsLabel, '${NumberFormat.decimalPattern().format(challenge.participantCount)} ${isRTL ? "عداء" : "Runners"}', scale, isRTL, fontScale),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, double scale, bool isRTL, double fontScale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
            fontSize: 14.0 * scale * fontScale,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B2D51),
            height: 1.3,
          ),
        ),
        Text(
          value,
          style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
            fontSize: 14.0 * scale * fontScale,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8B88B5).withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardButton(BuildContext context, Challenge challenge, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeaderboardScreen(challengeId: challenge.id),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 58.0 * scale,
        decoration: BoxDecoration(
          color: const Color(0xFF900EBF),
          borderRadius: BorderRadius.circular(14.0 * scale),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.leaderboardTitle,
              style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                fontSize: 19.0 * scale * fontScale,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            SizedBox(width: 12.0 * scale),
            Transform.rotate(
              angle: 3.14159,
              child: SvgPicture.asset(
                'assets/images/back_arrow_icon.svg',
                width: 24.0 * scale,
                height: 24.0 * scale,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, Challenge challenge, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 73.0 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF5F3F3).withValues(alpha: 0.62)),
        borderRadius: BorderRadius.circular(15.0 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: Offset(0, 4.0 * scale),
            blurRadius: 32.0 * scale,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 23.0 * scale, vertical: 15.0 * scale),
        child: Row(
          children: [
            if (!isRTL) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Run ${challenge.targetKm.toStringAsFixed(0)} km',
                      style: GoogleFonts.tajawal(
                        fontSize: 11.0 * scale * fontScale,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6E6A7C),
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 4.0 * scale),
                    Text(
                      'win ${NumberFormat.compact().format(challenge.rewardPoints)} points',
                      style: GoogleFonts.tajawal(
                        fontSize: 14.0 * scale * fontScale,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 41.0 * scale,
                height: 41.0 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4F2),
                  borderRadius: BorderRadius.circular(8.0 * scale),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/cup.svg',
                    width: 26.0 * scale,
                    height: 26.0 * scale,
                    colorFilter: const ColorFilter.mode(Color(0xFFF83A71), BlendMode.srcIn),
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.emoji_events, color: const Color(0xFFF83A71), size: 20.0 * scale),
                  ),
                ),
              ),
            ],
            if (isRTL) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'اركض ${challenge.targetKm.toStringAsFixed(0)} كم',
                      style: GoogleFonts.tajawal(
                        fontSize: 11.0 * scale * fontScale,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6E6A7C),
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 4.0 * scale),
                    Text(
                      'اربح ${NumberFormat.compact().format(challenge.rewardPoints)} نقطة',
                      style: GoogleFonts.tajawal(
                        fontSize: 14.0 * scale * fontScale,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.0 * scale),
              Container(
                width: 41.0 * scale,
                height: 41.0 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4F2),
                  borderRadius: BorderRadius.circular(8.0 * scale),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/cup.svg',
                    width: 26.0 * scale,
                    height: 26.0 * scale,
                    colorFilter: const ColorFilter.mode(Color(0xFFF83A71), BlendMode.srcIn),
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.emoji_events, color: const Color(0xFFF83A71), size: 20.0 * scale),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

