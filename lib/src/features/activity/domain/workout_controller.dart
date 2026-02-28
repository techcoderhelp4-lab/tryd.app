import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

// ===== CONSTANTS =====
class WorkoutConstants {
  static const int defaultWorkDuration = 60;
  static const int defaultRestDuration = 30;
  static const int defaultExercises = 1;
  static const int defaultRounds = 3;
  static const int countdownStart = 3;
  static const Duration timerInterval = Duration(milliseconds: 200);
}

// ===== ENUMS =====
enum WorkoutPhase { work, rest }
enum WorkoutStatus { idle, running, paused, finished }

// ===== WORKOUT STATE =====
@immutable
class WorkoutState {
  final WorkoutStatus status;
  final WorkoutPhase phase;
  final int currentExercise;
  final int currentRound;
  final int remainingSeconds;
  
  // Configuration
  final int workDuration;
  final int restDuration;
  final int totalExercises;
  final int totalRounds;
  
  // Tracking
  final int elapsedSeconds;
  final int totalWorkSeconds;
  final int totalRestSeconds;
  
  // Settings
  final bool voiceCuesEnabled;
  final bool hapticsEnabled;

  const WorkoutState({
    this.status = WorkoutStatus.idle,
    this.phase = WorkoutPhase.work,
    this.currentExercise = 1,
    this.currentRound = 1,
    this.remainingSeconds = WorkoutConstants.defaultWorkDuration,
    this.workDuration = WorkoutConstants.defaultWorkDuration,
    this.restDuration = WorkoutConstants.defaultRestDuration,
    this.totalExercises = WorkoutConstants.defaultExercises,
    this.totalRounds = WorkoutConstants.defaultRounds,
    this.elapsedSeconds = 0,
    this.totalWorkSeconds = 0,
    this.totalRestSeconds = 0,
    this.voiceCuesEnabled = true,
    this.hapticsEnabled = true,
  });

  WorkoutState copyWith({
    WorkoutStatus? status,
    WorkoutPhase? phase,
    int? currentExercise,
    int? currentRound,
    int? remainingSeconds,
    int? workDuration,
    int? restDuration,
    int? totalExercises,
    int? totalRounds,
    int? elapsedSeconds,
    int? totalWorkSeconds,
    int? totalRestSeconds,
    bool? voiceCuesEnabled,
    bool? hapticsEnabled,
  }) {
    return WorkoutState(
      status: status ?? this.status,
      phase: phase ?? this.phase,
      currentExercise: currentExercise ?? this.currentExercise,
      currentRound: currentRound ?? this.currentRound,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      workDuration: workDuration ?? this.workDuration,
      restDuration: restDuration ?? this.restDuration,
      totalExercises: totalExercises ?? this.totalExercises,
      totalRounds: totalRounds ?? this.totalRounds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      totalWorkSeconds: totalWorkSeconds ?? this.totalWorkSeconds,
      totalRestSeconds: totalRestSeconds ?? this.totalRestSeconds,
      voiceCuesEnabled: voiceCuesEnabled ?? this.voiceCuesEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  int get currentPhaseDuration => phase == WorkoutPhase.work ? workDuration : restDuration;
  
  bool get isLastRound => currentRound == totalRounds && currentExercise == totalExercises;
  
  double get progress {
    final totalUnits = totalExercises * totalRounds * 2;
    if (totalUnits == 0) return 0.0;
    final completedUnits = ((currentExercise - 1) * totalRounds * 2) +
        ((currentRound - 1) * 2) +
        (phase == WorkoutPhase.rest ? 1 : 0);
    return (completedUnits / totalUnits).clamp(0.0, 1.0);
  }
}

// ===== WORKOUT CONTROLLER =====
class WorkoutController extends StateNotifier<WorkoutState> {
  WorkoutController() : super(const WorkoutState()) {
    _init();
  }

  Timer? _timer;
  DateTime? _phaseStartTime;
  DateTime? _workoutStartTime;
  DateTime? _pausedAt;
  int _lastCountdownSpoken = 0;
  
  // TTS
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  Future<void> _init() async {
    // Initialize TTS
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (e) {
      debugPrint('TTS Init Error: $e');
    }
    
    // Load saved config
    try {
      final prefs = await SharedPreferences.getInstance();
      final work = prefs.getInt('workDuration') ?? WorkoutConstants.defaultWorkDuration;
      final rest = prefs.getInt('restDuration') ?? WorkoutConstants.defaultRestDuration;
      final exercises = prefs.getInt('totalExercises') ?? WorkoutConstants.defaultExercises;
      final rounds = prefs.getInt('totalRounds') ?? WorkoutConstants.defaultRounds;
      final cues = prefs.getBool('hiitVoiceCuesEnabled') ?? true;
      final haptics = prefs.getBool('hiitHapticsEnabled') ?? true;

      state = state.copyWith(
        workDuration: work,
        restDuration: rest,
        totalExercises: exercises,
        totalRounds: rounds,
        voiceCuesEnabled: cues,
        hapticsEnabled: haptics,
        remainingSeconds: work, // Set remaining to loaded work duration
      );
    } catch (e) {
      debugPrint('Config Init Error: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tts.stop();
    super.dispose();
  }

  // ===== PUBLIC METHODS =====

  void start() {
    if (state.status == WorkoutStatus.finished) {
      reset();
    }
    
    _workoutStartTime ??= DateTime.now();
    
    // Only reset phase timer if starting fresh
    if (state.status == WorkoutStatus.idle || state.status == WorkoutStatus.finished) {
      _phaseStartTime = DateTime.now();

      // Speak initial phase only on fresh start
      if (state.phase == WorkoutPhase.work) {
         _speakInitial();
      }
    } else if (state.status == WorkoutStatus.paused) {
      _speak("Let's go");
    }

    state = state.copyWith(status: WorkoutStatus.running);
    _startTimer();
  }

  void pause() {
    _timer?.cancel();
    _pausedAt = DateTime.now();
    state = state.copyWith(status: WorkoutStatus.paused);
    _speak('Paused');
  }

  void toggle() {
    if (state.status == WorkoutStatus.running) {
      pause();
    } else {
      start();
    }
  }

  void reset() {
    _timer?.cancel();
    _phaseStartTime = null;
    _workoutStartTime = null;
    _pausedAt = null;
    _lastCountdownSpoken = 0;
    
    state = state.copyWith(
      status: WorkoutStatus.idle,
      phase: WorkoutPhase.work,
      currentExercise: 1,
      currentRound: 1,
      remainingSeconds: state.workDuration,
      elapsedSeconds: 0,
      totalWorkSeconds: 0,
      totalRestSeconds: 0,
    );
  }

  void skipRest() {
    if (state.phase != WorkoutPhase.rest) return;
    _advancePhase(silent: true);
  }

  void handleAppResumed() {
    if (state.status != WorkoutStatus.running || _pausedAt == null) return;
    
    final now = DateTime.now();
    final backgroundDuration = now.difference(_pausedAt!);
    _pausedAt = null;
    
    // Calculate how many phases passed while backgrounded
    _catchUpPhases(backgroundDuration.inSeconds);
    
    // Resume timer
    _startTimer();
  }

  void handleAppPaused() {
    if (state.status == WorkoutStatus.running) {
      _pausedAt = DateTime.now();
      _timer?.cancel();
    }
  }

  Future<void> updateConfig({
    int? workDuration,
    int? restDuration,
    int? totalExercises,
    int? totalRounds,
  }) async {
    // Apply changes to state first
    state = state.copyWith(
      workDuration: workDuration ?? state.workDuration,
      restDuration: restDuration ?? state.restDuration,
      totalExercises: totalExercises ?? state.totalExercises,
      totalRounds: totalRounds ?? state.totalRounds,
    );
    
    // Recalculate remaining seconds if:
    // 1. Idle: Just reset to full duration (handled below)
    // 2. Active (Running/Paused): Recalculate based on elapsed time if current phase affected
    
    if (state.status == WorkoutStatus.idle) {
      state = state.copyWith(
        remainingSeconds: state.phase == WorkoutPhase.work 
            ? state.workDuration 
            : state.restDuration,
      );
    } else if (state.status == WorkoutStatus.running || state.status == WorkoutStatus.paused) {
       // Only recalculate if the modified setting matches the current phase
       // Work phase + work duration changed OR Rest phase + rest duration changed
       if ((state.phase == WorkoutPhase.work && workDuration != null) ||
           (state.phase == WorkoutPhase.rest && restDuration != null)) {
         
         final currentPhaseDuration = state.currentPhaseDuration;
         int elapsed = 0;
         
         if (_phaseStartTime != null) {
           if (state.status == WorkoutStatus.running) {
             elapsed = DateTime.now().difference(_phaseStartTime!).inSeconds;
           } else if (_pausedAt != null) {
             elapsed = _pausedAt!.difference(_phaseStartTime!).inSeconds;
           }
         }
         
         final newRemaining = (currentPhaseDuration - elapsed).clamp(0, currentPhaseDuration);
         state = state.copyWith(remainingSeconds: newRemaining);
       }
    }
    
    // Persist
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('workDuration', state.workDuration);
    await prefs.setInt('restDuration', state.restDuration);
    await prefs.setInt('totalExercises', state.totalExercises);
    await prefs.setInt('totalRounds', state.totalRounds);
  }

  // ===== PRIVATE METHODS =====

  void _startTimer() {
    _timer?.cancel();
    
    // If resuming from pause, adjust phase start time
    if (_pausedAt != null && _phaseStartTime != null) {
      final pauseDuration = DateTime.now().difference(_pausedAt!);
      _phaseStartTime = _phaseStartTime!.add(pauseDuration);
      _pausedAt = null;
    }
    
    _phaseStartTime ??= DateTime.now();
    
    _timer = Timer.periodic(WorkoutConstants.timerInterval, (_) {
      _tick();
    });
  }

  void _tick() {
    if (state.status != WorkoutStatus.running) return;
    
    final now = DateTime.now();
    final elapsed = now.difference(_phaseStartTime!).inSeconds;
    final remaining = (state.currentPhaseDuration - elapsed).clamp(0, state.currentPhaseDuration);
    
    // Update elapsed workout time
    final totalElapsed = _workoutStartTime != null 
        ? now.difference(_workoutStartTime!).inSeconds 
        : 0;
    
    if (remaining != state.remainingSeconds) {
      state = state.copyWith(
        remainingSeconds: remaining,
        elapsedSeconds: totalElapsed,
        totalWorkSeconds: state.phase == WorkoutPhase.work ? state.totalWorkSeconds + 1 : state.totalWorkSeconds,
        totalRestSeconds: state.phase == WorkoutPhase.rest ? state.totalRestSeconds + 1 : state.totalRestSeconds,
      );
      
      // Countdown speech
      if (remaining >= 1 && remaining <= WorkoutConstants.countdownStart) {
        _speakCountdown(remaining);
      }
    }
    
    if (remaining <= 0) {
      _lastCountdownSpoken = 0;
      _advancePhase(silent: false);
    }
  }

  void _catchUpPhases(int backgroundSeconds) {
    if (_phaseStartTime == null) return;
    
    int timeToProcess = backgroundSeconds;
    
    while (timeToProcess > 0 && state.status == WorkoutStatus.running) {
      final remainingInPhase = state.currentPhaseDuration - 
          DateTime.now().difference(_phaseStartTime!).inSeconds + timeToProcess;
      
      if (remainingInPhase <= 0) {
        // This phase ended during background
        final phaseTime = state.currentPhaseDuration;
        timeToProcess -= phaseTime;
        _advancePhase(silent: true);
        
        if (state.status == WorkoutStatus.finished) break;
      } else {
        // Still in this phase
        break;
      }
    }
    
    // Recalculate remaining
    if (_phaseStartTime != null && state.status == WorkoutStatus.running) {
      final elapsed = DateTime.now().difference(_phaseStartTime!).inSeconds;
      final remaining = (state.currentPhaseDuration - elapsed).clamp(0, state.currentPhaseDuration);
      state = state.copyWith(remainingSeconds: remaining);
    }
  }

  void _advancePhase({required bool silent}) {
    if (state.phase == WorkoutPhase.work) {
      // Work -> Rest
      _phaseStartTime = DateTime.now();
      state = state.copyWith(
        phase: WorkoutPhase.rest,
        remainingSeconds: state.restDuration,
      );
      
      if (!silent) {
        Future.delayed(const Duration(milliseconds: 600), () => _speakRest());
        _vibratePhaseChange();
      }
    } else {
      // Rest -> Work (next round/exercise)
      if (state.currentRound < state.totalRounds) {
        _phaseStartTime = DateTime.now();
        state = state.copyWith(
          phase: WorkoutPhase.work,
          currentRound: state.currentRound + 1,
          remainingSeconds: state.workDuration,
        );
        
        if (!silent) {
          Future.delayed(const Duration(milliseconds: 600), () => _speakWork());
          _vibratePhaseChange();
        }
      } else if (state.currentExercise < state.totalExercises) {
        _phaseStartTime = DateTime.now();
        state = state.copyWith(
          phase: WorkoutPhase.work,
          currentExercise: state.currentExercise + 1,
          currentRound: 1,
          remainingSeconds: state.workDuration,
        );
        
        if (!silent) {
          _speak('Next exercise, Exercise ${state.currentExercise}');
          _vibratePhaseChange();
        }
      } else {
        // Workout complete
        _timer?.cancel();
        state = state.copyWith(status: WorkoutStatus.finished);
        
        if (!silent) {
          _speak('Workout complete, Great job');
          _vibrateComplete();
        }
      }
    }
  }

  // ===== TTS HELPERS =====

  Future<void> _speak(String text) async {
    if (!state.voiceCuesEnabled) return;
    
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  Future<void> _speakInitial() async {
    await _speak("Round ${state.currentRound}, Let's work");
  }

  void _speakWork() async {
    final halfRound = (state.totalRounds / 2).ceil();
    if (state.currentRound == state.totalRounds && state.totalRounds > 1) {
      await _speak('Final round, Give it all');
    } else if (state.totalRounds > 2 && state.currentRound == halfRound) {
      await _speak('Round ${state.currentRound}, Halfway there');
    } else {
      await _speak('Round ${state.currentRound}, Work');
    }
  }

  void _speakRest() async {
    if (state.isLastRound) {
      await _speak('Last rest, Almost done');
    } else {
      await _speak('Rest');
    }
  }

  void _speakCountdown(int seconds) {
    if (seconds == _lastCountdownSpoken) return;
    _lastCountdownSpoken = seconds;

    if (seconds >= 1 && seconds <= 3) {
      _speak('$seconds');
    }
  }

  void _speakComplete() {
    _speak('Done, Great job');
  }

  // ===== HAPTICS HELPERS =====

  Future<void> _vibratePhaseChange() async {
    if (!state.hapticsEnabled) return;
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 200, amplitude: 128);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  Future<void> _vibrateComplete() async {
    if (!state.hapticsEnabled) return;
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(pattern: [0, 300, 100, 300], intensities: [0, 200, 0, 200]);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }
}

// ===== PROVIDER =====
final workoutControllerProvider = StateNotifierProvider<WorkoutController, WorkoutState>((ref) {
  return WorkoutController();
});
