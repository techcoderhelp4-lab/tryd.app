import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../data/gym_workout_notification_service.dart';

// ===== CONSTANTS =====
class WorkoutConstants {
  static const int defaultWorkDuration = 45;
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

  // Notification service
  final _notifService = GymWorkoutNotificationService();
  StreamSubscription<String>? _notifActionSub;

  // TTS
  final FlutterTts _tts = FlutterTts();
  String _languageCode = 'en';
  String _lastTtsLang = '';

  void setLocale(String languageCode) {
    _languageCode = languageCode;
  }

  Future<void> _init() async {
    // Initialize TTS
    try {
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker],
          IosTextToSpeechAudioMode.defaultMode,
        );
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        await _pickBestTtsEngine();
      }
      // Set a safe default language so the engine is primed
      await _tts.setLanguage('en-US');
      _lastTtsLang = 'en-US';
    } catch (e) {
      debugPrint('TTS Init Error: $e');
    }
    
    // Load saved config
    try {
      final prefs = await SharedPreferences.getInstance();
      final work = (prefs.getInt('workDuration') ?? WorkoutConstants.defaultWorkDuration).clamp(5, 3600);
      final rest = (prefs.getInt('restDuration') ?? WorkoutConstants.defaultRestDuration).clamp(5, 3600);
      final exercises = (prefs.getInt('totalExercises') ?? WorkoutConstants.defaultExercises).clamp(1, 20);
      final rounds = (prefs.getInt('totalRounds') ?? WorkoutConstants.defaultRounds).clamp(1, 50);
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
    _notifActionSub?.cancel();
    _notifService.stop();
    _notifService.dispose();
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
      _speak(_isAr ? 'هيا بنا' : "Let's go");
    }

    state = state.copyWith(status: WorkoutStatus.running);
    _startTimer();
    _startNotification();
  }

  void pause() {
    _timer?.cancel();
    _pausedAt = DateTime.now();
    state = state.copyWith(status: WorkoutStatus.paused);
    _speak(_isAr ? 'متوقف' : 'Paused');
    _updateNotification(isPaused: true);
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
    _notifActionSub?.cancel();
    _notifActionSub = null;
    _notifService.stop();

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

  void handleAppResumed() {}

  void handleAppPaused() {}

  Future<void> updateConfig({
    int? workDuration,
    int? restDuration,
    int? totalExercises,
    int? totalRounds,
  }) async {
    // Apply changes to state first
    state = state.copyWith(
      workDuration: workDuration != null ? workDuration.clamp(5, 3600) : state.workDuration,
      restDuration: restDuration != null ? restDuration.clamp(5, 3600) : state.restDuration,
      totalExercises: totalExercises != null ? totalExercises.clamp(1, 20) : state.totalExercises,
      totalRounds: totalRounds != null ? totalRounds.clamp(1, 50) : state.totalRounds,
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
      _updateNotification();

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

  void _advancePhase({required bool silent}) {
    if (state.phase == WorkoutPhase.work) {
      _phaseStartTime = DateTime.now();
      state = state.copyWith(
        phase: WorkoutPhase.rest,
        remainingSeconds: state.restDuration,
      );
      _updateNotification();
      if (!silent) {
        Future.delayed(const Duration(milliseconds: 600), () => _speakRest());
        _vibratePhaseChange();
      }
    } else {
      if (state.currentRound < state.totalRounds) {
        _phaseStartTime = DateTime.now();
        state = state.copyWith(
          phase: WorkoutPhase.work,
          currentRound: state.currentRound + 1,
          remainingSeconds: state.workDuration,
        );
        _updateNotification();
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
        _updateNotification();
        if (!silent) {
          _speak(_isAr
              ? 'التمرين التالي، التمرين ${_arNum(state.currentExercise)}'
              : 'Next exercise, Exercise ${state.currentExercise}');
          _vibratePhaseChange();
        }
      } else {
        _timer?.cancel();
        _notifActionSub?.cancel();
        _notifActionSub = null;
        _notifService.stop();
        state = state.copyWith(status: WorkoutStatus.finished);
        if (!silent) {
          _speak(_isAr ? 'اكتملت التمرين، عمل رائع' : 'Workout complete, Great job');
          _vibrateComplete();
        }
      }
    }
  }

  // ===== NOTIFICATION HELPERS =====

  GymWorkoutStats _buildStats({bool isPaused = false}) => GymWorkoutStats(
        phase: state.phase == WorkoutPhase.work ? 'Work' : 'Rest',
        currentRound: state.currentRound,
        totalRounds: state.totalRounds,
        currentExercise: state.currentExercise,
        totalExercises: state.totalExercises,
        remainingSeconds: state.remainingSeconds,
        isPaused: isPaused,
      );

  void _startNotification() {
    _notifActionSub?.cancel();
    _notifActionSub = _notifService.actionStream.listen((action) {
      switch (action) {
        case 'pause':
          if (state.status == WorkoutStatus.running) pause();
        case 'resume':
          if (state.status == WorkoutStatus.paused) start();
        case 'finish':
          reset();
      }
    });
    _notifService.start(stats: _buildStats());
  }

  void _updateNotification({bool isPaused = false}) {
    _notifService.update(stats: _buildStats(isPaused: isPaused));
  }

  // ===== TTS HELPERS =====

  bool get _isAr => _languageCode == 'ar';

  Future<void> _pickBestTtsEngine() async {
    try {
      final engines = await _tts.getEngines as List?;
      if (engines == null || engines.isEmpty) return;
      // com.svox.pico does not support Arabic — exclude it from preference list
      const preferred = [
        'com.google.android.tts',
        'com.samsung.SMT',
        'com.samsung.android.app.tts',
      ];
      for (final pref in preferred) {
        final match = engines.cast<String?>().firstWhere(
          (e) => e != null && (e == pref || e.contains(pref.split('.').last)),
          orElse: () => null,
        );
        if (match != null) {
          await _tts.setEngine(match);
          debugPrint('TTS engine (workout): $match');
          return;
        }
      }
      // Fall back to whatever is available, skipping pico
      final fallback = engines.cast<String?>().firstWhere(
        (e) => e != null && !e.toString().contains('pico'),
        orElse: () => engines.first as String?,
      );
      if (fallback != null) await _tts.setEngine(fallback);
    } catch (e) {
      debugPrint('TTS engine pick error: $e');
    }
  }

  Future<void> _speak(String text) async {
    if (!state.voiceCuesEnabled) return;
    try {
      final lang = _isAr ? 'ar-EG' : 'en-US';
      await _tts.stop();
      if (_lastTtsLang != lang) {
        await _tts.setLanguage(lang);
        await _tts.setSpeechRate(0.5);
        await _tts.setVolume(1.0);
        await _tts.setPitch(1.0);
        _lastTtsLang = lang;
      }
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  String _arNum(int n) {
    const words = ['', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية', 'تسعة', 'عشرة'];
    return n >= 1 && n <= 10 ? words[n] : '$n';
  }

  Future<void> _speakInitial() async {
    await _speak(_isAr
        ? "الجولة ${_arNum(state.currentRound)}، هيا نعمل"
        : "Round ${state.currentRound}, Let's work");
  }

  void _speakWork() async {
    final halfRound = (state.totalRounds / 2).ceil();
    if (state.currentRound == state.totalRounds && state.totalRounds > 1) {
      await _speak(_isAr ? 'الجولة الأخيرة، أعطِ كل ما لديك' : 'Final round, Give it all');
    } else if (state.totalRounds > 2 && state.currentRound == halfRound) {
      await _speak(_isAr ? 'الجولة ${_arNum(state.currentRound)}، في المنتصف' : 'Round ${state.currentRound}, Halfway there');
    } else {
      await _speak(_isAr ? 'الجولة ${_arNum(state.currentRound)}، اعمل' : 'Round ${state.currentRound}, Work');
    }
  }

  void _speakRest() async {
    if (state.isLastRound) {
      await _speak(_isAr ? 'آخر استراحة، اقتربت من النهاية' : 'Last rest, Almost done');
    } else {
      await _speak(_isAr ? 'استراحة' : 'Rest');
    }
  }

  void _speakCountdown(int seconds) {
    if (seconds == _lastCountdownSpoken) return;
    _lastCountdownSpoken = seconds;
    if (seconds >= 1 && seconds <= 3) {
      const arWords = ['', 'واحد', 'اثنان', 'ثلاثة'];
      _speak(_isAr ? arWords[seconds] : '$seconds');
    }
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

