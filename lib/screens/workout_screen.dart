import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../widgets/custom_work_icon.dart';
import '../widgets/custom_refresh_icon.dart';
import '../widgets/custom_exercises_icon.dart';
import '../widgets/custom_rounds_icon.dart';
import '../widgets/custom_bottom_navigation.dart';
import 'add_number_screen.dart';

enum WorkoutPhase { work, rest }

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> with WidgetsBindingObserver {
  int _selectedIndex = 1;

  // Workout configuration
  int workDuration = 345; // 5:45 in seconds
  int restDuration = 45;
  int totalExercises = 3;
  int totalRounds = 12;

  // Current workout state
  int currentExercise = 1;
  int currentRound = 1;

  // Timer state
  Timer? _timer;
  final ValueNotifier<int> _remainingSeconds = ValueNotifier<int>(345);
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
      workDuration = prefs.getInt('workDuration') ?? 345;
      restDuration = prefs.getInt('restDuration') ?? 45;
      totalExercises = prefs.getInt('totalExercises') ?? 3;
      totalRounds = prefs.getInt('totalRounds') ?? 12;
      _remainingSeconds.value = workDuration;
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
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('workoutHistory') ?? '[]';
    final List<dynamic> history = jsonDecode(historyJson);

    final totalTime = (workDuration * totalRounds + restDuration * totalRounds) * totalExercises;
    final workout = {
      'date': DateTime.now().toIso8601String(),
      'exercises': totalExercises,
      'rounds': totalRounds,
      'workDuration': workDuration,
      'restDuration': restDuration,
      'totalTime': totalTime,
    };

    history.insert(0, workout);
    if (history.length > 50) history.removeRange(50, history.length);

    await prefs.setString('workoutHistory', jsonEncode(history));
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
        content: Text('Great job! You completed $totalExercises exercises with $totalRounds rounds each.', style: GoogleFonts.lexend(color: const Color(0xFF8B88B5))),
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
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              image: DecorationImage(image: AssetImage('assets/images/bg-gradient.png'), fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        children: [
                          SizedBox(height: 20.h),
                          _buildTimerSection(),
                          SizedBox(height: 30.h),
                          _buildConfigSection(),
                          SizedBox(height: 20.h),
                          _buildProgressSection(),
                          SizedBox(height: 100.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.only(left: 26.w, right: 26.w, top: 28.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _showExitConfirmation,
            child: SvgPicture.asset('assets/images/back_arrow_icon.svg', width: 28.w, height: 28.w),
          ),
          Text('WORKOUT', style: GoogleFonts.lexend(fontSize: 18.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1B2D51))),
          GestureDetector(
            onTap: _resetWorkout,
            child: Container(
              width: 28.w, height: 28.w,
              decoration: BoxDecoration(color: const Color(0xFF221F48), shape: BoxShape.circle),
              child: Icon(Icons.refresh, color: Colors.white, size: 18.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    return Column(
      children: [
        ListenableBuilder(
          listenable: _currentPhase,
          builder: (context, child) {
            final isWork = _currentPhase.value == WorkoutPhase.work;
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isWork ? const Color(0xFF34CDFD).withValues(alpha: 0.1) : const Color(0xFFFEB720).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(isWork ? 'WORK' : 'REST', style: GoogleFonts.lexend(fontSize: 14.sp, fontWeight: FontWeight.w600, color: isWork ? const Color(0xFF34CDFD) : const Color(0xFFFEB720))),
            );
          },
        ),
        SizedBox(height: 20.h),
        ListenableBuilder(
          listenable: _remainingSeconds,
          builder: (context, child) => Text(_formatTime(_remainingSeconds.value), style: GoogleFonts.lexendDeca(fontSize: 72.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1B2D51))),
        ),
        SizedBox(height: 20.h),
        _buildPlayPauseButton(),
      ],
    );
  }

  Widget _buildPlayPauseButton() {
    return ListenableBuilder(
      listenable: _isRunning,
      builder: (context, child) {
        return GestureDetector(
          onTap: _toggleTimer,
          child: Container(
            width: 96.w, height: 96.w,
            decoration: BoxDecoration(
              color: const Color(0xFF900EBF),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: [BoxShadow(offset: const Offset(0, 4), blurRadius: 11.9, spreadRadius: 6, color: const Color(0xFFD2D2D2).withValues(alpha: 0.25))],
            ),
            child: Center(child: Icon(_isRunning.value ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 40.sp)),
          ),
        );
      },
    );
  }

  Widget _buildConfigSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(offset: const Offset(0, 4), blurRadius: 32, color: Colors.black.withValues(alpha: 0.04))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: ListenableBuilder(
                listenable: _currentPhase,
                builder: (context, child) => _buildConfigItem(
                  label: 'WORK', value: _formatTime(workDuration),
                  customIcon: CustomWorkIcon(size: 21.sp, color: _currentPhase.value == WorkoutPhase.work ? Colors.white : const Color(0xFF34CDFD)),
                  iconBgColor: _currentPhase.value == WorkoutPhase.work ? const Color(0xFF34CDFD) : const Color(0xFF34CDFD).withValues(alpha: 0.1),
                  onTap: () => _navigateToTimeScreen('work'),
                ),
              )),
              SizedBox(width: 20.w),
              Expanded(child: ListenableBuilder(
                listenable: _currentPhase,
                builder: (context, child) => _buildConfigItem(
                  label: 'REST', value: _formatTime(restDuration),
                  customIcon: CustomRefreshIcon(size: 21.sp, color: _currentPhase.value == WorkoutPhase.rest ? Colors.white : const Color(0xFFFEB720)),
                  iconBgColor: _currentPhase.value == WorkoutPhase.rest ? const Color(0xFFFEB720) : const Color(0xFFFEB720).withValues(alpha: 0.1),
                  onTap: () => _navigateToTimeScreen('rest'),
                ),
              )),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: _buildConfigItem(
                label: 'EXERCISES', value: totalExercises.toString(),
                customIcon: CustomExercisesIcon(size: 21.sp, color: const Color(0xFF5D37E5)),
                iconBgColor: const Color(0xFF5D37E5).withValues(alpha: 0.1),
                onTap: () => _navigateToNumberScreen('exercises'),
              )),
              SizedBox(width: 20.w),
              Expanded(child: _buildConfigItem(
                label: 'ROUNDS', value: totalRounds.toString(),
                customIcon: CustomRoundsIcon(size: 21.sp, color: const Color(0xFFF83A71)),
                iconBgColor: const Color(0xFFF83A71).withValues(alpha: 0.1),
                onTap: () => _navigateToNumberScreen('rounds'),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem({required String label, required String value, required Widget customIcon, required Color iconBgColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(12.r)),
        child: Row(
          children: [
            Container(
              width: 40.w, height: 40.w,
              decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10.r)),
              child: Center(child: customIcon),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.lexend(fontSize: 10.sp, fontWeight: FontWeight.w400, color: const Color(0xFF8B88B5))),
                  Text(value, style: GoogleFonts.lexendDeca(fontSize: 18.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1B2D51))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(offset: const Offset(0, 4), blurRadius: 32, color: Colors.black.withValues(alpha: 0.04))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROGRESS', style: GoogleFonts.lexend(fontSize: 12.sp, fontWeight: FontWeight.w500, color: const Color(0xFF8B88B5))),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: _buildProgressItem(label: 'EXERCISE', current: currentExercise, total: totalExercises, color: const Color(0xFF5D37E5))),
              SizedBox(width: 20.w),
              Expanded(child: _buildProgressItem(label: 'ROUND', current: currentRound, total: totalRounds, color: const Color(0xFFF83A71))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem({required String label, required int current, required int total, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.lexend(fontSize: 10.sp, fontWeight: FontWeight.w400, color: const Color(0xFF8B88B5))),
        SizedBox(height: 8.h),
        Row(
          children: [
            Text('$current', style: GoogleFonts.lexendDeca(fontSize: 24.sp, fontWeight: FontWeight.w600, color: color)),
            Text(' / $total', style: GoogleFonts.lexendDeca(fontSize: 16.sp, fontWeight: FontWeight.w400, color: const Color(0xFF8B88B5))),
          ],
        ),
        SizedBox(height: 8.h),
        LinearProgressIndicator(value: current / total, backgroundColor: color.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation<Color>(color), borderRadius: BorderRadius.circular(4.r)),
      ],
    );
  }

  void _navigateToTimeScreen(String type) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TimePickerSheet(
        title: type == 'work' ? 'Work Duration' : 'Rest Duration',
        initialSeconds: type == 'work' ? workDuration : restDuration,
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

class _TimePickerSheet extends StatefulWidget {
  final String title;
  final int initialSeconds;

  const _TimePickerSheet({required this.title, required this.initialSeconds});

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late int minutes;
  late int seconds;

  @override
  void initState() {
    super.initState();
    minutes = widget.initialSeconds ~/ 60;
    seconds = widget.initialSeconds % 60;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2.r))),
          SizedBox(height: 20.h),
          Text(widget.title, style: GoogleFonts.lexend(fontSize: 18.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1B2D51))),
          SizedBox(height: 30.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeColumn(value: minutes, label: 'MIN', onIncrement: () => setState(() { if (minutes < 59) minutes++; }), onDecrement: () => setState(() { if (minutes > 0) minutes--; })),
              Padding(padding: EdgeInsets.symmetric(horizontal: 20.w), child: Text(':', style: GoogleFonts.lexendDeca(fontSize: 48.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1B2D51)))),
              _buildTimeColumn(value: seconds, label: 'SEC', onIncrement: () => setState(() { if (seconds < 59) seconds++; else { seconds = 0; if (minutes < 59) minutes++; } }), onDecrement: () => setState(() { if (seconds > 0) seconds--; else if (minutes > 0) { seconds = 59; minutes--; } })),
            ],
          ),
          SizedBox(height: 30.h),
          GestureDetector(
            onTap: () => Navigator.pop(context, minutes * 60 + seconds),
            child: Container(
              width: double.infinity, height: 56.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6E3AFF), Color(0xFFDB1DCD)]),
                borderRadius: BorderRadius.circular(28.r),
              ),
              child: Center(child: Text('SAVE', style: GoogleFonts.lexend(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white))),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10.h),
        ],
      ),
    );
  }

  Widget _buildTimeColumn({required int value, required String label, required VoidCallback onIncrement, required VoidCallback onDecrement}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onIncrement,
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF6E3AFF), Color(0xFFDB1DCD)]).createShader(bounds),
            child: Text('+', style: GoogleFonts.lexendDeca(fontSize: 48.sp, fontWeight: FontWeight.w300, color: Colors.white)),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          width: 80.w, height: 80.w,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r), boxShadow: [BoxShadow(offset: const Offset(0, 4), blurRadius: 20, color: Colors.black.withValues(alpha: 0.08))]),
          child: Center(child: Text(value.toString().padLeft(2, '0'), style: GoogleFonts.lexendDeca(fontSize: 36.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1B2D51)))),
        ),
        SizedBox(height: 10.h),
        GestureDetector(
          onTap: onDecrement,
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF6E3AFF), Color(0xFFDB1DCD)]).createShader(bounds),
            child: Text('-', style: GoogleFonts.lexendDeca(fontSize: 48.sp, fontWeight: FontWeight.w300, color: Colors.white)),
          ),
        ),
        SizedBox(height: 8.h),
        Text(label, style: GoogleFonts.lexend(fontSize: 12.sp, fontWeight: FontWeight.w400, color: const Color(0xFF8B88B5))),
      ],
    );
  }
}
