import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../../widgets/custom_work_icon.dart';
import '../../../../widgets/custom_refresh_icon.dart';
import '../../../../widgets/custom_exercises_icon.dart';
import '../../../../widgets/custom_rounds_icon.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import '../data/activity_repository.dart';
import '../domain/workout.dart';
import '../domain/workout_controller.dart';
import 'add_number_screen.dart';
import 'add_time_screen.dart';
import 'history_screen.dart';
import '../../../shell/main_shell.dart' show gymWorkoutNavGuardProvider, isGymWorkoutActiveProvider, mainTabProvider, mainNavTapProvider;
import '../../home/presentation/home_screen.dart';
import '../../activity/presentation/running_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import '../../club/presentation/club_screen.dart';
import '../../challenges/data/challenge_repository.dart';
import 'package:tryd/src/generated/l10n/app_localizations.dart';
import 'package:tryd/main.dart' show localeProvider;
import '../domain/pre_built_workouts_data.dart';
import '../../../../widgets/swipe_to_pop_wrapper.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../../../widgets/custom_gradient_button.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  final bool showSwipeBack;
  const WorkoutScreen({super.key, this.showSwipeBack = false});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  bool _isWorkoutSaved = false;
  PreBuiltWorkout? _selectedPreBuiltWorkout;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(gymWorkoutNavGuardProvider.notifier).state = () async {
        final result = await _showExitConfirmationAsync();
        return result;
      };
      ref.read(workoutControllerProvider.notifier)
          .setLocale(ref.read(localeProvider).languageCode);
    });
  }

  @override
  void dispose() {
    ref.read(gymWorkoutNavGuardProvider.notifier).state = null;
    ref.read(isGymWorkoutActiveProvider.notifier).state = false;
    WidgetsBinding.instance.removeObserver(this);
    _disableWakelock();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(workoutControllerProvider.notifier);
    if (state == AppLifecycleState.paused) {
      controller.handleAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      controller.handleAppResumed();
    }
  }

  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('Wakelock enable error: $e');
    }
  }

  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('Wakelock disable error: $e');
    }
  }

  void _toggleTimer() {
    HapticFeedback.mediumImpact();
    final controller = ref.read(workoutControllerProvider.notifier);
    final state = ref.read(workoutControllerProvider);

    if (state.status == WorkoutStatus.running) {
      controller.pause();
      _disableWakelock();
    } else {
      _isWorkoutSaved = false;
      controller.start();
      _enableWakelock();

      // Check for completion after starting (use fresh state, not stale)
      final updatedState = ref.read(workoutControllerProvider);
      if (updatedState.status == WorkoutStatus.finished && !_isWorkoutSaved) {
        _saveWorkoutCompletion(updatedState);
      }
    }
  }

  void _stopWorkout() {
    HapticFeedback.mediumImpact();
    _showExitConfirmation();
  }

  Future<void> _saveWorkoutCompletion(WorkoutState state) async {
    if (_isWorkoutSaved) return;
    _isWorkoutSaved = true;

    final duration = state.elapsedSeconds > 0
        ? state.elapsedSeconds
        : (state.workDuration * state.totalRounds + state.restDuration * state.totalRounds) * state.totalExercises;

    final estimatedCalories = duration * 0.15;

    int completedRoundsInCurrent = state.currentRound - 1;
    if (state.phase == WorkoutPhase.rest || state.status == WorkoutStatus.finished) {
      completedRoundsInCurrent++;
    }

    int completedExercises = state.currentExercise - 1;
    if (completedRoundsInCurrent >= state.totalRounds) {
      completedExercises++;
    }

    // Total rounds completed across all exercises
    // We cap current rounds at totalRounds to avoid overflow logic
    int totalRoundsCompleted = ((state.currentExercise - 1) * state.totalRounds) +
        (completedRoundsInCurrent > state.totalRounds ? state.totalRounds : completedRoundsInCurrent);

    final workout = Workout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'workout',
      duration: duration,
      calories: estimatedCalories,
      date: DateTime.now(),
      exercises: completedExercises,
      rounds: totalRoundsCompleted,
      workDuration: state.totalWorkSeconds,
      restDuration: state.totalRestSeconds,
    );

    await ref.read(workoutHistoryProvider.notifier).addWorkout(workout);

    // Fire-and-forget: don't block workout save for challenge progress
    ref.read(challengeRepositoryProvider).updateAllChallengesProgress(
      distanceKm: 0,
      durationSeconds: duration,
      calories: estimatedCalories,
    ).catchError((e) => debugPrint('Failed to update challenge progress: $e'));
  }

  void _showCompletionDialog(WorkoutState state) {
    if (!_isWorkoutSaved) {
      _saveWorkoutCompletion(state);
    }

    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 32.0, left: 24.0, right: 24.0, bottom: 24.0),
              child: Column(
                children: [
                  Text(
                    l10n.workoutComplete,
                    style: GoogleFonts.lexend(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.workoutCompleteMessage,
                    style: GoogleFonts.lexend(
                      fontSize: 14.0,
                      color: const Color(0xFF24252C).withOpacity(0.8),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFE5E7EB), height: 1, thickness: 1),
            InkWell(
              onTap: () {
                ref.read(workoutControllerProvider.notifier).reset();
                _isWorkoutSaved = false;
                Navigator.of(context).pop(); // close dialog
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(); // pop screen if pushed
                } else {
                  ref.read(mainTabProvider.notifier).state = 0;
                }
              },
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                alignment: Alignment.center,
                child: Text(
                  l10n.doneButton,
                  style: GoogleFonts.lexend(
                    fontSize: 16.0,
                    color: const Color(0xFF900EBF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 32.0, left: 24.0, right: 24.0, bottom: 24.0),
                child: Column(
                  children: [
                    Text(
                      l10n.endWorkoutTitle,
                    style: GoogleFonts.lexend(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.endWorkoutMessage,
                    style: GoogleFonts.lexend(
                      fontSize: 14.0,
                      color: const Color(0xFF24252C).withOpacity(0.8),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFE5E7EB), height: 1, thickness: 1),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20.0)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.cancelButton,
                          style: GoogleFonts.lexend(
                            fontSize: 16.0,
                            color: const Color(0xFF989898),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const VerticalDivider(color: Color(0xFFE5E7EB), width: 1, thickness: 1),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _disableWakelock();
                        final currentState = ref.read(workoutControllerProvider);
                        if (currentState.elapsedSeconds > 0 || currentState.status != WorkoutStatus.idle) {
                          _saveWorkoutCompletion(currentState);
                        }
                        ref.read(workoutControllerProvider.notifier).reset();
                        Navigator.pop(context);
                      },
                      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20.0)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.endButton,
                          style: GoogleFonts.lexend(
                            fontSize: 16.0,
                            color: const Color(0xFFFF5656),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  // Returns true if user confirmed ending the workout (navigation may proceed),
  // false if they cancelled.
  Future<bool> _showExitConfirmationAsync() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 32.0, left: 24.0, right: 24.0, bottom: 24.0),
              child: Column(
                children: [
                  Text(
                    l10n.endWorkoutTitle,
                    style: GoogleFonts.lexend(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.endWorkoutMessage,
                    style: GoogleFonts.lexend(
                      fontSize: 14.0,
                      color: const Color(0xFF24252C).withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFE5E7EB), height: 1, thickness: 1),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx, false),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20.0)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.cancelButton,
                          style: GoogleFonts.lexend(
                            fontSize: 16.0,
                            color: const Color(0xFF989898),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const VerticalDivider(color: Color(0xFFE5E7EB), width: 1, thickness: 1),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _disableWakelock();
                        final currentState = ref.read(workoutControllerProvider);
                        if (currentState.elapsedSeconds > 0 || currentState.status != WorkoutStatus.idle) {
                          _saveWorkoutCompletion(currentState);
                        }
                        ref.read(workoutControllerProvider.notifier).reset();
                        Navigator.pop(ctx, true);
                      },
                      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20.0)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.endButton,
                          style: GoogleFonts.lexend(
                            fontSize: 16.0,
                            color: const Color(0xFFFF5656),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return confirmed == true;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatSecondsToWords(int seconds, AppLocalizations l10n, {bool colonStyle = false}) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (colonStyle) {
      if (m > 0 && s > 0) return '$m ${l10n.minUnit} : $s ${l10n.secUnit}';
      if (m > 0) return '$m ${l10n.minUnit}';
      return '$s ${l10n.secUnit}';
    }
    // Under 2 minutes: show raw seconds for clarity
    if (seconds < 120) return '$seconds ${l10n.secUnit}';
    if (m > 0 && s > 0) return '$m ${l10n.minUnit} $s ${l10n.secUnit}';
    return '$m ${l10n.minUnit}';
  }

  String _formatDuration(int seconds, AppLocalizations l10n) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes == 0) return '$secs ${l10n.secUnit}';
    if (secs == 0) return '$minutes ${l10n.minUnit}';
    return '$minutes ${l10n.minUnit} $secs ${l10n.secUnit}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen(localeProvider, (_, locale) {
      ref.read(workoutControllerProvider.notifier).setLocale(locale.languageCode);
    });
    final state = ref.watch(workoutControllerProvider);
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;
    final isTablet = screenWidth > 600;
    final l10n = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isRTL ? 1.15 : 1.0;

    // ── Responsive Scale ──────────────────────────────────
    const double smallScale  = 0.70;
    const double mediumScale = 0.80;
    const double largeScale  = 0.85;
    const double tabletScale = 1.15;

    final double scale = isTablet
        ? tabletScale
        : screenHeight < 680
            ? smallScale
            : screenHeight < 850
                ? mediumScale
                : largeScale;

    // Keep isGymWorkoutActiveProvider in sync so the shell can lock swipe/nav.
    ref.listen(workoutControllerProvider, (prev, next) {
      final active = next.status == WorkoutStatus.running ||
          next.status == WorkoutStatus.paused;
      if (ref.read(isGymWorkoutActiveProvider) != active) {
        ref.read(isGymWorkoutActiveProvider.notifier).state = active;
      }
    });

    // Reliable listener for finished state
    ref.listen(workoutControllerProvider, (prev, next) {
      if (prev?.status != WorkoutStatus.finished && next.status == WorkoutStatus.finished) {
        if (!_isWorkoutSaved) {
          _saveWorkoutCompletion(next);
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCompletionDialog(next);
        });
      }
    });

    final timerCardGradient = const LinearGradient(
      colors: [Color(0xFF910EBF), Color(0xFFFD3B6E)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    // ── Sub-screen: Pre-built workout detail ─────────────
    if (_selectedPreBuiltWorkout != null) {
      final hPad = (isTablet ? 20.0 : 15.0) * scale;
      final subContent = Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/images/bg-gradient.png', fit: BoxFit.cover),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // header
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPad, (isTablet ? 15.0 : 20.0) * scale, hPad, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _selectedPreBuiltWorkout = null),
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: 42.0 * scale,
                            height: 42.0 * scale,
                            child: SvgPicture.asset(
                              'assets/images/back_arrow_icon.svg',
                              width: 42.0 * scale,
                              height: 42.0 * scale,
                              matchTextDirection: true,
                            ),
                          ),
                        ),
                        Text(
                          _selectedPreBuiltWorkout!.title,
                          style: GoogleFonts.lexendDeca(
                            fontSize: 19.0 * scale * fontScale,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF24252C),
                          ),
                        ),
                        SizedBox(width: 42.0 * scale),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.0 * scale),
                  // cards
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: _buildPreBuiltCardsRow(isTablet, scale, fontScale),
                  ),
                  SizedBox(height: 12.0 * scale),
                  // white container fills rest
                  Expanded(
                    child: _buildPreBuiltWorkoutDetail(
                      _selectedPreBuiltWorkout!,
                      isTablet,
                      scale,
                      l10n,
                      fontScale,
                    ),
                  ),
                ],
              ),
            ),
            if (Navigator.of(context).canPop())
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CustomBottomNavigation(
                  currentIndex: 3,
                  onTap: (index) async {
                    if (index == 3) return;
                    if (ref.read(isGymWorkoutActiveProvider)) {
                      final shouldLeave = await _showExitConfirmationAsync();
                      if (!shouldLeave || !mounted) return;
                    }
                    if (!mounted) return;
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    ref.read(mainNavTapProvider)?.call(index);
                  },
                ),
              ),
          ],
        ),
      );
      if (widget.showSwipeBack) return SwipeToPopWrapper(child: subContent);
      return subContent;
    }

    final content = Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
             child: Image.asset(
               'assets/images/bg-gradient.png',
               fit: BoxFit.cover,
             ),
          ),

          if (Navigator.of(context).canPop())
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNavigation(
                currentIndex: 3,
                onTap: (index) async {
                  if (index == 3) return;
                  if (ref.read(isGymWorkoutActiveProvider)) {
                    final shouldLeave = await _showExitConfirmationAsync();
                    if (!shouldLeave || !mounted) return;
                  }
                  Widget target;
                  switch (index) {
                    case 0: target = HomeScreen(); break;
                    case 1: target = const RunningScreen(); break;
                    case 2: target = RewardsScreen(showSwipeBack: true); break;
                    case 4: target = const ClubScreen(); break;
                    default: return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => target),
                  );
                },
              ),
            ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context, isTablet, state, scale, l10n, isRTL, fontScale),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: (isTablet ? 20.0 : 15.0) * scale),
                      child: Column(
                        children: [
                          SizedBox(height: 15.0 * scale),
                          _buildTimerCard(context, timerCardGradient, isTablet, state, scale, l10n, fontScale),
                          SizedBox(height: 20.0 * scale),
                          _buildTotalTimeCard(state, scale, l10n, fontScale),
                          SizedBox(height: 20.0 * scale),
                          _buildConfigGrid(isTablet, state, scale, l10n, fontScale),
                          SizedBox(height: 20.0 * scale),
                          _buildWorkoutControls(isTablet, state, scale, l10n, fontScale),
                          SizedBox(height: 20.0 * scale),
                          _buildPreBuiltWorkouts(isTablet, state, scale, l10n, fontScale),

                          SizedBox(height: (isTablet ? 140.0 : 160.0) * scale),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (Navigator.of(context).canPop())
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNavigation(
                currentIndex: 3,
                onTap: (index) async {
                  if (index == 3) return;
                  if (ref.read(isGymWorkoutActiveProvider)) {
                    final shouldLeave = await _showExitConfirmationAsync();
                    if (!shouldLeave || !mounted) return;
                  }
                  if (!mounted) return;
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  ref.read(mainNavTapProvider)?.call(index);
                },
              ),
            ),
          ],
        ),
    );

    if (widget.showSwipeBack) {
      return SwipeToPopWrapper(child: content);
    }
    return content;
  }

  Widget _buildHeader(BuildContext context, bool isTablet, WorkoutState state, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final horizontalPadding = (isTablet ? 20.0 : 15.0) * scale;
    final topPadding = (isTablet ? 15.0 : 20.0) * scale;
    final iconSize = (isTablet ? 28.0 : 28.0) * scale;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, topPadding, horizontalPadding, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              if (state.status == WorkoutStatus.running || state.status == WorkoutStatus.paused) {
                _showExitConfirmation();
              } else {
                ref.read(mainNavTapProvider)?.call(0);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 42.0 * scale,
              height: 42.0 * scale,
              child: SvgPicture.asset(
                'assets/images/back_arrow_icon.svg',
                width: 42.0 * scale,
                height: 42.0 * scale,
                matchTextDirection: true,
              ),
            ),
          ),
          Text(
            l10n.workoutsTitle,
            style: GoogleFonts.lexendDeca(
              fontSize: 19.0 * scale * fontScale,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF24252C),
            ),
          ),
          GestureDetector(
             onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => const HistoryScreen()),
               );
             },
             child: Icon(
               Icons.history,
               size: iconSize,
               color: const Color(0xFF24252C)
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard(BuildContext context, Gradient gradient, bool isTablet, WorkoutState state, double scale, AppLocalizations l10n, double fontScale) {
    final cardHeight = (isTablet ? 180.0 : 165.0) * scale;
    final hPadding = (isTablet ? 24.0 : 20.0) * scale;

    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(17.0 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 32,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.exerciseProgress(
              state.currentExercise.toString(),
              state.totalExercises.toString(),
            ),
            style: GoogleFonts.lexend(
              fontSize: 17.0 * scale * fontScale,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 5.0 * scale),
          Text(
            _formatTime(state.remainingSeconds),
            style: GoogleFonts.lexend(
              fontSize: 52.0 * scale,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          SizedBox(height: 5.0 * scale),
          Text(
            "${_formatSecondsToWords(state.workDuration, l10n)} ${l10n.workLabel} / ${_formatSecondsToWords(state.restDuration, l10n)} ${l10n.restLabel}",
            style: GoogleFonts.poppins(
              fontSize: 16.0 * scale * fontScale,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSkipControls(bool isTablet, WorkoutState state, double scale, AppLocalizations l10n, double fontScale) {
    if (state.status != WorkoutStatus.running || state.phase != WorkoutPhase.rest) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => ref.read(workoutControllerProvider.notifier).skipRest(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0 * scale, vertical: 8.0 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFFFEB720).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.0 * scale),
              border: Border.all(color: const Color(0xFFFEB720).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fast_forward_rounded, size: 18.0 * scale, color: const Color(0xFFFEB720)),
                SizedBox(width: 6.0 * scale),
                Text(
                  l10n.skipRest,
                  style: GoogleFonts.lexend(
                    fontSize: 12.0 * scale * fontScale,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFEB720),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigGrid(bool isTablet, WorkoutState state, double scale, AppLocalizations l10n, double fontScale) {
    final gap = 12.0 * scale;
    final isActive = state.status == WorkoutStatus.running || state.status == WorkoutStatus.paused;

    // During workout: highlight only the current phase card, grey out the rest
    final isWorkHighlighted = isActive && state.phase == WorkoutPhase.work;
    final isRestHighlighted = isActive && state.phase == WorkoutPhase.rest;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column
        Expanded(
          child: Column(
            children: [
              _buildConfigCard(
                context: context,
                label: l10n.workLabel,
                value: _formatDuration(state.workDuration, l10n),
                colorBg: isWorkHighlighted ? const Color(0xFFDCF7FE) : const Color(0xFFEBF9FC),
                colorIconBg: const Color(0xFFD0F5FD),
                colorIcon: const Color(0xFF34CDFD),
                customIcon: CustomWorkIcon(size: 21.0 * scale, color: const Color(0xFF34CDFD)),
                onTap: () => _navigateToTimeScreen('work', state),
                isTablet: isTablet,
                scale: scale,
                fontScale: fontScale,
                isDisabled: isActive && !isWorkHighlighted,
              ),
              SizedBox(height: gap),
              _buildConfigCard(
                context: context,
                label: l10n.exercisesLabel,
                value: '${state.totalExercises}',
                colorBg: const Color(0xFFEFEAFC),
                colorIconBg: const Color(0xFFCDC0F4),
                colorIcon: const Color(0xFF5D37E5),
                customIcon: CustomExercisesIcon(size: 21.0 * scale, color: const Color(0xFF5D37E5)),
                onTap: () => _navigateToNumberScreen('exercises', state),
                isTablet: isTablet,
                scale: scale,
                fontScale: fontScale,
                isDisabled: isActive,
              ),
            ],
          ),
        ),
        SizedBox(width: gap),
        // Right Column
        Expanded(
          child: Column(
            children: [
              _buildConfigCard(
                context: context,
                label: l10n.restLabel,
                value: _formatDuration(state.restDuration, l10n),
                colorBg: isRestHighlighted ? const Color(0xFFFFF2D4) : const Color(0xFFFFF8E8),
                colorIconBg: const Color(0xFFFFE8BA),
                colorIcon: const Color(0xFFFEB720),
                customIcon: CustomRefreshIcon(size: 21.0 * scale, color: const Color(0xFFFEB720)),
                onTap: () => _navigateToTimeScreen('rest', state),
                isTablet: isTablet,
                scale: scale,
                fontScale: fontScale,
                isDisabled: isActive && !isRestHighlighted,
              ),
              SizedBox(height: gap),
              _buildConfigCard(
                context: context,
                label: l10n.roundsLabel,
                value: '${state.totalRounds} ${l10n.repsLabel}',
                colorBg: const Color(0xFFFFECEB),
                colorIconBg: const Color(0xFFFBC7C1),
                colorIcon: const Color(0xFFFE413D),
                customIcon: CustomRoundsIcon(size: 21.0 * scale, color: const Color(0xFFFE413D)),
                onTap: () => _navigateToNumberScreen('rounds', state),
                isTablet: isTablet,
                scale: scale,
                fontScale: fontScale,
                isDisabled: isActive,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutControls(bool isTablet, WorkoutState state, double scale, AppLocalizations l10n, double fontScale) {
    final circleSize = 88.0 * scale;
    final stopWidth = 180.0 * scale;
    final stopHeight = 64.0 * scale;
    final playIconSize = (isTablet ? 38.0 : 34.0) * scale;

    switch (state.status) {
      case WorkoutStatus.idle:
      case WorkoutStatus.finished:
        return Center(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              _isWorkoutSaved = false;
              ref.read(workoutControllerProvider.notifier).start();
              _enableWakelock();
            },
            child: Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: const Color(0xFF900EBF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD2D2D2).withValues(alpha: 0.25),
                    offset: const Offset(0, 4),
                    blurRadius: 11.9,
                    spreadRadius: isTablet ? 8 : 6,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  l10n.startRun,
                  style: GoogleFonts.poppins(
                    fontSize: 17.0 * scale * fontScale,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );

      case WorkoutStatus.running:
        return Center(
          child: _WorkoutHoldGradient(
            onAction: _toggleTimer,
            child: Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: const Color(0xFF900EBF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD2D2D2).withValues(alpha: 0.25),
                    offset: const Offset(0, 3),
                    blurRadius: 10,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(child: _buildWorkoutPauseIcon(scale, isTablet)),
            ),
          ),
        );

      case WorkoutStatus.paused:
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 18.0 * scale),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _WorkoutHoldGradient(
                onAction: _toggleTimer,
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB7B7B7).withValues(alpha: 0.25),
                        offset: const Offset(0, 3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(1.5, 0),
                      child: Icon(
                        Icons.play_arrow,
                        color: const Color(0xFF900EBF),
                        size: playIconSize * 1.3,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 11.0 * scale),
              CustomGradientButton(
                text: l10n.endWorkoutTitle,
                onAction: _showExitConfirmation,
                width: stopWidth,
                height: stopHeight,
                textStyle: GoogleFonts.lexendDeca(
                  fontSize: 18.0 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildWorkoutPauseIcon(double scale, bool isTablet) {
    final barWidth = (isTablet ? 9.0 : 8.0) * scale;
    final barHeight = (isTablet ? 22.0 : 19.0) * scale;
    final gap = (isTablet ? 6.0 : 4.0) * scale;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: barWidth,
          height: barHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: gap),
        Container(
          width: barWidth,
          height: barHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalTimeCard(WorkoutState state, double scale, AppLocalizations l10n, double fontScale) {
    final totalSeconds = state.totalExercises * state.totalRounds * (state.workDuration + state.restDuration);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0 * scale),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46.0 * scale,
            height: 46.0 * scale,
            decoration: const BoxDecoration(
              color: Color(0xFFF3E8FF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.access_time_filled_rounded,
                color: const Color(0xFF900EBF),
                size: 24.0 * scale,
              ),
            ),
          ),
          SizedBox(width: 14.0 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.totalWorkoutTime,
                  style: GoogleFonts.lexend(
                    fontSize: 15.0 * scale * fontScale,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF24252C),
                  ),
                ),
                SizedBox(height: 2.0 * scale),
                Text(
                  l10n.totalWithTime(_formatSecondsToWords(totalSeconds, l10n, colonStyle: true)),
                  style: GoogleFonts.lexend(
                    fontSize: 12.0 * scale * fontScale,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF24252C),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.more_time_rounded,
            color: const Color(0xFF900EBF),
            size: 22.0 * scale,
          ),
        ],
      ),
    );
  }

  Widget _buildPreBuiltWorkouts(bool isTablet, WorkoutState state, double scale, AppLocalizations l10n, double fontScale) {
    if (state.status == WorkoutStatus.running || state.status == WorkoutStatus.paused) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0 * scale),
          child: Text(
            l10n.preBuiltWorkoutsTitle,
            style: GoogleFonts.lexendDeca(
              fontSize: 14.0 * scale * fontScale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF24252C),
              letterSpacing: 1.2,
            ),
          ),
        ),
        SizedBox(height: 12.0 * scale),
        SizedBox(
          height: 250.0 * scale,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: preBuiltWorkouts.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final workout = preBuiltWorkouts[index];
              return _buildPreBuiltWorkoutCard(workout, scale, fontScale);
            },
          ),
        ),
        if (_selectedPreBuiltWorkout != null) ...[
          SizedBox(height: 20.0 * scale),
          _buildPreBuiltWorkoutDetail(_selectedPreBuiltWorkout!, isTablet, scale, l10n, fontScale),
        ],
      ],
    );
  }

  Widget _buildPreBuiltCardsRow(bool isTablet, double scale, double fontScale) {
    return SizedBox(
      height: 250.0 * scale,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: preBuiltWorkouts.length,
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          final workout = preBuiltWorkouts[index];
          return _buildPreBuiltWorkoutCard(workout, scale, fontScale);
        },
      ),
    );
  }

  String _formatTotalTime(PreBuiltWorkout w) {
    final total = w.totalExercises * w.totalRounds * (w.workDuration + w.restDuration);
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildPreBuiltWorkoutDetail(
    PreBuiltWorkout workout,
    bool isTablet,
    double scale,
    AppLocalizations l10n,
    double fontScale,
  ) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF910EBF), Color(0xFFFD3B6E)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    final restMinutes = workout.restDuration ~/ 60;
    final restSecs = workout.restDuration % 60;
    final restStr = '${restMinutes.toString().padLeft(2, '0')}:${restSecs.toString().padLeft(2, '0')}';
    final dividerH = 40.0 * scale;
    final hMargin = 12.0 * scale;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(0, -4),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.0 * scale, 20.0 * scale, 16.0 * scale, 20.0 * scale),
            child: Column(
              children: [
                // ── Timer card ──────────────────────────────
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0 * scale,
                    vertical: 16.0 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8FB),
                    borderRadius: BorderRadius.circular(16.0 * scale),
                    border: Border.all(color: const Color(0xFFF5F3F3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.exerciseTimer,
                        style: GoogleFonts.lexend(
                          fontSize: 13.0 * scale * fontScale,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF8B88B5),
                        ),
                      ),
                      SizedBox(height: 6.0 * scale),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${workout.workDuration} ${l10n.secUnit}',
                              style: GoogleFonts.lexend(
                                fontSize: 26.0 * scale * fontScale,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1B2D51),
                              ),
                            ),
                            TextSpan(
                              text: ' ${l10n.workSlash} / ',
                              style: GoogleFonts.lexend(
                                fontSize: 20.0 * scale * fontScale,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF8B88B5),
                              ),
                            ),
                            TextSpan(
                              text: '${workout.restDuration} ${l10n.secUnit}',
                              style: GoogleFonts.lexend(
                                fontSize: 26.0 * scale * fontScale,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1B2D51),
                              ),
                            ),
                            TextSpan(
                              text: ' ${l10n.restWord}',
                              style: GoogleFonts.lexend(
                                fontSize: 20.0 * scale * fontScale,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF8B88B5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.0 * scale),
                // ── Stats row ───────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0 * scale),
                    border: Border.all(color: const Color(0xFFF5F3F3)),
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 3),
                        blurRadius: 20,
                        color: Colors.black.withValues(alpha: 0.04),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hMargin),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _buildDetailStatItem(l10n.exercisesLabel, '${workout.totalExercises}', null, scale, isTablet, fontScale)),
                        Container(width: 1, height: dividerH, color: const Color(0xFFE8ECF4)),
                        Expanded(child: _buildDetailStatItem(l10n.restLabel, restStr, l10n.minsUnit, scale, isTablet, fontScale)),
                        Container(width: 1, height: dividerH, color: const Color(0xFFE8ECF4)),
                        Expanded(child: _buildDetailStatItem(l10n.roundsLabel, '${workout.totalRounds} of 3', 'Reps', scale, isTablet, fontScale)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12.0 * scale),
                // ── Total Time ──────────────────────────────
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.0 * scale),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0 * scale),
                    border: Border.all(color: const Color(0xFFF5F3F3)),
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 3),
                        blurRadius: 20,
                        color: Colors.black.withValues(alpha: 0.04),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.totalTimeColon,
                        style: GoogleFonts.lexend(
                          fontSize: 13.0 * scale * fontScale,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF8B88B5),
                        ),
                      ),
                      SizedBox(height: 4.0 * scale),
                      Text(
                        _formatTotalTime(workout),
                        style: GoogleFonts.lexendDeca(
                          fontSize: 32.0 * scale,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1B2D51),
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 2.0 * scale),
                      Text(
                        '(${l10n.exercisesPlusRest})',
                        style: GoogleFonts.lexend(
                          fontSize: 12.0 * scale * fontScale,
                          color: const Color(0xFF8B88B5),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.0 * scale),
                // ── Controls — same as main workout screen ───
                _buildPreBuiltControls(workout, isTablet, scale, l10n, fontScale),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildDetailStatItem(String label, String value, String? unit, double scale, bool isTablet, double fontScale) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0 * scale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 11.0 * scale * fontScale,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8B88B5),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.0 * scale),
          Text(
            value,
            style: GoogleFonts.lexendDeca(
              fontSize: 22.0 * scale,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B2D51),
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          if (unit != null)
            Text(
              unit,
              style: GoogleFonts.lexendDeca(
                fontSize: 11.0 * scale * fontScale,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8B88B5),
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildPreBuiltControls(PreBuiltWorkout workout, bool isTablet, double scale, AppLocalizations l10n, double fontScale) {
    final state = ref.watch(workoutControllerProvider);
    final circleSize = 88.0 * scale;
    final stopWidth = 180.0 * scale;
    final stopHeight = 64.0 * scale;
    final playIconSize = (isTablet ? 38.0 : 34.0) * scale;

    switch (state.status) {
      case WorkoutStatus.idle:
      case WorkoutStatus.finished:
        return Center(
          child: GestureDetector(
            onTap: () async {
              HapticFeedback.mediumImpact();
              _isWorkoutSaved = false;
              final notifier = ref.read(workoutControllerProvider.notifier);
              await notifier.updateConfig(
                workDuration: workout.workDuration,
                restDuration: workout.restDuration,
                totalExercises: workout.totalExercises,
                totalRounds: workout.totalRounds,
              );
              notifier.start();
              _enableWakelock();
              setState(() => _selectedPreBuiltWorkout = null);
            },
            child: Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: const Color(0xFF900EBF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD2D2D2).withValues(alpha: 0.25),
                    offset: const Offset(0, 4),
                    blurRadius: 11.9,
                    spreadRadius: isTablet ? 8 : 6,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  l10n.startRun,
                  style: GoogleFonts.poppins(
                    fontSize: 17.0 * scale * fontScale,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );

      case WorkoutStatus.running:
        return Center(
          child: _WorkoutHoldGradient(
            onAction: _toggleTimer,
            child: Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: const Color(0xFF900EBF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD2D2D2).withValues(alpha: 0.25),
                    offset: const Offset(0, 3),
                    blurRadius: 10,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(child: _buildWorkoutPauseIcon(scale, isTablet)),
            ),
          ),
        );

      case WorkoutStatus.paused:
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 18.0 * scale),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _WorkoutHoldGradient(
                onAction: _toggleTimer,
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB7B7B7).withValues(alpha: 0.25),
                        offset: const Offset(0, 3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(1.5, 0),
                      child: Icon(
                        Icons.play_arrow,
                        color: const Color(0xFF900EBF),
                        size: playIconSize * 1.3,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 11.0 * scale),
              CustomGradientButton(
                text: l10n.endWorkoutTitle,
                onAction: _showExitConfirmation,
                width: stopWidth,
                height: stopHeight,
                textStyle: GoogleFonts.lexendDeca(
                  fontSize: 18.0 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildPreBuiltWorkoutCard(PreBuiltWorkout workout, double scale, double fontScale) {
    final l10n = AppLocalizations.of(context)!;
    final cardWidth = 160.0 * scale;
    final cardHeight = 250.0 * scale;
    final borderRadius = BorderRadius.circular(20.0 * scale);
    final isSelected = _selectedPreBuiltWorkout?.id == workout.id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() {
          _selectedPreBuiltWorkout = isSelected ? null : workout;
        });
      },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: EdgeInsets.only(right: 14.0 * scale),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                workout.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF1A1A2E),
                  child: const Icon(Icons.fitness_center, color: Colors.white54, size: 40),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 10.0 * scale,
                right: 10.0 * scale,
                bottom: 12.0 * scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      workout.title,
                      style: GoogleFonts.lexend(
                        fontSize: 13.0 * scale * fontScale,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                    ),
                    SizedBox(height: 2.0 * scale),
                    Text(
                      '(${workout.totalDurationMinutes} min)',
                      style: GoogleFonts.lexend(
                        fontSize: 11.0 * scale * fontScale,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                    ),
                    SizedBox(height: 10.0 * scale),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _selectedPreBuiltWorkout = workout);
                      },
                      child: Container(
                        width: double.infinity,
                        height: 34.0 * scale,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0 * scale),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.letsGoFire,
                          style: GoogleFonts.lexendDeca(
                            fontSize: 13.0 * scale * fontScale,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF900EBF),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigCard({
    required BuildContext context,
    required String label,
    required String value,
    required Color colorBg,
    required Color colorIconBg,
    required Color colorIcon,
    required Widget customIcon,
    required VoidCallback onTap,
    required bool isTablet,
    required double scale,
    required double fontScale,
    bool isDisabled = false,
  }) {
    final iconContainerSize = 43.0 * scale;
    final padding = 14.0 * scale;

    return IgnorePointer(
      ignoring: isDisabled,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            // No fixed height — card grows with content so it never overflows.
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorBg,
              borderRadius: BorderRadius.circular(15.0 * scale),
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: iconContainerSize,
                        height: iconContainerSize,
                        decoration: BoxDecoration(
                          color: colorIconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: customIcon),
                      ),
                      Transform.scale(
                        scaleX: Directionality.of(context) == TextDirection.rtl ? -1 : 1,
                        child: CustomArrowIcon(size: 20.0 * scale, color: const Color(0xFF900EBF)),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.0 * scale),
                  Text(
                    label,
                    style: GoogleFonts.lexend(
                      fontSize: 16.0 * scale * fontScale,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.0 * scale),
                  Text(
                    value,
                    style: GoogleFonts.lexend(
                      fontSize: 14.0 * scale * fontScale,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8B88B5),
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToTimeScreen(String type, WorkoutState state) async {
    if (state.status == WorkoutStatus.running || state.status == WorkoutStatus.paused) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTimeScreen(
          title: type == 'work' ? l10n.workLabel : l10n.restLabel,
          initialSeconds: type == 'work' ? state.workDuration : state.restDuration,
        ),
      ),
    );

    if (result != null) {
      if (type == 'work') {
        ref.read(workoutControllerProvider.notifier).updateConfig(workDuration: result);
      } else {
        ref.read(workoutControllerProvider.notifier).updateConfig(restDuration: result);
      }
    }
  }

  void _navigateToNumberScreen(String type, WorkoutState state) async {
    if (state.status == WorkoutStatus.running || state.status == WorkoutStatus.paused) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNumberScreen(
          title: type == 'exercises' ? l10n.exercisesLabel : l10n.roundsLabel,
          initialValue: type == 'exercises' ? state.totalExercises : state.totalRounds,
          iconType: type,
          minValue: 1,
          maxValue: type == 'exercises' ? 20 : 50,
        ),
      ),
    );

    if (result != null) {
      if (type == 'exercises') {
        ref.read(workoutControllerProvider.notifier).updateConfig(totalExercises: result);
      } else {
        ref.read(workoutControllerProvider.notifier).updateConfig(totalRounds: result);
      }
    }
  }
}

class _WorkoutHoldGradient extends StatefulWidget {
  final VoidCallback onAction;
  final Widget child;

  const _WorkoutHoldGradient({required this.onAction, required this.child});

  @override
  State<_WorkoutHoldGradient> createState() => _WorkoutHoldGradientState();
}

class _WorkoutHoldGradientState extends State<_WorkoutHoldGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.vibrate();
        widget.onAction();
        _ctrl.reset();
        if (mounted) setState(() => _holding = false);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    HapticFeedback.lightImpact();
    setState(() => _holding = true);
    _ctrl.forward();
  }

  void _up(TapUpDetails _) {
    if (_ctrl.isAnimating) _ctrl.reverse();
    if (mounted) setState(() => _holding = false);
  }

  void _cancel() {
    if (_ctrl.isAnimating) _ctrl.reverse();
    if (mounted) setState(() => _holding = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      child: AnimatedScale(
        scale: _holding ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (_holding)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF900EBF)
                              .withValues(alpha: 0.20 * _ctrl.value),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              child!,
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: _ctrl.value,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF900EBF)
                        .withValues(alpha: _holding ? 1.0 : 0.0),
                  ),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
