import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../../../widgets/skeleton_loading.dart';
import '../../activity/presentation/running_screen.dart';
import '../../activity/presentation/activity_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../activity/presentation/workout_screen.dart';
import '../../club/presentation/club_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import '../../profile/data/user_repository.dart';
import '../../auth/domain/user.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../notifications/data/notification_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../onboarding/presentation/start_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tryd/src/generated/l10n/app_localizations.dart';
import '../../../../main.dart' show localeProvider, sharedPreferencesProvider;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    // If already granted, nothing to do
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) return;

    // If permanently denied, nothing we can do programmatically
    if (permission == LocationPermission.deniedForever) return;

    // Only ask once — track via SharedPreferences
    final prefs = ref.read(sharedPreferencesProvider);
    const key = 'location_permission_asked';
    if (prefs.getBool(key) == true) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    await prefs.setBool(key, true);
    await Geolocator.requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;
    final isTablet = screenWidth > 600;
    final l10n = AppLocalizations.of(context)!;

    // ── Responsive Scale ──────────────────────────────────
    // Change these 4 values to control ALL component sizes:
    //   small  → phones with height < 680px
    //   medium → phones with height 680–850px
    //   large  → phones with height > 850px
    //   tablet → devices with width > 600px
    const double smallScale  = 0.65;
    const double mediumScale = 0.78;
    const double largeScale  = 0.80;
    const double tabletScale = 1.05;

    final double scale = isTablet
        ? tabletScale
        : screenHeight < 680
            ? smallScale
            : screenHeight < 850
                ? mediumScale
                : largeScale;

    final fontScale = Localizations.localeOf(context).languageCode == 'ar' ? 1.15 : 1.0;

    final userAsync = ref.watch(userProfileProvider);
    final activityAsync = ref.watch(activitySummaryProvider('month'));
    final horizontalPadding = (isTablet ? 16.0 : 15.0) * scale;
    final bottomPadding = (isTablet ? 100.0 : 140.0) * scale;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 0) return;

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
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: const Color(0xFF900EBF),
          onRefresh: () async {
            ref.invalidate(userProfileProvider);
            ref.invalidate(activitySummaryProvider('month'));
            await Future.wait([
              ref.read(userProfileProvider.future),
              ref.read(activitySummaryProvider('month').future),
            ]);
          },
          child: Stack(
            children: [
              userAsync.when(
                data: (user) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  child: Column(
                    children: [
                      _buildHeader(context, horizontalPadding, user, isTablet, scale, l10n),
                      SizedBox(height: (isTablet ? 10.0 : 12.0) * scale),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.black.withOpacity(0.1),
                      ),
                      SizedBox(height: 8.0 * scale),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: Column(
                          children: [
                            _buildPointsCard(context, user.points ?? 0, isTablet, scale, l10n),
                            SizedBox(height: 8.0 * scale),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: horizontalPadding),
                        child: _buildBannerCard(horizontalPadding, isTablet, scale),
                      ),
                      activityAsync.when(
                        data: (activityData) => Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: Column(
                            children: [
                              SizedBox(height: 8.0 * scale),
                              _buildCurrentMonthCard(context, activityData, isTablet, scale, l10n),
                              SizedBox(height: (isTablet ? 12.0 : 16.0) * scale),
                              _buildStatsGrid(context, activityData, isTablet, scale, l10n),
                              SizedBox(height: bottomPadding),
                            ],
                          ),
                        ),
                        loading: () => Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: Column(
                            children: [
                              SizedBox(height: 8.0 * scale),
                              // Current month skeleton
                              SkeletonBox(
                                width: double.infinity,
                                height: (isTablet ? 70.0 : 80.0) * scale,
                                borderRadius: (isTablet ? 12.0 : 15.0) * scale,
                              ),
                              SizedBox(height: (isTablet ? 12.0 : 16.0) * scale),
                              // Stats grid skeleton
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        SkeletonBox(width: double.infinity, height: 152.0 * scale, borderRadius: 15.0 * scale),
                                        SizedBox(height: 12.0 * scale),
                                        SkeletonBox(width: double.infinity, height: 130.0 * scale, borderRadius: 15.0 * scale),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 10.0 * scale),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        SkeletonBox(width: double.infinity, height: 130.0 * scale, borderRadius: 15.0 * scale),
                                        SizedBox(height: 12.0 * scale),
                                        SkeletonBox(width: double.infinity, height: 152.0 * scale, borderRadius: 15.0 * scale),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        error: (err, stack) => Container(
                          padding: EdgeInsets.all(20.0 * scale),
                          margin: EdgeInsets.only(top: 8.0 * scale),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(15.0 * scale),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.activityLoadError,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14 * scale * fontScale,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.red, size: 18),
                                onPressed: () => ref.invalidate(activitySummaryProvider('month')),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => Stack(
                  children: [
                    HomeSkeletonLoading(scale: scale, isTablet: isTablet),
                    Positioned(
                      top: (isTablet ? 20.0 : 32.0) * scale,
                      right: horizontalPadding,
                      child: TextButton.icon(
                        onPressed: () async {
                          try {
                            await ref.read(authControllerProvider.notifier).logout();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const StartScreen()),
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Logout failed: $e')),
                              );
                            }
                          }
                        },
                        icon: Icon(Icons.logout, size: 18.0 * scale, color: const Color(0xFFF83A71)),
                        label: Text(l10n.logoutLabel, style: GoogleFonts.poppins(
                          fontSize: 13.0 * scale * fontScale,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF83A71),
                        )),
                      ),
                    ),
                  ],
                ),
                error: (err, stack) {
                  // For debugging: debugPrint('Home error: $err');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            l10n.somethingWentWrong,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF221F48),
                              fontSize: 16 * fontScale,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              await ref.read(authControllerProvider.notifier).logout();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const StartScreen()),
                                  (route) => false,
                                );
                              }
                            } catch (e) {
                              // If logout fails, at least we tried. Just navigate if possible.
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const StartScreen()),
                                  (route) => false,
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF900EBF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            l10n.loginLabel,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15 * fontScale,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
  
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildHeader(BuildContext context, double horizontalPadding, User user, bool isTablet, double scale, AppLocalizations l10n) {
    final fontScale = Localizations.localeOf(context).languageCode == 'ar' ? 1.15 : 1.0;
    final avatarSize = (isTablet ? 45.0 : 50.0) * scale;
    final topPadding = (isTablet ? 12.0 : 18.0) * scale;
    final bottomPadding = (isTablet ? 8.0 : 12.0) * scale;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE5E7EB),
              ),
              child: ClipOval(
                child: (user.profilePicture != null && user.profilePicture!.isNotEmpty)
                    ? Image.network(
                        user.profilePicture!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/profile.png',
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/images/profile.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          SizedBox(width: (isTablet ? 12.0 : 16.0) * scale),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.helloGreeting,
                    style: GoogleFonts.lexendDeca(
                      fontSize: 16.0 * scale * fontScale,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF24252C),
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    user.name,
                    style: GoogleFonts.lexendDeca(
                      fontSize: 22.0 * scale * fontScale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8.0 * scale),
          _buildLangToggle(scale),
          SizedBox(width: 4.0 * scale),
          _buildNotificationBell(context, isTablet, scale),
        ],
      ),
    );
  }

  Widget _buildLangToggle(double scale) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return PopupMenuButton<String>(
      onSelected: (value) {
        ref.read(localeProvider.notifier).setLocale(Locale(value));
      },
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: Offset(0, 40 * scale),
      constraints: BoxConstraints(minWidth: 170 * scale),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'en',
          height: 44 * scale,
          padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 2 * scale),
          child: Row(
            children: [
              Text('English',
                  style: GoogleFonts.lexendDeca(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w600,
                      color: !isAr ? const Color(0xFF900EBF) : const Color(0xFF24252C))),
              const Spacer(),
              if (!isAr)
                Icon(Icons.check_rounded, size: 18 * scale, color: const Color(0xFF900EBF)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'ar',
          height: 44 * scale,
          padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 2 * scale),
          child: Row(
            children: [
              Text('العربية',
                  style: GoogleFonts.cairo(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w600,
                      color: isAr ? const Color(0xFF900EBF) : const Color(0xFF24252C))),
              const Spacer(),
              if (isAr)
                Icon(Icons.check_rounded, size: 18 * scale, color: const Color(0xFF900EBF)),
            ],
          ),
        ),
      ],
      child: Icon(
        Icons.language_rounded,
        size: 34.0 * scale,
        color: const Color(0xFF24252C),
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context, bool isTablet, double scale) {
    final fontScale = Localizations.localeOf(context).languageCode == 'ar' ? 1.15 : 1.0;
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    final iconSize = (isTablet ? 32.0 : 36.0) * scale;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.0 * scale),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: iconSize,
              color: const Color(0xFF24252C),
            ),
            unreadCountAsync.when(
              data: (count) {
                if (count == 0) return const SizedBox.shrink();
                return Positioned(
                  right: -1.0,
                  top: -1.0,
                  child: Container(
                    padding: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF83A71),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: BoxConstraints(
                      minWidth: (isTablet ? 20.0 : 22.0) * scale,
                      minHeight: (isTablet ? 20.0 : 22.0) * scale,
                    ),
                    child: Center(
                      child: Text(
                        count > 9 ? '9+' : count.toString(),
                        style: GoogleFonts.lexendDeca(
                          fontSize: 11.5 * scale * fontScale,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard(BuildContext context, int points, bool isTablet, double scale, AppLocalizations l10n) {
    final fontScale = Localizations.localeOf(context).languageCode == 'ar' ? 1.15 : 1.0;
    final cardHeight = (isTablet ? 60.0 : 66.0) * scale;
    final iconContainerSize = (isTablet ? 38.0 : 44.0) * scale;
    final borderRadius = (isTablet ? 14.0 : 16.0) * scale;
    final horizontalPadding = (isTablet ? 12.0 : 14.0) * scale;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RewardsScreen()),
        );
      },
      child: Container(
        constraints: BoxConstraints(minHeight: cardHeight),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: (isTablet ? 8.0 : 11.0) * scale),
        child: Row(
          children: [
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD66B),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/crown_icon.svg',
                  width: (isTablet ? 20.0 : 25.0) * scale,
                  height: (isTablet ? 18.0 : 22.0) * scale,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            SizedBox(width: (isTablet ? 12.0 : 14.0) * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                      style: GoogleFonts.poppins(
                        fontSize: 24.0 * scale * fontScale,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF221F48),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: (isTablet ? 1.0 : 4.0) * scale),
                  Text(
                    l10n.availablePointsLabel,
                    style: GoogleFonts.lexendDeca(
                      fontSize: 14.0 * scale * fontScale,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF221F48),
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

  Widget _buildBannerCard(double horizontalPadding, bool isTablet, double scale) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular((isTablet ? 18.0 : 22.0) * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: isTablet ? (334 / 140) : (334 / 160),
        child: ClipRRect(
          borderRadius: BorderRadius.circular((isTablet ? 18.0 : 22.0) * scale),
          child: Image.asset(
            'assets/images/banner.png',
            fit: BoxFit.cover,
            semanticLabel: 'Promotional Banner',
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFFEEEEEE),
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentMonthCard(BuildContext context, Map<String, dynamic> data, bool isTablet, double scale, AppLocalizations l10n) {
    final fontScale = Localizations.localeOf(context).languageCode == 'ar' ? 1.15 : 1.0;
    final distance = data['distance']?.toStringAsFixed(2) ?? '0.00';
    final cardHeight = (isTablet ? 70.0 : 80.0) * scale;
    final iconSize = (isTablet ? 38.0 : 43.0) * scale;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ActivityScreen()),
        );
      },
      child: Container(
        constraints: BoxConstraints(minHeight: cardHeight),
        padding: EdgeInsets.symmetric(horizontal: (isTablet ? 14.0 : 19.0) * scale, vertical: (isTablet ? 10.0 : 14.0) * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFF5F3F3).withOpacity(0.62),
          ),
          borderRadius: BorderRadius.circular((isTablet ? 12.0 : 15.0) * scale),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 32,
              color: Colors.black.withOpacity(0.04),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: const BoxDecoration(
                color: Color(0xFFEDE4FF),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/runner_icon.svg',
                  width: (isTablet ? 14.0 : 16.0) * scale,
                  height: (isTablet ? 20.0 : 23.0) * scale,
                ),
              ),
            ),
            SizedBox(width: (isTablet ? 12.0 : 14.0) * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.currentMonthLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 13.0 * scale * fontScale,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF24252C),
                    ),
                  ),
                  Text(
                    '$distance ${l10n.kmSuffix}',
                    style: GoogleFonts.poppins(
                      fontSize: 19.0 * scale * fontScale,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF221F48),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.visibility,
              color: const Color(0xFF900EBF),
              size: (isTablet ? 20.0 : 23.0) * scale,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> data, bool isTablet, double scale, AppLocalizations l10n) {
    final steps = data['steps']?.toString() ?? '0';
    final rawCalories = (data['calories'] ?? data['caloriesBurned'] ?? 0);
    final calories = rawCalories is num ? rawCalories.toStringAsFixed(1) : rawCalories.toString();

    String duration = '0';
    final rawDuration = data['duration'];
    if (rawDuration is int) {
      duration = (rawDuration ~/ 60).toString();
    } else {
      duration = rawDuration?.toString() ?? '0';
    }

    final rawBpm = data['bpm'];
    final bpm = (rawBpm == null || rawBpm == 0 || rawBpm == 0.0) ? '--' : rawBpm.toString();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildStatCard(
                context: context,
                backgroundColor: const Color(0xFFEBF9FC),
                iconBackgroundColor: const Color(0xFFD0F5FD),
                svgIcon: 'assets/images/footsteps_icon.svg',
                iconColor: const Color(0xFF34CDFD),
                value: steps,
                label: l10n.stepsCountLabel,
                height: 152.0 * scale,
                iconTopPadding: 22.0 * scale,
                isTablet: isTablet,
                scale: scale,
              ),
              SizedBox(height: 12.0 * scale),
              _buildStatCard(
                context: context,
                backgroundColor: const Color(0xFFEFEAFC),
                iconBackgroundColor: const Color(0xFFCDC0F4),
                svgIcon: 'assets/images/clock_icon.svg',
                iconColor: const Color(0xFF5D37E5),
                value: duration,
                label: l10n.durationsLabel,
                suffix: l10n.minsSuffix,
                height: 130.0 * scale,
                iconTopPadding: 16.0 * scale,
                isTablet: isTablet,
                scale: scale,
              ),
            ],
          ),
        ),
        SizedBox(width: 10.0 * scale),
        Expanded(
          child: Column(
            children: [
              _buildStatCard(
                context: context,
                backgroundColor: const Color(0xFFFFF8E8),
                iconBackgroundColor: const Color(0xFFFFE8BA),
                svgIcon: 'assets/images/fire_icon.svg',
                iconColor: const Color(0xFFFEB720),
                value: calories,
                label: l10n.burnedCaloriesLabel,
                height: 130.0 * scale,
                iconTopPadding: 15.0 * scale,
                isTablet: isTablet,
                scale: scale,
              ),
              SizedBox(height: 12.0 * scale),
              _buildStatCard(
                context: context,
                backgroundColor: const Color(0xFFFFECEB),
                iconBackgroundColor: const Color(0xFFFBC7C1),
                icon: Icons.favorite,
                iconColor: const Color(0xFFFE413D),
                value: bpm,
                label: l10n.averageBpmLabel,
                height: 152.0 * scale,
                iconTopPadding: 23.0 * scale,
                isTablet: isTablet,
                scale: scale,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required Color backgroundColor,
    required Color iconBackgroundColor,
    IconData? icon,
    String? svgIcon,
    required Color iconColor,
    required String value,
    required String label,
    required double height,
    required double iconTopPadding,
    required bool isTablet,
    required double scale,
    String? suffix,
    double? svgWidth,
    double? svgHeight,
  }) {
    final fontScale = Localizations.localeOf(context).languageCode == 'ar' ? 1.15 : 1.0;
    final iconContainerSize = 43.0 * scale;
    final innerPaddingHorizontal = 20.0 * scale;
    final innerPaddingBottom = 15.0 * scale;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15.0 * scale),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(innerPaddingHorizontal, iconTopPadding, 15.0 * scale, innerPaddingBottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: svgIcon != null
                    ? SvgPicture.asset(
                        svgIcon,
                        width: svgWidth ?? 21.0 * scale,
                        height: svgHeight ?? 21.0 * scale,
                        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                      )
                    : Icon(
                        icon!,
                        color: iconColor,
                        size: 21.0 * scale,
                      ),
              ),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 19.0 * scale * fontScale,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (suffix != null) ...[
                  SizedBox(width: 4.0 * scale),
                  Padding(
                    padding: EdgeInsets.only(bottom: 2.0 * scale),
                    child: Text(
                      suffix,
                      style: GoogleFonts.poppins(
                        fontSize: 13.0 * scale * fontScale,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8B88B5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 4.0 * scale),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16.0 * scale * fontScale,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8B88B5),
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
