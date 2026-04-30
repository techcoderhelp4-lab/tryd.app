import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../../widgets/gradient_button.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../data/challenge_repository.dart';
import '../domain/challenge.dart';
import '../../notifications/data/real_time_notification_service.dart';
import 'my_challenge_screen.dart';
import '../../../../widgets/swipe_to_pop_wrapper.dart';
import '../../../shell/main_shell.dart' show mainNavTapProvider;

class ChallengeDetailScreen extends ConsumerWidget {
  final String challengeId;

  const ChallengeDetailScreen({super.key, required this.challengeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeDetailsProvider(challengeId));

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

    final l10n = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isRTL ? 1.2 : 1.0;

    return SwipeToPopWrapper(child: Scaffold(
      body: Stack(
        children: [
          // Background
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

          // Main Content
          SafeArea(
            bottom: false,
            child: challengeAsync.when(
              data: (challenge) => Stack(
                children: [
                   Column(
                    children: [
                      // App bar
                      _buildAppBar(context, scale, l10n, isRTL, fontScale),

                      // Scrollable Content
                      Expanded(
                        child: RefreshIndicator(
                          color: const Color(0xFF900EBF),
                          onRefresh: () async {
                            ref.invalidate(challengeDetailsProvider(challengeId));
                            await ref.read(challengeDetailsProvider(challengeId).future);
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: EdgeInsets.symmetric(horizontal: 14.0 * scale),
                            child: Column(
                              children: [
                                _buildChallengeHeroCard(context, challenge, scale, l10n, isRTL, fontScale),
                                SizedBox(height: 22.0 * scale),
                                _buildWinPointsCard(context, challenge, scale, l10n, isRTL, fontScale),
                                SizedBox(height: 22.0 * scale),
                                _buildDetailsCard(context, challenge, scale, l10n, isRTL, fontScale),
                                SizedBox(height: 20.0 * scale),
                                _buildJoinButton(context, ref, challenge, scale, l10n, isRTL, fontScale),
                                SizedBox(height: 120.0 * scale), // Spacing for bottom nav
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        ref.read(mainNavTapProvider)?.call(index);
                      },
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.error_outline, color: Colors.red, size: 48.0 * scale),
                    SizedBox(height: 16.0 * scale),
                    Text(l10n.errorLoadingChallenge, style: (isRTL ? GoogleFonts.cairo : GoogleFonts.lexendDeca)(fontSize: 14 * scale * fontScale)),
                    TextButton(
                      onPressed: () => ref.refresh(challengeDetailsProvider(challengeId)),
                      child: Text(l10n.retryButton, style: TextStyle(fontSize: 14 * scale * fontScale)),
                    ),
                  ],
                ),
              ),
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
              l10n.challengeDetailTitle,
              textAlign: TextAlign.center,
              style: (isRTL ? GoogleFonts.cairo : GoogleFonts.lexendDeca)(
                fontSize: 19.0 * scale * fontScale,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF24252C),
                height: 1.25,
              ),
            ),
          ),
          SizedBox(width: 24.0 * scale),
        ],
      ),
    );
  }

  Widget _buildChallengeHeroCard(BuildContext context, Challenge challenge, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final dateFormat = DateFormat('MMM d, yyyy', isRTL ? 'ar' : 'en');
    final now = DateTime.now();
    final timeLeft = challenge.endDate.difference(now).inDays;
    final hasEnded = challenge.endDate.isBefore(now);
    final isUpcoming = challenge.startDate.isAfter(now);

    String timeLabel;
    if (hasEnded) {
      timeLabel = isRTL ? 'التحدي انتهى' : 'Challenge Ended';
    } else if (isUpcoming) {
      final daysToStart = challenge.startDate.difference(now).inDays;
      timeLabel = isRTL ? 'يبدأ في $daysToStart أيام' : 'Starts in $daysToStart Days';
    } else {
      timeLabel = isRTL ? '$timeLeft أيام متبقية' : '$timeLeft Days Left';
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20 * scale,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Challenge image
            challenge.imageUrl != null && challenge.imageUrl!.startsWith('http')
              ? Image.network(
                  challenge.imageUrl!,
                  width: double.infinity,
                  height: 120.0 * scale,
                  fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => Image.asset(
                     'assets/images/running.png',
                     width: double.infinity,
                     height: 120.0 * scale,
                     fit: BoxFit.cover,
                  ),
                )
              : Image.asset(
                  challenge.imageUrl ?? 'assets/images/running.png',
                  width: double.infinity,
                  height: 120.0 * scale,
                  fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => Image.asset(
                     'assets/images/running.png',
                     width: double.infinity,
                     height: 120.0 * scale,
                     fit: BoxFit.cover,
                  ),
                ),
            // Gradient section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                  end: isRTL ? Alignment.centerLeft : Alignment.centerRight,
                  colors: const [Color(0xFF910EBF), Color(0xFFFD3B6E)],
                ),
              ),
              padding: EdgeInsets.all(20.0 * scale),
              child: Row(
                children: [
                  // Left content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          challenge.title,
                          style: (isRTL ? GoogleFonts.cairo : GoogleFonts.lexendDeca)(
                            fontSize: 22.0 * scale * fontScale,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 8.0 * scale),
                        // Badge
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.0 * scale, vertical: 4.0 * scale),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF83A71).withValues(alpha: 0.73),
                            borderRadius: BorderRadius.circular(222.0 * scale),
                          ),
                          child: Text(
                            isRTL
                                ? 'ستربح ${NumberFormat.compact().format(challenge.rewardPoints)} نقطة'
                                : 'You will win ${NumberFormat.compact().format(challenge.rewardPoints)} points',
                            style: (isRTL ? GoogleFonts.cairo : GoogleFonts.poppins)(
                              fontSize: 11.0 * scale * fontScale,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.0 * scale),
                        // Date and Time
                        Wrap(
                          spacing: 12.0 * scale,
                          runSpacing: 6.0 * scale,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_rounded, color: Colors.white, size: 14.0 * scale),
                                SizedBox(width: 6.0 * scale),
                                Text(
                                  dateFormat.format(challenge.startDate),
                                  style: (isRTL ? GoogleFonts.cairo : GoogleFonts.poppins)(
                                    fontSize: 11.0 * scale * fontScale,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time_filled, color: Colors.white, size: 14.0 * scale),
                                SizedBox(width: 6.0 * scale),
                                Text(
                                  timeLabel,
                                  style: (isRTL ? GoogleFonts.cairo : GoogleFonts.poppins)(
                                    fontSize: 11.0 * scale * fontScale,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16.0 * scale),
                  // KM Badge (Right side)
                  Container(
                    width: 68.0 * scale,
                    height: 93.0 * scale,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5392),
                      borderRadius: BorderRadius.circular(19.43 * scale),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          challenge.targetKm.toStringAsFixed(0),
                          style: GoogleFonts.poppins(
                            fontSize: 23.0 * scale,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        Text(
                          l10n.kmLabel,
                          style: (isRTL ? GoogleFonts.cairo : GoogleFonts.poppins)(
                            fontSize: 13.0 * scale * fontScale,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

  Widget _buildWinPointsCard(BuildContext context, Challenge challenge, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final dateFormat = DateFormat('d MMM', isRTL ? 'ar' : 'en');
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 73.0 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF5F3F3).withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(15.0 * scale),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 23.0 * scale, vertical: 15.0 * scale),
        child: Row(
          children: [
            if (isRTL) ...[
              Container(
                width: 41.0 * scale,
                height: 41.0 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFF900EBF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.0 * scale),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/crown_icon.svg',
                    width: 24.0 * scale,
                    height: 24.0 * scale,
                    colorFilter: const ColorFilter.mode(Color(0xFF900EBF), BlendMode.srcIn),
                  ),
                ),
              ),
              SizedBox(width: 12.0 * scale),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isRTL
                        ? 'اربح ${NumberFormat.compact().format(challenge.rewardPoints)} نقطة'
                        : 'Win ${NumberFormat.compact().format(challenge.rewardPoints)} points',
                    style: (isRTL ? GoogleFonts.cairo : GoogleFonts.lexendDeca)(
                      fontSize: 18.0 * scale * fontScale,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.22,
                    ),
                  ),
                  SizedBox(height: 4.0 * scale),
                  Text(
                    isRTL
                        ? 'أكمل ${challenge.targetKm.toStringAsFixed(0)} كم بحلول ${dateFormat.format(challenge.endDate)}'
                        : 'Complete ${challenge.targetKm.toStringAsFixed(0)} km by ${dateFormat.format(challenge.endDate)}',
                    style: (isRTL ? GoogleFonts.cairo : GoogleFonts.lexendDeca)(
                      fontSize: 11.0 * scale * fontScale,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6E6A7C),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            if (!isRTL) Container(
              width: 41.0 * scale,
              height: 41.0 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFF900EBF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.0 * scale),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/crown_icon.svg',
                  width: 24.0 * scale,
                  height: 24.0 * scale,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF900EBF),
                    BlendMode.srcIn,
                  ),
                ),
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
            offset: const Offset(0, 4),
            blurRadius: 32,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow(context, l10n.totalDistance, '${challenge.targetKm.toStringAsFixed(0)} ${l10n.kmLabel}', scale, isRTL, fontScale),
          SizedBox(height: 7.0 * scale),
          _buildDetailRow(context, isRTL ? 'المدة' : 'Duration', '${dateFormat.format(challenge.startDate)}-${dateFormat.format(challenge.endDate)}', scale, isRTL, fontScale),
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
          style: (isRTL ? GoogleFonts.cairo : GoogleFonts.poppins)(
            fontSize: 12.0 * scale * fontScale,
            color: const Color(0xFF8B88B5),
          ),
        ),
        Text(
          value,
          style: (isRTL ? GoogleFonts.cairo : GoogleFonts.lexendDeca)(
            fontSize: 14.0 * scale * fontScale,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF24252C),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinButton(BuildContext context, WidgetRef ref, Challenge challenge, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final now = DateTime.now();
    final hasEnded = challenge.endDate.isBefore(now);
    final isUpcoming = challenge.startDate.isAfter(now);

    // If already joined, always allow viewing
    if (challenge.isJoined) {
      return GradientButton(
        text: l10n.goToChallenge,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MyChallengeScreen(challenge: challenge)),
          );
        },
        height: 58.0 * scale,
      );
    }

    // Challenge has ended - show disabled state
    if (hasEnded) {
      return GradientButton(
        text: l10n.challengeEndedButton,
        onPressed: () {},
        enabled: false,
        disabledColor: const Color(0xFF96AAD2),
        showIcon: false,
        height: 58.0 * scale,
      );
    }

    // Challenge hasn't started yet - show upcoming state
    if (isUpcoming) {
      final daysToStart = challenge.startDate.difference(now).inDays;
      return GradientButton(
        text: isRTL ? 'يبدأ في $daysToStart أيام' : 'Starts in $daysToStart days',
        onPressed: () {},
        enabled: false,
        disabledColor: const Color(0xFF900EBF),
        showIcon: false,
        height: 58.0 * scale,
      );
    }

    // Active challenge - allow joining
    return GradientButton(
      text: l10n.joinChallenge,
      onPressed: () async {
        try {
          await ref.read(challengeRepositoryProvider).joinChallenge(challenge.id);

          if (context.mounted) {
            ref.read(realTimeNotificationServiceProvider).showInAppBanner(
              l10n.challengeJoinedTitle,
              isRTL ? 'أنت الآن جزء من ${challenge.title}. هيا بنا!' : 'You are now part of the ${challenge.title}. Let\'s go!',
            );

            // Refresh challenges list and details
            ref.invalidate(challengesListProvider);
            ref.invalidate(challengeDetailsProvider(challenge.id));

            final joinedChallenge = Challenge(
              id: challenge.id,
              title: challenge.title,
              description: challenge.description,
              startDate: challenge.startDate,
              endDate: challenge.endDate,
              targetKm: challenge.targetKm,
              rewardPoints: challenge.rewardPoints,
              imageUrl: challenge.imageUrl,
              isJoined: true,
              userProgress: challenge.userProgress,
              progressPercentage: challenge.progressPercentage,
              participantCount: challenge.participantCount + 1,
            );

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyChallengeScreen(challenge: joinedChallenge)),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to join challenge: $e')),
            );
          }
        }
      },
      height: 58.0 * scale,
    );
  }
}
