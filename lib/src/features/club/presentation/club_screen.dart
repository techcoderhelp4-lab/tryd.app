import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/gradient_button.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../challenges/presentation/challenge_detail_screen.dart';
import '../../challenges/presentation/my_challenge_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import '../../activity/presentation/running_screen.dart';
import '../../activity/presentation/workout_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../challenges/data/challenge_repository.dart';
import '../../challenges/domain/challenge.dart';
import 'package:intl/intl.dart';
import '../../../../widgets/skeleton_loading.dart';
import 'package:tryd/src/generated/l10n/app_localizations.dart';

class ClubScreen extends ConsumerStatefulWidget {
  const ClubScreen({super.key});

  @override
  ConsumerState<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends ConsumerState<ClubScreen> {
  String _selectedTab = 'My Challenges';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isTablet = screenWidth > 600;

    // ── Responsive Scale ──────────────────────────────────
    // Change these 4 values to control ALL component sizes:
    //   small  → phones with height < 680px
    //   medium → phones with height 680–850px
    //   large  → phones with height > 850px
    //   tablet → devices with width > 600px
    const double smallScale  = 0.82;
    const double mediumScale = 0.95;
    const double largeScale  = 1.05;
    const double tabletScale = 1.20;

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

    final horizontalPadding = 16.0 * scale;
    final heroHeight = 330.0 * scale;
    final titleFontSize = 22.0 * scale * fontScale;
    final subtitleFontSize = 13.0 * scale * fontScale;
    final sectionTitleSize = 18.0 * scale * fontScale;
    final bottomNavSpacing = 140.0 * scale;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: 4,
        onTap: (index) {
          if (index == 4) return;
          
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
      body: Container(
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
          child: Stack(
            children: [
              RefreshIndicator(
                color: const Color(0xFF900EBF),
                onRefresh: () async {
                  await ref.read(challengeRepositoryProvider).fetchAndSyncChallenges(force: true);
                  ref.invalidate(challengesListProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  child: Column(
                    children: [
                    SizedBox(height: 15.0 * scale),
                    // Hero Image
                    Container(
                      width: double.infinity,
                      height: heroHeight,
                      margin: const EdgeInsets.symmetric(horizontal: 0),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/challenges.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[300],
                                child: const Center(child: Icon(Icons.image, size: 50)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30.0 * scale),
                    // Title
                    Text(
                      l10n.challengesTitle,
                      style: isRTL
                          ? GoogleFonts.cairo(fontSize: titleFontSize, fontWeight: FontWeight.w700, color: const Color(0xFF1B2D51))
                          : GoogleFonts.lexendDeca(fontSize: titleFontSize, fontWeight: FontWeight.w600, color: const Color(0xFF1B2D51)),
                    ),
                    SizedBox(height: 18.0 * scale),
                    // Subtitle
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: (isTablet ? 30.0 : 30.0) * scale),
                      child: Text(
                        l10n.challengesSubtitle,
                        textAlign: TextAlign.center,
                        style: isRTL
                            ? GoogleFonts.cairo(fontSize: subtitleFontSize, fontWeight: FontWeight.w400, color: const Color(0xFF1B2D51), height: 1.5)
                            : GoogleFonts.poppins(fontSize: subtitleFontSize, fontWeight: FontWeight.w400, color: const Color(0xFF1B2D51), height: 1.5),
                      ),
                    ),
                    SizedBox(height: 22.0 * scale),
                    // Tab Buttons
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: _buildTabButtons(isTablet, scale, l10n, isRTL, fontScale),
                    ),
                    SizedBox(height: 23.0 * scale),
                    // Content based on selected tab
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: ref.watch(challengesListProvider).when(
                        data: (challenges) {
                          final now = DateTime.now();
                          final myChallenges = challenges.where((c) => c.isJoined).toList();
                          final activeChallenges = myChallenges.where((c) => c.endDate.isAfter(now)).toList();
                          final expiredChallenges = myChallenges.where((c) => !c.endDate.isAfter(now)).toList();
                          final availableChallenges = challenges.where((c) => !c.isJoined && c.endDate.isAfter(now)).toList();

                          if (_selectedTab == 'My Challenges') {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.myChallengesTab,
                                  style: isRTL
                                      ? GoogleFonts.cairo(fontSize: sectionTitleSize, fontWeight: FontWeight.w700, color: const Color(0xFF1B2D51))
                                      : GoogleFonts.lexendDeca(fontSize: sectionTitleSize, fontWeight: FontWeight.w600, color: const Color(0xFF1B2D51)),
                                ),
                                SizedBox(height: 10.0 * scale),
                                if (activeChallenges.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: Text(
                                        l10n.noActiveChallenges,
                                        style: isRTL ? GoogleFonts.cairo(color: Colors.grey) : GoogleFonts.poppins(color: Colors.grey),
                                      ),
                                    ),
                                  )
                                else
                                  ...activeChallenges.map((challenge) => Padding(
                                    padding: EdgeInsets.only(bottom: 12.0 * scale),
                                    child: _buildChallengeCard(
                                      challenge: challenge,
                                      isActive: true,
                                      isTablet: isTablet,
                                      scale: scale,
                                      l10n: l10n,
                                      isRTL: isRTL,
                                      fontScale: fontScale,
                                    ),
                                  )),

                                if (expiredChallenges.isNotEmpty) ...[
                                  SizedBox(height: 20.0 * scale),
                                  Text(
                                    l10n.previousChallenges,
                                    style: isRTL
                                        ? GoogleFonts.cairo(fontSize: sectionTitleSize, fontWeight: FontWeight.w700, color: const Color(0xFF1B2D51))
                                        : GoogleFonts.lexendDeca(fontSize: sectionTitleSize, fontWeight: FontWeight.w600, color: const Color(0xFF1B2D51)),
                                  ),
                                  SizedBox(height: 10.0 * scale),
                                  ...expiredChallenges.map((challenge) => Padding(
                                    padding: EdgeInsets.only(bottom: 12.0 * scale),
                                    child: _buildChallengeCard(
                                      challenge: challenge,
                                      isActive: false,
                                      isTablet: isTablet,
                                      scale: scale,
                                      l10n: l10n,
                                      isRTL: isRTL,
                                      fontScale: fontScale,
                                    ),
                                  )),
                                ],
                              ],
                            );
                          } else {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (availableChallenges.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: Text(
                                        l10n.noAvailableChallenges,
                                        style: isRTL ? GoogleFonts.cairo(color: Colors.grey) : GoogleFonts.poppins(color: Colors.grey),
                                      ),
                                    ),
                                  )
                                else
                                  ...availableChallenges.map((challenge) => Padding(
                                    padding: EdgeInsets.only(bottom: 12.0 * scale),
                                    child: _buildJoinChallengeCard(challenge, isTablet, scale, l10n, isRTL, fontScale),
                                  )),
                              ],
                            );
                          }
                        },
                        loading: () => ClubSkeletonLoading(scale: scale, isTablet: isTablet),
                        error: (err, stack) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red),
                                const SizedBox(height: 8),
                                Text('Failed to load challenges: $err'),
                                TextButton(
                                  onPressed: () => ref.invalidate(challengesListProvider),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: bottomNavSpacing),
                  ],
                ),
              ),
              ),

            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTabButtons(bool isTablet, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final containerHeight = (isTablet ? 50.0 : 50.0) * scale;
    final buttonHeight = (isTablet ? 36.0 : 36.0) * scale;
    final fontSize = (isTablet ? 12.0 : 13.0) * scale * fontScale;
    final borderRadius = (isTablet ? 12.0 : 12.0) * scale;

    return Container(
      width: double.infinity,
      height: containerHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF5F3F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 4),
            blurRadius: 32,
          ),
        ],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 17.0 * scale, vertical: 8.5 * scale),
        child: Row(
          children: [
            Expanded(
              child: _selectedTab == 'My Challenges'
                  ? GradientButton(
                      text: l10n.myChallengesTab,
                      onPressed: () {},
                      height: buttonHeight,
                      showIcon: false,
                      textStyle: isRTL
                          ? GoogleFonts.cairo(fontSize: fontSize, fontWeight: FontWeight.w600, color: Colors.white)
                          : GoogleFonts.poppins(fontSize: fontSize, fontWeight: FontWeight.w400, color: Colors.white),
                    )
                  : GestureDetector(
                      onTap: () => setState(() => _selectedTab = 'My Challenges'),
                      child: Container(
                        height: buttonHeight,
                        alignment: Alignment.center,
                        child: Text(
                          l10n.myChallengesTab,
                          style: isRTL
                              ? GoogleFonts.cairo(fontSize: fontSize, fontWeight: FontWeight.w500, color: Colors.black)
                              : GoogleFonts.poppins(fontSize: fontSize, fontWeight: FontWeight.w400, color: Colors.black),
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: _selectedTab == 'Join a Challenge'
                  ? GradientButton(
                      text: l10n.joinAChallengeTab,
                      onPressed: () {},
                      height: buttonHeight,
                      showIcon: false,
                      textStyle: isRTL
                          ? GoogleFonts.cairo(fontSize: fontSize, fontWeight: FontWeight.w600, color: Colors.white)
                          : GoogleFonts.poppins(fontSize: fontSize, fontWeight: FontWeight.w400, color: Colors.white),
                    )
                  : GestureDetector(
                      onTap: () => setState(() => _selectedTab = 'Join a Challenge'),
                      child: Container(
                        height: buttonHeight,
                        alignment: Alignment.center,
                        child: Text(
                          l10n.joinAChallengeTab,
                          style: isRTL
                              ? GoogleFonts.cairo(fontSize: fontSize, fontWeight: FontWeight.w500, color: Colors.black)
                              : GoogleFonts.poppins(fontSize: fontSize, fontWeight: FontWeight.w400, color: Colors.black),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _challengeDateLabel(Challenge challenge, bool isActive, AppLocalizations l10n, bool isRTL) {
    final now = DateTime.now();
    final daysLeft = challenge.endDate.difference(now).inDays;
    final km = challenge.targetKm.toStringAsFixed(0);
    final locale = isRTL ? 'ar' : 'en';

    if (!isActive) {
      return isRTL
          ? 'انتهى ${DateFormat('dd MMM yyyy', locale).format(challenge.endDate)}'
          : 'Ended ${DateFormat('dd MMM yyyy').format(challenge.endDate)}';
    } else if (now.isBefore(challenge.startDate)) {
      final daysToStart = challenge.startDate.difference(now).inDays;
      return isRTL
          ? 'يبدأ خلال $daysToStart أيام  •  $km ${l10n.kmLabel}'
          : 'Starts in $daysToStart days  •  $km ${l10n.kmLabel}';
    } else {
      return isRTL
          ? '$daysLeft أيام متبقية  •  $km ${l10n.kmLabel}'
          : '$daysLeft days left  •  $km ${l10n.kmLabel}';
    }
  }

  Widget _buildChallengeCard({
    required Challenge challenge,
    required bool isActive,
    required bool isTablet,
    required double scale,
    required AppLocalizations l10n,
    required bool isRTL,
    required double fontScale,
  }) {
    final cardHeight = (isTablet ? 98.0 : 104.0) * scale;
    final borderRadius = (isTablet ? 12.0 : 12.0) * scale;
    final titleFontSize = (isTablet ? 12.0 : 13.0) * scale * fontScale;
    final descFontSize = (isTablet ? 10.0 : 10.5) * scale * fontScale;
    final progressFontSize = (isTablet ? 11.0 : 12.0) * scale * fontScale;
    final badgeHeight = (isTablet ? 40.0 : 45.0) * scale;
    final badgeWidth = 42.0 * scale;
    final badgeNumSize = 17.0 * scale;
    final badgeLabelSize = 10.0 * scale;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyChallengeScreen(challenge: challenge),
          ),
        );
        ref.invalidate(challengesListProvider);
      },
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: cardHeight),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF5F3F3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 4),
              blurRadius: 32,
            ),
          ],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0 * scale, vertical: 12.0 * scale),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      challenge.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lexendDeca(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF24252C),
                      ),
                    ),
                    SizedBox(height: 4.0 * scale),
                    Text(
                      challenge.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lexendDeca(
                        fontSize: descFontSize,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6E6A7C),
                      ),
                    ),
                    SizedBox(height: 10.0 * scale),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: const Color(0xFFAB94FF),
                          size: 16.0 * scale,
                        ),
                        SizedBox(width: 6.0 * scale),
                        Expanded(
                          child: Text(
                            _challengeDateLabel(challenge, isActive, l10n, isRTL),
                            style: isRTL
                                ? GoogleFonts.cairo(fontSize: progressFontSize, fontWeight: FontWeight.w400, color: isActive ? const Color(0xFF24252C) : const Color(0xFF8B88B5))
                                : GoogleFonts.lexendDeca(fontSize: progressFontSize, fontWeight: FontWeight.w400, color: isActive ? const Color(0xFF24252C) : const Color(0xFF8B88B5)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.0 * scale),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: badgeWidth,
                    height: badgeHeight,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFFFE4F2) : const Color(0xFF96AAD2),
                      borderRadius: BorderRadius.circular(7.0 * scale),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          challenge.targetKm.toStringAsFixed(0),
                          style: GoogleFonts.lexendDeca(
                            fontSize: badgeNumSize,
                            fontWeight: FontWeight.w600,
                            color: isActive ? const Color(0xFFF83A71) : Colors.white,
                          ),
                        ),
                        Text(
                          l10n.kmLabel,
                          style: GoogleFonts.roboto(
                            fontSize: badgeLabelSize,
                            fontWeight: FontWeight.w500,
                            color: isActive ? const Color(0xFFF83A71) : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive) ...[
                     SizedBox(height: 4.0 * scale),
                     Icon(
                      Icons.visibility,
                      color: const Color(0xFF9260F4),
                      size: 20.0 * scale,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJoinChallengeCard(Challenge challenge, bool isTablet, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final now = DateTime.now();
    final isUpcoming = challenge.startDate.isAfter(now);
    final timeLeft = challenge.endDate.difference(now).inDays;
    final cardHeight = (isTablet ? 230.0 : 250.0) * scale;
    final imageHeight = (isTablet ? 110.0 : 125.0) * scale;
    final titleFontSize = (isTablet ? 12.0 : 13.5) * scale * fontScale;
    final descFontSize = (isTablet ? 10.0 : 10.5) * scale * fontScale;
    final badgeWidth = (isTablet ? 40.0 : 43.0) * scale;
    final badgeHeight = (isTablet ? 40.0 : 45.0) * scale;
    final badgeNumSize = (isTablet ? 16.0 : 17.0) * scale * fontScale;
    final badgeLabelSize = (isTablet ? 9.0 : 10.0) * scale * fontScale;
    final footerFontSize = (isTablet ? 10.0 : 10.5) * scale * fontScale;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChallengeDetailScreen(challengeId: challenge.id),
          ),
        );
        ref.invalidate(challengesListProvider);
      },
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: cardHeight),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF5F3F3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 4),
              blurRadius: 32,
            ),
          ],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(11.0 * scale),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: challenge.imageUrl != null && challenge.imageUrl!.startsWith('http')
                  ? Image.network(
                      challenge.imageUrl!,
                      height: imageHeight,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/running.png',
                        height: imageHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      challenge.imageUrl ?? 'assets/images/running.png',
                      height: imageHeight,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.0 * scale),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: (isRTL ? GoogleFonts.cairo : GoogleFonts.lexendDeca)(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF24252C),
                          ),
                        ),
                        SizedBox(height: 4.0 * scale),
                        Text(
                          challenge.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: (isRTL ? GoogleFonts.cairo : GoogleFonts.lexendDeca)(
                            fontSize: descFontSize,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6E6A7C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.0 * scale),
                  Container(
                    width: badgeWidth,
                    height: badgeHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4F2),
                      borderRadius: BorderRadius.circular(7.44),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          challenge.targetKm.toStringAsFixed(0),
                          style: GoogleFonts.lexendDeca(
                            fontSize: badgeNumSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF83A71),
                          ),
                        ),
                        Text(
                          l10n.kmLabel,
                          style: (isRTL ? GoogleFonts.cairo : GoogleFonts.roboto)(
                            fontSize: badgeLabelSize,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFF83A71),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.0 * scale),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.0 * scale),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: const Color(0xFFAB94FF),
                    size: isTablet ? 12.0 : 14.0,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isUpcoming
                          ? (isRTL
                              ? 'يبدأ في ${challenge.startDate.difference(now).inDays} أيام  |  ${NumberFormat.compact().format(challenge.rewardPoints)} نقطة ستربحها'
                              : 'Starts in ${challenge.startDate.difference(now).inDays} days  |  ${NumberFormat.compact().format(challenge.rewardPoints)} pts you will win')
                          : (isRTL
                              ? '$timeLeft أيام متبقية  |  ${NumberFormat.compact().format(challenge.rewardPoints)} نقطة ستربحها'
                              : '$timeLeft Days remaining  |  ${NumberFormat.compact().format(challenge.rewardPoints)} pts you will win'),
                      style: (isRTL ? GoogleFonts.cairo : GoogleFonts.lexendDeca)(
                        fontSize: footerFontSize,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8B88B5),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.visibility,
                    color: const Color(0xFF9260F4),
                    size: isTablet ? 16.0 : 20.0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
