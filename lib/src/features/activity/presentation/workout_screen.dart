import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../../../../widgets/custom_work_icon.dart';
import '../../../../widgets/custom_refresh_icon.dart';
import '../../../../widgets/custom_exercises_icon.dart';
import '../../../../widgets/custom_rounds_icon.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../data/activity_repository.dart';
import '../domain/workout.dart';
import 'add_number_screen.dart';
import 'add_time_screen.dart';
import 'history_screen.dart';

enum WorkoutPhase { work, rest }

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> with WidgetsBindingObserver {
  int _selectedIndex = 1;

  // Workout configuration
  int workDuration = 45; // Default 0:45
  int restDuration = 5;  // Default 0:05
  int totalExercises = 3;
  int totalRounds = 12;

  // Current workout state
  int currentExercise = 1;
  int currentRound = 1;

  // Timer state
  Timer? _timer;
  final ValueNotifier<int> _remainingSeconds = ValueNotifier<int>(45);
  final ValueNotifier<WorkoutPhase> _currentPhase = ValueNotifier<WorkoutPhase>(WorkoutPhase.work);
  final ValueNotifier<bool> _isRunning = ValueNotifier<bool>(false);

  // Background timer tracking
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadWorkoutConfig();
    _enableWakelock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _remainingSeconds.dispose();
    _currentPhase.dispose();
    _isRunning.dispose();
    _disableWakelock();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_isRunning.value) {
        _pausedAt = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null && _isRunning.value) {
        final elapsed = DateTime.now().difference(_pausedAt!).inSeconds;
        _handleBackgroundTimeElapsed(elapsed);
        _pausedAt = null;
      }
    }
  }

  void _handleBackgroundTimeElapsed(int elapsedSeconds) {
    int remaining = _remainingSeconds.value;
    int elapsed = elapsedSeconds;

    while (elapsed > 0 && (currentRound <= totalRounds || currentExercise <= totalExercises)) {
      if (elapsed >= remaining) {
        elapsed -= remaining;
        _handlePhaseCompleteQuiet();
        remaining = _remainingSeconds.value;
      } else {
        _remainingSeconds.value = remaining - elapsed;
        elapsed = 0;
      }
    }
  }

  void _handlePhaseCompleteQuiet() {
    if (_currentPhase.value == WorkoutPhase.work) {
      _currentPhase.value = WorkoutPhase.rest;
      _remainingSeconds.value = restDuration;
    } else {
      if (currentRound < totalRounds) {
        setState(() => currentRound++);
        _currentPhase.value = WorkoutPhase.work;
        _remainingSeconds.value = workDuration;
      } else if (currentExercise < totalExercises) {
        setState(() {
          currentExercise++;
          currentRound = 1;
        });
        _currentPhase.value = WorkoutPhase.work;
        _remainingSeconds.value = workDuration;
      } else {
        _isRunning.value = false;
        _timer?.cancel();
        _saveWorkoutCompletion();
      }
    }
  }

  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {}
  }

  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {}
  }

  Future<void> _loadWorkoutConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      workDuration = prefs.getInt('workDuration') ?? 45;
      restDuration = prefs.getInt('restDuration') ?? 5;
      totalExercises = prefs.getInt('totalExercises') ?? 3;
      totalRounds = prefs.getInt('totalRounds') ?? 12;
      
      // Initialize remaining seconds if not running
      if (!_isRunning.value) {
        _remainingSeconds.value = workDuration;
      }
    });
  }

  Future<void> _saveWorkoutConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('workDuration', workDuration);
    await prefs.setInt('restDuration', restDuration);
    await prefs.setInt('totalExercises', totalExercises);
    await prefs.setInt('totalRounds', totalRounds);
  }

  Future<void> _saveWorkoutCompletion() async {
    final totalTime = (workDuration * totalRounds + restDuration * totalRounds) * totalExercises;
    
    final workout = Workout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'hiit', // High Intensity Interval Training
      duration: totalTime,
      calories: totalTime * 0.15, // Estimate
      date: DateTime.now(),
      exercises: totalExercises,
      rounds: totalRounds,
      workDuration: workDuration,
      restDuration: restDuration,
    );

    await ref.read(workoutHistoryProvider.notifier).addWorkout(workout);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds.value > 0) {
        _remainingSeconds.value--;
        if (_remainingSeconds.value <= 3 && _remainingSeconds.value > 0) {
          _playCountdownBeep();
        }
      } else {
        _handlePhaseComplete();
      }
    });
  }

  void _playCountdownBeep() {
    try {
      FlutterRingtonePlayer().play(
        android: AndroidSounds.notification,
        ios: IosSounds.receivedMessage,
        looping: false,
        volume: 0.5,
      );
    } catch (e) {}
  }

  void _handlePhaseComplete() async {
    if (_currentPhase.value == WorkoutPhase.work) {
      try {
        FlutterRingtonePlayer().play(
          android: AndroidSounds.notification,
          ios: IosSounds.glass,
          looping: false,
          volume: 0.7,
        );
      } catch (e) {}

      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate(duration: 300, amplitude: 128);
        }
      } catch (e) {}

      _currentPhase.value = WorkoutPhase.rest;
      _remainingSeconds.value = restDuration;
    } else {
      try {
        FlutterRingtonePlayer().play(
          android: AndroidSounds.alarm,
          ios: IosSounds.alarm,
          looping: false,
          volume: 1.0,
        );
      } catch (e) {}

      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate(pattern: [0, 200, 100, 200], intensities: [0, 255, 0, 255]);
        }
      } catch (e) {}

      if (currentRound < totalRounds) {
        setState(() => currentRound++);
        _currentPhase.value = WorkoutPhase.work;
        _remainingSeconds.value = workDuration;
      } else if (currentExercise < totalExercises) {
        setState(() {
          currentExercise++;
          currentRound = 1;
        });
        _currentPhase.value = WorkoutPhase.work;
        _remainingSeconds.value = workDuration;
      } else {
        _isRunning.value = false;
        _timer?.cancel();
        _saveWorkoutCompletion();

        try {
          FlutterRingtonePlayer().play(
            android: AndroidSounds.ringtone,
            ios: IosSounds.triTone,
            looping: false,
            volume: 1.0,
          );
        } catch (e) {}

        if (mounted) _showCompletionDialog();
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Workout Complete!', style: GoogleFonts.lexend(fontWeight: FontWeight.w600, color: const Color(0xFF1B2D51))),
        content: Text('Great job! You completed all exercises and rounds.', style: GoogleFonts.lexend(color: const Color(0xFF8B88B5))),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _resetWorkout(); }, child: Text('Start Again', style: GoogleFonts.lexend(color: const Color(0xFF900EBF)))),
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: Text('Exit', style: GoogleFonts.lexend(color: const Color(0xFF8B88B5)))),
        ],
      ),
    );
  }

  void _resetWorkout() {
    setState(() {
      currentExercise = 1;
      currentRound = 1;
    });
    _currentPhase.value = WorkoutPhase.work;
    _remainingSeconds.value = workDuration;
    _isRunning.value = false;
  }

  void _toggleTimer() {
    if (_isRunning.value) {
      _timer?.cancel();
      _isRunning.value = false;
    } else {
      _isRunning.value = true;
      _startTimer();
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit Workout?', style: GoogleFonts.lexend(fontWeight: FontWeight.w600, color: const Color(0xFF1B2D51))),
        content: Text('Are you sure you want to exit? Your progress will be lost.', style: GoogleFonts.lexend(color: const Color(0xFF8B88B5))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.lexend(color: const Color(0xFF8B88B5)))),
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: Text('Exit', style: GoogleFonts.lexend(color: const Color(0xFFF83A71)))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Colors from design
    final timerCardGradient = const LinearGradient(
      colors: [Color(0xFF910EBF), Color(0xFFFD3B6E)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background
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
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.w),
                      child: Column(
                        children: [
                          SizedBox(height: 30.h),
                          // Timer Card with floating button
                          _buildTimerCard(timerCardGradient),
                          SizedBox(height: 38.h),
                          // Grid of Config Cards
                          _buildConfigGrid(),
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
            left: 0, right: 0, bottom: 0,
            child: CustomBottomNavigation(
              currentIndex: _selectedIndex,
              onTap: (index) {
                if (index == 0) {
                  _showExitConfirmation();
                } else {
                  setState(() => _selectedIndex = index);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(15.w, 28.h, 15.w, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _showExitConfirmation,
            child: SvgPicture.asset('assets/images/back_arrow_icon.svg', width: 28.w, height: 28.w),
          ),
          Text(
            'Workouts',
            style: GoogleFonts.lexendDeca(
              fontSize: 19.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF24252C),
            ),
          ),
          // History Icon (using Iconly like styling or material fallback)
          GestureDetector(
             onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => const HistoryScreen()),
               );
             },
             child: Icon(Icons.history, size: 28.sp, color: const Color(0xFF24252C)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard(Gradient gradient) {
    return SizedBox(
      height: 148.h + 36.w, // Card height + half button height for "half-in, half-out"
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Gradient Card
          Container(
            width: double.infinity,
            height: 148.h,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(17.r),
              boxShadow: [
                 BoxShadow(
                   color: Colors.black.withValues(alpha: 0.04),
                   offset: const Offset(0, 4),
                   blurRadius: 32,
                 ),
              ],
            ),
            padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 0.h, bottom: 20.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Exercise $currentExercise of $totalExercises',
                  style: GoogleFonts.lexend(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 5.h),
                ListenableBuilder(
                  listenable: _remainingSeconds,
                  builder: (context, _) {
                    return Text(
                      _formatTime(_remainingSeconds.value),
                      style: GoogleFonts.lexend(
                        fontSize: 40.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    );
                  }
                ),
                SizedBox(height: 5.h),
                Text(
                  'Round $currentRound of $totalRounds',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          // Floating Play/Pause Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: ListenableBuilder(
                listenable: _isRunning,
                builder: (context, _) {
                  return GestureDetector(
                    onTap: _toggleTimer,
                    child: Container(
                      width: 72.w,
                      height: 72.w,
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
                        // Triangle icon using Icon
                        child: Icon(
                          _isRunning.value ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 40.sp,
                          color: const Color(0xFFF83A71),
                        ),
                      ),
                    ),
                  );
                }
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigGrid() {
    return SizedBox(
      height: 310.h, // Sufficient height for the grid
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 10.w) / 2;
          
          return Stack(
            children: [
              // Work - Top Left (Tall)
              Positioned(
                left: 0,
                top: 0,
                width: cardWidth,
                child: _buildConfigCard(
                  label: 'Work',
                  value: '${_formatTime(workDuration)} mins',
                  colorBg: const Color(0xFFEBF9FC),
                  colorIconBg: const Color(0xFFD0F5FD),
                  colorIcon: const Color(0xFF34CDFD),
                  customIcon: CustomWorkIcon(size: 20.sp, color: const Color(0xFF34CDFD)),
                  height: 152.h,
                  onTap: () => _navigateToTimeScreen('work'),
                ),
              ),
              // Rest - Top Right (Short)
              Positioned(
                right: 0,
                top: 0,
                width: cardWidth,
                child: _buildConfigCard(
                  label: 'Rest',
                  value: '${_formatTime(restDuration)} mins',
                  colorBg: const Color(0xFFFFF8E8),
                  colorIconBg: const Color(0xFFFFE8BA),
                  colorIcon: const Color(0xFFFEB720),
                  customIcon: CustomRefreshIcon(size: 20.sp, color: const Color(0xFFFEB720)),
                  height: 130.h,
                  onTap: () => _navigateToTimeScreen('rest'),
                ),
              ),
              // Exercises - Bottom Left (Short)
              Positioned(
                left: 0,
                top: 164.h, // 152 + 12 gap
                width: cardWidth,
                child: _buildConfigCard(
                  label: 'Exercises',
                  value: '$totalExercises',
                  colorBg: const Color(0xFFEFEAFC),
                  colorIconBg: const Color(0xFFCDC0F4),
                  colorIcon: const Color(0xFF5D37E5),
                  customIcon: CustomExercisesIcon(size: 20.sp, color: const Color(0xFF5D37E5)),
                  height: 130.h,
                  onTap: () => _navigateToNumberScreen('exercises'),
                ),
              ),
              // Rounds - Bottom Right (Tall)
              Positioned(
                right: 0,
                top: 142.h, // 130 + 12 gap
                width: cardWidth,
                child: _buildConfigCard(
                  label: 'Rounds',
                  value: '$totalRounds Reps',
                  colorBg: const Color(0xFFFFECEB),
                  colorIconBg: const Color(0xFFFBC7C1),
                  colorIcon: const Color(0xFFF83A71),
                  customIcon: CustomRoundsIcon(size: 20.sp, color: const Color(0xFFF83A71)),
                  height: 152.h,
                  onTap: () => _navigateToNumberScreen('rounds'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConfigCard({
    required String label,
    required String value,
    required Color colorBg,
    required Color colorIconBg,
    required Color colorIcon,
    required Widget customIcon,
    required double height,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: colorBg,
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 32,
              color: Colors.black.withValues(alpha: 0.04),
            ),
          ],
        ),
        padding: EdgeInsets.only(left: 20.w, top: 20.h, right: 15.w, bottom: 15.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 43.w,
              height: 43.w,
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
                fontSize: 19.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8B88B5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTimeScreen(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTimeScreen(
          title: type == 'work' ? 'Work Duration' : 'Rest Duration',
          initialSeconds: type == 'work' ? workDuration : restDuration,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (type == 'work') {
          workDuration = result;
          if (_currentPhase.value == WorkoutPhase.work && !_isRunning.value) {
            _remainingSeconds.value = workDuration;
          }
        } else {
          restDuration = result;
          if (_currentPhase.value == WorkoutPhase.rest && !_isRunning.value) {
            _remainingSeconds.value = restDuration;
          }
        }
      });
      _saveWorkoutConfig();
    }
  }

  void _navigateToNumberScreen(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNumberScreen(
          title: type == 'exercises' ? 'Exercises' : 'Rounds',
          initialValue: type == 'exercises' ? totalExercises : totalRounds,
          iconType: type,
          minValue: 1,
          maxValue: type == 'exercises' ? 20 : 50,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (type == 'exercises') {
          totalExercises = result;
        } else {
          totalRounds = result;
        }
      });
      _saveWorkoutConfig();
    }
  }
}
