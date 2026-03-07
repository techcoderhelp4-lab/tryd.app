import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../../../widgets/skeleton_loading.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../home/presentation/home_screen.dart';
import '../../activity/presentation/running_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import '../../activity/presentation/workout_screen.dart';
import '../../club/presentation/club_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/challenge_repository.dart';
import '../domain/leaderboard_data.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  final String challengeId;
  const LeaderboardScreen({super.key, required this.challengeId});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  final ScrollController _scrollController = ScrollController();
  static const double _rowHeight = 65.0; // Approximate height of each row

  bool _isUserVisible = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final leaderboardAsync = ref.read(challengeLeaderboardProvider(widget.challengeId));
    leaderboardAsync.whenData((data) {
      if (!mounted) return;
      
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final isTablet = screenWidth > 600;
      
      const double smallScale  = 0.85;
      const double mediumScale = 0.98;
      const double largeScale  = 1.05;
      const double tabletScale = 1.25;

      final double scale = isTablet
          ? tabletScale
          : screenHeight < 680
              ? smallScale
              : screenHeight < 850
                  ? mediumScale
                  : largeScale;

      // 146 (card) + 15 (gap) + 40 (table header header height)
      final initialOffset = (250.0 + 160.0) * scale;
      final userTop = initialOffset + ((data.currentUserRank - 1) * _rowHeight * scale);
      
      final viewportTop = _scrollController.offset;
      final viewportBottom = viewportTop + _scrollController.position.viewportDimension;

      // We consider user visible if their row is within the viewport
      final isVisible = (userTop < viewportBottom - 20) && (userTop > viewportTop + 20);

      if (_isUserVisible != isVisible) {
        setState(() {
          _isUserVisible = isVisible;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToUser(int rank, int totalItems, double scale) {
    if (rank <= 1) return;
    
    final headerOffset = (250.0 + 160.0) * scale;
    final targetOffset = headerOffset + ((rank - 1) * _rowHeight * scale) - (100 * scale);
    
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
  @override
  Widget build(BuildContext context) {
    final challengeId = widget.challengeId;
    final leaderboardAsync = ref.watch(challengeLeaderboardProvider(challengeId));

    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;
    final isTablet = screenWidth > 600;

    // ── Responsive Scale ──────────────────────────────────
    const double smallScale  = 0.85;
    const double mediumScale = 0.98;
    const double largeScale  = 1.05;
    const double tabletScale = 1.25;

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

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Image
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
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(context, scale, l10n, isRTL, fontScale),
                Expanded(
                  child: leaderboardAsync.when(
                    data: (data) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.0 * scale),
                      child: RefreshIndicator(
                        color: const Color(0xFF900EBF),
                        onRefresh: () async {
                          await ref.read(challengeRepositoryProvider).fetchAndCacheLeaderboard(challengeId, force: true);
                          ref.invalidate(challengeLeaderboardProvider(challengeId));
                        },
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  _buildActiveChallengeCard(context, data.challenge, scale, l10n, isRTL, fontScale),
                                  SizedBox(height: 15.0 * scale),
                                ],
                              ),
                            ),
                            _buildTableHeader(scale, l10n, isRTL, fontScale),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final participant = data.leaderboard[index];
                                  return _buildParticipantTableRow(context, participant, scale);
                                },
                                childCount: data.leaderboard.length,
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: SizedBox(height: 260.0 * scale),
                            ),
                          ],
                        ),
                      ),
                    ),
                    loading: () => LeaderboardSkeletonLoading(scale: scale, isTablet: isTablet),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(height: 8),
                            Text('Failed to load leaderboard: $err'),
                            TextButton(
                              onPressed: () => ref.invalidate(challengeLeaderboardProvider(challengeId)),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          leaderboardAsync.when(
            data: (data) => (data.currentUserRank > 5 && !_isUserVisible) ? Positioned(
              left: 15.0 * scale,
              right: 15.0 * scale,
              bottom: (137.0 * scale) + MediaQuery.of(context).padding.bottom + 10.0, 
              child: GestureDetector(
                onTap: () => _scrollToUser(data.currentUserRank, data.leaderboard.length, scale),
                child: _buildStickyUserRank(context, data, scale, l10n, isRTL),
              ),
            ) : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Bottom Navigation
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

                Widget? page;
                switch (index) {
                  case 0: page = const HomeScreen(); break;
                  case 1: page = const RunningScreen(); break;
                  case 2: page = const RewardsScreen(); break;
                  case 3: page = const WorkoutScreen(); break;
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

  Widget _buildStickyUserRank(BuildContext context, LeaderboardData data, double scale, AppLocalizations l10n, bool isRTL) {
    final me = data.leaderboard.firstWhere(
      (entry) => entry.isCurrentUser,
      orElse: () => LeaderboardEntry(
        rank: data.currentUserRank,
        user: LeaderboardUserInfo(id: '', name: isRTL ? 'أنت' : 'You'),
        completedKm: data.challenge.userProgress ?? 0,
        isCurrentUser: true,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0 * scale),
        border: Border.all(color: const Color(0xFF2CFC44), width: 2.0 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildParticipantRow(
        context: context,
        rank: '${me.rank}.',
        name: me.user.name.isEmpty ? (isRTL ? 'أنت' : 'You') : me.user.name,
        rankLabel: l10n.yourPositionLabel,
        km: '${me.completedKm.toStringAsFixed(2)} ${l10n.kmLabel}',
        isYou: true,
        profilePicture: me.user.profilePicture,
        scale: scale,
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    return Padding(
      padding: EdgeInsets.fromLTRB(26.0 * scale, 28.0 * scale, 26.0 * scale, 20.0 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Transform.scale(
              scaleX: isRTL ? -1.0 : 1.0,
              child: SvgPicture.asset(
                'assets/images/back_arrow_icon.svg',
                width: 24.0 * scale,
                height: 24.0 * scale,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF24252C),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              l10n.leaderboardTitle,
              textAlign: TextAlign.center,
              style: (isRTL ? GoogleFonts.cairo : GoogleFonts.lexendDeca)(
                fontSize: 19.0 * scale * fontScale,
                fontWeight: FontWeight.w600,
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

  Widget _buildActiveChallengeCard(BuildContext context, LeaderboardChallengeInfo challenge, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final now = DateTime.now();
    final hasEnded = challenge.endDate != null && challenge.endDate!.isBefore(now);
    final isUpcoming = challenge.startDate != null && challenge.startDate!.isAfter(now);

    // Dynamic badge and time text
    String badgeText;
    Color badgeColor;
    String timeText;

    if (hasEnded) {
      badgeText = isRTL ? 'التحدي انتهى' : 'Challenge Ended';
      badgeColor = const Color(0xFFFF5252).withValues(alpha: 0.67);
      timeText = challenge.endDate != null
          ? (isRTL
              ? 'انتهى ${challenge.endDate!.day} ${_monthName(challenge.endDate!.month, isRTL)} ${challenge.endDate!.year}'
              : 'Ended ${challenge.endDate!.day} ${_monthName(challenge.endDate!.month, isRTL)} ${challenge.endDate!.year}')
          : '';
    } else if (isUpcoming) {
      final daysToStart = challenge.startDate!.difference(now).inDays;
      badgeText = isRTL ? 'تحدٍّ قادم' : 'Upcoming Challenge';
      badgeColor = const Color(0xFFFFAA00).withValues(alpha: 0.67);
      timeText = isRTL ? 'يبدأ في $daysToStart أيام' : 'Starts in $daysToStart days';
    } else {
      badgeText = isRTL ? 'تحدٍّ نشط' : 'Active Challenge';
      badgeColor = const Color(0xFF4FFD5B).withValues(alpha: 0.67);
      final daysLeft = challenge.endDate != null ? challenge.endDate!.difference(now).inDays.clamp(0, 999) : 0;
      timeText = isRTL ? '$daysLeft أيام متبقية' : '$daysLeft Days Remaining';
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
        padding: EdgeInsets.fromLTRB(20.0 * scale, 22.0 * scale, 20.0 * scale, 22.0 * scale),
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
                      style: (isRTL ? GoogleFonts.cairo : GoogleFonts.poppins)(
                        fontSize: 10.0 * scale * fontScale,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0 * scale),
                  // Title
                  Text(
                    challenge.title,
                    style: (isRTL ? GoogleFonts.cairo : GoogleFonts.poppins)(
                      fontSize: 18.0 * scale * fontScale,
                      fontWeight: FontWeight.w600,
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
                          style: (isRTL ? GoogleFonts.cairo : GoogleFonts.poppins)(
                            fontSize: 14.0 * scale * fontScale,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.0 * scale),
            // Circular progress indicator
            _buildCircularProgress(context, challenge.userProgress ?? 0.0, challenge.targetKm, scale),
          ],
        ),
      ),
    );
  }

  String _monthName(int month, bool isRTL) {
    const enMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const arMonths = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return isRTL ? arMonths[month - 1] : enMonths[month - 1];
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
              angle: -1.5708,
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
                    style: GoogleFonts.lexendDeca(
                      fontSize: 11.0 * scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 2.0 * scale),
                  Text(
                    totalText,
                    style: GoogleFonts.lexendDeca(
                      fontSize: 10.0 * scale,
                      fontWeight: FontWeight.w700,
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

  Widget _buildLeaderboardHeaderSection(BuildContext context, LeaderboardData data, double scale) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFF5F3F3).withValues(alpha: 0.74),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 32.0 * scale,
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15.0 * scale),
          topRight: Radius.circular(15.0 * scale),
        ),
      ),
      padding: EdgeInsets.fromLTRB(18.0 * scale, 23.0 * scale, 18.0 * scale, 15.0 * scale),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Rank',
                style: GoogleFonts.poppins(
                  fontSize: 18.0 * scale,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1B2D51),
                  height: 1.0,
                ),
              ),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 15.0 * scale,
                      color: const Color(0xFF1B2D51),
                    ),
                    SizedBox(width: 6.0 * scale),
                    Flexible(
                      child: Text(
                        '${data.leaderboard.length} participants',
                        style: GoogleFonts.poppins(
                          fontSize: 14.0 * scale,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF1B2D51),
                          height: 1.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 15.0 * scale),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: 61.0 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12.0 * scale),
            ),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 20.0 * scale, vertical: 15.0 * scale),
            child: Text(
              '#${data.currentUserRank}',
              style: GoogleFonts.poppins(
                fontSize: 31.0 * scale,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF83A71),
                height: 1,
              ),
            ),
          ),
          SizedBox(height: 17.0 * scale),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Top Performers Rank',
              style: GoogleFonts.poppins(
                fontSize: 18.0 * scale,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1B2D51),
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final textStyle = (isRTL ? GoogleFonts.cairo : GoogleFonts.lexend)(
      fontSize: 10.0 * scale * fontScale,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF8B88B5),
      letterSpacing: isRTL ? 0.0 : 0.5,
    );
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.0 * scale, vertical: 12.0 * scale),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFF5F3F3)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48.0 * scale,
              child: Text(l10n.rankHeaderLabel, style: textStyle),
            ),
            SizedBox(width: 8.0 * scale),
            Expanded(
              child: Text(l10n.userHeaderLabel, style: textStyle),
            ),
            SizedBox(
              width: 90.0 * scale,
              child: Text(
                l10n.distanceHeaderLabel,
                textAlign: isRTL ? TextAlign.left : TextAlign.right,
                style: textStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantTableRow(BuildContext context, LeaderboardEntry participant, double scale) {
    final l10n = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    String kmText;
    if (participant.completedKm >= 1000) {
      kmText = '${(participant.completedKm / 1000).toStringAsFixed(1)}K ${l10n.kmLabel}';
    } else if (participant.completedKm >= 100) {
      kmText = '${participant.completedKm.toStringAsFixed(1)} ${l10n.kmLabel}';
    } else {
      kmText = '${participant.completedKm.toStringAsFixed(2)} ${l10n.kmLabel}';
    }

    return Container(
      color: Colors.white,
      child: _buildParticipantRow(
        context: context,
        rank: '${participant.rank}.',
        name: participant.user.name,
        rankLabel: participant.rank <= 3 ? (isRTL ? 'المركز #${participant.rank}' : 'Rank #${participant.rank}') : '',
        km: kmText,
        isYou: participant.isCurrentUser,
        profilePicture: participant.user.profilePicture,
        scale: scale,
      ),
    );
  }

  Widget _buildParticipantRow({
    required BuildContext context,
    required String rank,
    required String name,
    required String rankLabel,
    required String km,
    required bool isYou,
    required double scale,
    String? profilePicture,
  }) {
    return Container(
      margin: isYou ? EdgeInsets.symmetric(vertical: 4.0 * scale) : EdgeInsets.only(bottom: 9.0 * scale),
      padding: isYou
          ? EdgeInsets.fromLTRB(16.0 * scale, 18.0 * scale, 16.0 * scale, 18.0 * scale)
          : EdgeInsets.symmetric(horizontal: 18.0 * scale, vertical: 12.0 * scale),
      decoration: BoxDecoration(
        color: isYou ? const Color(0xFF2CFC44).withOpacity(0.15) : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isYou ? const Color(0xFF2CFC44) : const Color(0xFFE7EAF0),
            width: isYou ? 3.0 * scale : 1.0 * scale,
          ),
        ),
        borderRadius: isYou ? BorderRadius.circular(15.0 * scale) : null,
      ),
      child: Row(
        children: [
          // Rank number or Medal
          SizedBox(
            width: 48.0 * scale,
            child: _buildRankIconOrNumber(rank, scale, isYou),
          ),
          SizedBox(width: 8.0 * scale),
          // Profile image
          ClipOval(
            child: profilePicture != null && profilePicture.startsWith('http')
              ? Image.network(
                  profilePicture,
                  width: 34.0 * scale,
                  height: 34.0 * scale,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/profile.png',
                    width: 34.0 * scale,
                    height: 34.0 * scale,
                    fit: BoxFit.cover,
                  ),
                )
              : Image.asset(
                  'assets/images/profile.png',
                  width: 34.0 * scale,
                  height: 34.0 * scale,
                  fit: BoxFit.cover,
                ),
          ),
          SizedBox(width: 12.0 * scale),
          // Name and rank label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14.0 * scale,
                    fontWeight: isYou ? FontWeight.w700 : FontWeight.w600,
                    color: const Color(0xFF121212),
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (rankLabel.isNotEmpty && !isYou) // Hide redundant rank label for YOU
                  Padding(
                    padding: EdgeInsets.only(top: 2.0 * scale),
                    child: Text(
                      rankLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 11.0 * scale,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8B88B5).withOpacity(0.7),
                        height: 1.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8.0 * scale),
          // KM value
          SizedBox(
            width: 90.0 * scale,
            child: Text(
              km,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 13.0 * scale,
                fontWeight: isYou ? FontWeight.w800 : FontWeight.w500,
                color: isYou ? const Color(0xFF121212) : const Color(0xFF121212).withOpacity(0.5),
                height: 1.2,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankIconOrNumber(String rankText, double scale, bool isYou) {
    int? rankNum = int.tryParse(rankText.replaceAll('.', '').trim());
    
    if (rankNum == 1) {
      return Center(child: Text('🥇', style: TextStyle(fontSize: 22.0 * scale)));
    } else if (rankNum == 2) {
      return Center(child: Text('🥈', style: TextStyle(fontSize: 22.0 * scale)));
    } else if (rankNum == 3) {
      return Center(child: Text('🥉', style: TextStyle(fontSize: 22.0 * scale)));
    }
    
    return Text(
      rankText,
      style: GoogleFonts.lexend(
        fontSize: isYou ? 16.0 * scale : 14.0 * scale,
        fontWeight: isYou ? FontWeight.w800 : FontWeight.w600,
        color: const Color(0xFF121212).withOpacity(isYou ? 1.0 : 0.5),
        height: 1.2,
      ),
    );
  }
}
