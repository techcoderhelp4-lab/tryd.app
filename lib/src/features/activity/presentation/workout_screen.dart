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
import '../../../../widgets/gradient_button.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../data/activity_repository.dart';
import '../domain/workout.dart';
import '../domain/workout_controller.dart';
import 'add_number_screen.dart';
import 'add_time_screen.dart';
import 'history_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import 'hold_progress_button.dart';
import 'running_screen.dart';
import '../../club/presentation/club_screen.dart';
import '../../challenges/data/challenge_repository.dart';
import '../../notifications/data/real_time_notification_service.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> with WidgetsBindingObserver {
  final int _selectedIndex = 3;
  bool _isWorkoutSaved = false;
  bool _showHoldHint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('End Workout?', style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to end this workout?', style: GoogleFonts.lexend()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.lexend(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(workoutControllerProvider.notifier).reset();
              _disableWakelock();
            },
            child: Text('End', style: GoogleFonts.lexend(color: Colors.red)),
          ),
        ],
      ),
    );
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
                    'Workout Complete!',
                    style: GoogleFonts.lexend(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Great job! You completed all exercises and rounds.',
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
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
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
                  'Done',
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
                    'End Workout?',
                    style: GoogleFonts.lexend(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Are you sure you want to end this workout?',
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
                          'Cancel',
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
                          'End',
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

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')} mins';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutControllerProvider);
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;
    final isTablet = screenWidth > 600;

    // ── Responsive Scale ──────────────────────────────────
    // Change these 4 values to control ALL component sizes:
    //   small  → phones with height < 680px
    //   medium → phones with height 680–850px
    //   large  → phones with height > 850px
    //   tablet → devices with width > 600px
    const double smallScale  = 0.78;
    const double mediumScale = 0.88;
    const double largeScale  = 0.95;
    const double tabletScale = 1.30;

    final double scale = isTablet
        ? tabletScale
        : screenHeight < 680
            ? smallScale
            : screenHeight < 850
                ? mediumScale
                : largeScale;

    // Reliable listener for finished state
    ref.listen(workoutControllerProvider, (prev, next) {
      if (prev?.status != WorkoutStatus.finished && next.status == WorkoutStatus.finished) {
        if (!_isWorkoutSaved) {
          _saveWorkoutCompletion(next);
        }
        
        // Show banner notification
        ref.read(realTimeNotificationServiceProvider).showInAppBanner(
          'Workout Complete!',
          'Great job! You completed all exercises and rounds.',
          showAlert: true,
          showSnackBar: false,
        );

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

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 3) return;
          
          if (state.status == WorkoutStatus.running || state.status == WorkoutStatus.paused) {
            _showExitConfirmation();
            return;
          }

          Widget? page;
          switch (index) {
            case 0: page = const HomeScreen(); break;
            case 1: page = const RunningScreen(); break;
            case 2: page = const RewardsScreen(); break;
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
      body: Stack(
        children: [
          Positioned.fill(
             child: Image.asset(
               'assets/images/bg-gradient.png',
               fit: BoxFit.cover,
             ),
          ),
          
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context, isTablet, state, scale),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: (isTablet ? 20.0 : 15.0) * scale),
                      child: Column(
                        children: [
                          SizedBox(height: (isTablet ? 20.0 : 20.0) * scale),
                          _buildTimerCard(context, timerCardGradient, isTablet, state, scale),
                          SizedBox(height: (isTablet ? 30.0 : 25.0) * scale),
                          _buildConfigGrid(isTablet, state, scale),

                          if (state.status == WorkoutStatus.running || state.status == WorkoutStatus.paused) ...[
                             SizedBox(height: 20.0 * scale),
                             Padding(
                               padding: EdgeInsets.symmetric(horizontal: 20.0 * scale),
                               child: SizedBox(
                                 width: double.infinity,
                                 height: 54.0 * scale,
                                 child: ElevatedButton(
                                   onPressed: () {
                                     HapticFeedback.mediumImpact();
                                     _showExitConfirmation();
                                   },
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: const Color(0xFFF83A71),
                                     foregroundColor: Colors.white,
                                     elevation: 8,
                                     shadowColor: const Color(0xFFF83A71).withOpacity(0.5),
                                     shape: RoundedRectangleBorder(
                                       borderRadius: BorderRadius.circular(16.0 * scale),
                                     ),
                                   ),
                                   child: Text(
                                     'Reset Workout',
                                     style: GoogleFonts.lexend(
                                       fontSize: 16.0 * scale,
                                       fontWeight: FontWeight.w600,
                                     ),
                                   ),
                                 ),
                               ),
                            ),
                          ],
                          
                          SizedBox(height: (isTablet ? 120.0 : 140.0) * scale),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),


        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet, WorkoutState state, double scale) {
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
                 Navigator.pushReplacement(
                   context,
                   MaterialPageRoute(builder: (context) => const HomeScreen()),
                 );
               }
            },
            child: SvgPicture.asset(
              'assets/images/back_arrow_icon.svg', 
              width: iconSize, 
              height: iconSize
            ),
          ),
          Text(
            'Workouts',
            style: GoogleFonts.lexendDeca(
              fontSize: 19.0 * scale,
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

  Widget _buildTimerCard(BuildContext context, Gradient gradient, bool isTablet, WorkoutState state, double scale) {
    final cardHeight = (isTablet ? 160.0 : 148.0) * scale;
    final buttonSize = (isTablet ? 80.0 : 72.0) * scale;
    final hPadding = (isTablet ? 24.0 : 20.0) * scale;

    return SizedBox(
      height: cardHeight + (buttonSize / 2),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
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
              children: [
                Text(
                  'Exercise ${state.currentExercise} of ${state.totalExercises}',
                  style: GoogleFonts.lexend(
                    fontSize: 14.0 * scale,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 5.0 * scale),
                Text(
                  _formatTime(state.remainingSeconds),
                  style: GoogleFonts.lexend(
                    fontSize: 40.0 * scale,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 5.0 * scale),
                Text(
                  'Round ${state.currentRound} of ${state.totalRounds}',
                  style: GoogleFonts.poppins(
                    fontSize: 13.0 * scale,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 20.0 * scale),
              ],
            ),
          ),
          Positioned(
            top: cardHeight - (buttonSize / 2),
            left: 0,
            right: 0,
            child: Column(
              children: [
                HoldProgressButton(
                  scale: scale,
                  size: buttonSize,
                  isRunning: state.status == WorkoutStatus.running,
                  requireHold: state.status == WorkoutStatus.running || state.status == WorkoutStatus.paused,
                  onAction: () {
                    HapticFeedback.mediumImpact();
                    _toggleTimer();
                  },
                  onTap: () {
                    HapticFeedback.selectionClick();
                    // Trigger the hint text to show up via the global notifier or local state
                    // For now, let the button handle its own hint or pass a callback
                    // We'll update state to show hint
                    setState(() {
                      _showHoldHint = true;
                    });
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) {
                        setState(() {
                          _showHoldHint = false;
                        });
                      }
                    });
                  },
                ),
                SizedBox(height: 8.0 * scale),
                AnimatedOpacity(
                  opacity: _showHoldHint ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    state.status == WorkoutStatus.running 
                        ? 'Hold to Pause' 
                        : 'Hold to Resume',
                    style: GoogleFonts.lexend(
                      fontSize: 12.0 * scale,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFF83A71),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipControls(bool isTablet, WorkoutState state, double scale) {
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
                  'Skip Rest',
                  style: GoogleFonts.lexend(
                    fontSize: 12.0 * scale,
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

  Widget _buildWorkoutControls(BuildContext context, WorkoutState state, double buttonSize, double scale) {
    if (state.status == WorkoutStatus.idle) {
      return Center(
        child: GestureDetector(
          onTap: _toggleTimer,
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  offset: const Offset(0, 4),
                  blurRadius: 25,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.play_arrow_rounded,
                size: 40.0 * scale,
                color: const Color(0xFFF83A71),
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: GestureDetector(
        onTap: _toggleTimer,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                offset: const Offset(0, 4),
                blurRadius: 25,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              state.status == WorkoutStatus.running
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: 40.0 * scale,
              color: const Color(0xFFF83A71),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigGrid(bool isTablet, WorkoutState state, double scale) {
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
                label: 'Work',
                value: _formatDuration(state.workDuration),
                colorBg: isWorkHighlighted ? const Color(0xFFDCF7FE) : const Color(0xFFEBF9FC),
                colorIconBg: const Color(0xFFD0F5FD),
                colorIcon: const Color(0xFF34CDFD),
                customIcon: CustomWorkIcon(size: 21.0 * scale, color: const Color(0xFF34CDFD)),
                height: 152.0 * scale,
                onTap: () => _navigateToTimeScreen('work', state),
                isTablet: isTablet,
                scale: scale,
                isDisabled: isActive && !isWorkHighlighted,
              ),
              SizedBox(height: gap),
              _buildConfigCard(
                context: context,
                label: 'Exercises',
                value: '${state.totalExercises}',
                colorBg: const Color(0xFFEFEAFC),
                colorIconBg: const Color(0xFFCDC0F4),
                colorIcon: const Color(0xFF5D37E5),
                customIcon: CustomExercisesIcon(size: 21.0 * scale, color: const Color(0xFF5D37E5)),
                height: 130.0 * scale,
                onTap: () => _navigateToNumberScreen('exercises', state),
                isTablet: isTablet,
                scale: scale,
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
                label: 'Rest',
                value: _formatDuration(state.restDuration),
                colorBg: isRestHighlighted ? const Color(0xFFFFF2D4) : const Color(0xFFFFF8E8),
                colorIconBg: const Color(0xFFFFE8BA),
                colorIcon: const Color(0xFFFEB720),
                customIcon: CustomRefreshIcon(size: 21.0 * scale, color: const Color(0xFFFEB720)),
                height: 130.0 * scale,
                onTap: () => _navigateToTimeScreen('rest', state),
                isTablet: isTablet,
                scale: scale,
                isDisabled: isActive && !isRestHighlighted,
              ),
              SizedBox(height: gap),
              _buildConfigCard(
                context: context,
                label: 'Rounds',
                value: '${state.totalRounds} Reps',
                colorBg: const Color(0xFFFFECEB),
                colorIconBg: const Color(0xFFFBC7C1),
                colorIcon: const Color(0xFFFE413D),
                customIcon: CustomRoundsIcon(size: 21.0 * scale, color: const Color(0xFFFE413D)),
                height: 152.0 * scale,
                onTap: () => _navigateToNumberScreen('rounds', state),
                isTablet: isTablet,
                scale: scale,
                isDisabled: isActive,
              ),
            ],
          ),
        ),
      ],
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
    required double height,
    required VoidCallback onTap,
    required bool isTablet,
    required double scale,
    bool isDisabled = false,
  }) {
    final iconContainerSize = 43.0 * scale;
    final innerPaddingHorizontal = 18.0 * scale;
    final iconTopPadding = 18.0 * scale;
    final innerPaddingBottom = 15.0 * scale;

    return IgnorePointer(
      ignoring: isDisabled,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorBg,
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
                      color: colorIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: customIcon),
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style: GoogleFonts.lexend(
                      fontSize: 16.0 * scale,
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
                      fontSize: 14.0 * scale,
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

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTimeScreen(
          title: type == 'work' ? 'Work Duration' : 'Rest Duration',
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

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNumberScreen(
          title: type == 'exercises' ? 'Exercises' : 'Rounds',
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
