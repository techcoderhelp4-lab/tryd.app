import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/custom_bottom_navigation.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/activity/presentation/running_screen.dart';
import '../features/rewards/presentation/rewards_screen.dart';
import '../features/activity/presentation/workout_screen.dart';
import '../features/club/presentation/club_screen.dart';
import '../../main.dart' show sharedPreferencesProvider;
import '../features/activity/data/workout_lock_screen_service.dart';

// ── Global providers ──────────────────────────────────────────────────────────

/// Current bottom-nav tab index (0-4).
final mainTabProvider = StateProvider<int>((ref) => 0);

/// RunningScreen sets this true during countdown so the bottom nav hides.
final isCountdownActiveProvider = StateProvider<bool>((ref) => false);

/// True while a run is in progress (running or paused). Shell uses this to
/// block tab-switches and swipes away from the running screen.
final isWorkoutActiveProvider = StateProvider<bool>((ref) => false);

/// Callback registered by RunningScreen so the shell can show the end-run
/// confirmation modal when the user tries to navigate away mid-run.
/// Returns true if the run was ended (navigation should proceed).
final workoutNavGuardProvider = StateProvider<Future<bool> Function()?>(
  (ref) => null,
);

/// True while a gym workout is in progress (running or paused). Shell uses
/// this to block tab-switches and swipes away from the workout screen.
final isGymWorkoutActiveProvider = StateProvider<bool>((ref) => false);

/// Callback registered by WorkoutScreen so the shell can show the end-workout
/// confirmation modal when the user tries to navigate away mid-workout.
final gymWorkoutNavGuardProvider = StateProvider<Future<bool> Function()?>(
  (ref) => null,
);

/// Shell's _onNavTap — child screens call this to properly animate the PageView.
final mainNavTapProvider = StateProvider<void Function(int)?>(
  (ref) => null,
);

// ── Shell ─────────────────────────────────────────────────────────────────────

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late final PageController _pageController;
  late final WorkoutLockScreenService _lockScreenService;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _requestLocationPermission();
    _lockScreenService = ref.read(workoutLockScreenServiceProvider);
    _lockScreenService.openTabStream.listen((tab) {
      if (mounted) _onNavTap(tab);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mainNavTapProvider.notifier).state = _onNavTap;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache important images to avoid decoding lag during swipes
    precacheImage(const AssetImage('assets/images/bg-gradient.png'), context);
    precacheImage(const AssetImage('assets/images/banner.png'), context);
    precacheImage(const AssetImage('assets/images/profile.png'), context);
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) return;
    if (permission == LocationPermission.deniedForever) return;

    final prefs = ref.read(sharedPreferencesProvider);
    const key = 'location_permission_asked';
    if (prefs.getBool(key) == true) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    await prefs.setBool(key, true);
    await Geolocator.requestPermission();
  }

  Future<void> _onNavTap(int index) async {
    if (!_pageController.hasClients) return;

    final prev = ref.read(mainTabProvider);
    if (prev == index) return;

    // Guard: leaving the running screen while a run is active.
    if (prev == 1 && ref.read(isWorkoutActiveProvider)) {
      final guard = ref.read(workoutNavGuardProvider);
      if (guard != null) {
        final shouldLeave = await guard();
        if (!shouldLeave) return;
      }
    }

    // Guard: leaving the workout screen while a gym workout is active.
    if (prev == 3 && ref.read(isGymWorkoutActiveProvider)) {
      final guard = ref.read(gymWorkoutNavGuardProvider);
      if (guard != null) {
        final shouldLeave = await guard();
        if (!shouldLeave) return;
      }
    }

    ref.read(mainTabProvider.notifier).state = index;

    final distance = (prev - index).abs();
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: distance == 1 ? 350 : 500),
      curve: Curves.easeInOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCountdown = ref.watch(isCountdownActiveProvider);
    final isWorkoutActive = ref.watch(isWorkoutActiveProvider);
    final isGymWorkoutActive = ref.watch(isGymWorkoutActiveProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      bottomNavigationBar: AnimatedSlide(
        offset: isCountdown ? const Offset(0, 1) : Offset.zero,
        duration: const Duration(milliseconds: 280),
        curve: isCountdown ? Curves.easeIn : Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: isCountdown ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: isCountdown ? Curves.easeIn : Curves.easeOut,
          child: Consumer(
            builder: (context, ref, _) {
              final currentIndex = ref.watch(mainTabProvider);
              return CustomBottomNavigation(
                currentIndex: currentIndex,
                onTap: _onNavTap,
              );
            },
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: (isWorkoutActive || isGymWorkoutActive)
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        dragStartBehavior: DragStartBehavior.down,
        allowImplicitScrolling: false,
        clipBehavior: Clip.none,
        onPageChanged: (index) {
          if (ref.read(mainTabProvider) != index) {
            ref.read(mainTabProvider.notifier).state = index;
          }
        },
        children: const [
          HomeScreen(),
          RunningScreen(),
          RewardsScreen(),
          WorkoutScreen(),
          ClubScreen(),
        ],
      ),
    );
  }
}
