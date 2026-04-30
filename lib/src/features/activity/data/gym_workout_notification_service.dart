import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void gymWorkoutTaskEntryPoint() {
  FlutterForegroundTask.setTaskHandler(_GymTaskHandler());
}

class _GymTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}
  @override
  void onRepeatEvent(DateTime timestamp) {}
  @override
  Future<void> onDestroy(DateTime timestamp) async {}
  @override
  void onReceiveData(Object data) {}
  @override
  void onNotificationButtonPressed(String id) {}
}

// ── Stats model ───────────────────────────────────────────────────────────────

class GymWorkoutStats {
  final String phase;
  final int currentRound;
  final int totalRounds;
  final int currentExercise;
  final int totalExercises;
  final int remainingSeconds;
  final bool isPaused;

  const GymWorkoutStats({
    required this.phase,
    required this.currentRound,
    required this.totalRounds,
    required this.currentExercise,
    required this.totalExercises,
    required this.remainingSeconds,
    required this.isPaused,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────

class GymWorkoutNotificationService {
  static const _androidChannel =
      MethodChannel('tryd.app/gym_workout_notification');
  static const _iosChannel = MethodChannel('tryd.app/live_activity');

  final StreamController<String> _actionController =
      StreamController.broadcast();
  Stream<String> get actionStream => _actionController.stream;

  bool _initialized = false;
  bool _running = false;
  bool _iosHandlerSet = false;
  bool _androidHandlerSet = false;

  void _initAndroidHandler() {
    if (_androidHandlerSet) return;
    _androidHandlerSet = true;
    _androidChannel.setMethodCallHandler((call) async {
      if (call.method == 'onAction') {
        final action = call.arguments as String?;
        if (action != null) _actionController.add(action);
      }
    });
  }

  void _initIosHandler() {
    if (_iosHandlerSet) return;
    _iosHandlerSet = true;
    _iosChannel.setMethodCallHandler((call) async {
      if (call.method == 'onAction') {
        final action = call.arguments as String?;
        if (action != null) _actionController.add(action);
      }
    });
  }

  void _initForegroundTask() {
    if (_initialized) return;
    _initialized = true;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'tryd_workout_v4',
        channelName: 'Workout Tracking',
        channelDescription: 'Live workout stats on the lock screen',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.MAX,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  Future<void> start({required GymWorkoutStats stats}) async {
    if (Platform.isAndroid) {
      _initAndroidHandler();
      _initForegroundTask();
      await FlutterForegroundTask.startService(
        serviceId: 8883,
        notificationTitle: 'Gym Workout in Progress',
        notificationText: 'Starting…',
        callback: gymWorkoutTaskEntryPoint,
      );
      _running = true;
      await _androidChannel.invokeMethod('show', _toMap(stats));
    } else if (Platform.isIOS) {
      _initIosHandler();
      await _iosStart(stats);
    }
  }

  Future<void> update({required GymWorkoutStats stats}) async {
    if (Platform.isAndroid) {
      if (!_running) return;
      await _androidChannel.invokeMethod('update', _toMap(stats));
    } else if (Platform.isIOS) {
      await _iosUpdate(stats);
    }
  }

  Future<void> stop() async {
    _running = false;
    if (Platform.isAndroid) {
      await _androidChannel.invokeMethod('dismiss', null);
      await FlutterForegroundTask.stopService();
    } else if (Platform.isIOS) {
      await _iosStop();
    }
  }

  void dispose() {
    _actionController.close();
  }

  Map<String, dynamic> _toMap(GymWorkoutStats s) => {
        'phase': s.phase,
        'currentRound': s.currentRound,
        'totalRounds': s.totalRounds,
        'currentExercise': s.currentExercise,
        'totalExercises': s.totalExercises,
        'remainingSeconds': s.remainingSeconds,
        'isPaused': s.isPaused,
        // iOS Live Activity fields (running fields zeroed for gym)
        'elapsedSeconds': 0,
        'distanceKm': 0.0,
        'pacePerKm': 0.0,
        'calories': 0.0,
        'steps': 0,
        'workoutType': 'gym',
      };

  Future<void> _iosStart(GymWorkoutStats s) async {
    try {
      await _iosChannel.invokeMethod('startActivity', _toMap(s));
    } on PlatformException catch (e) {
      debugPrint('GymLiveActivity start error: $e');
    }
  }

  Future<void> _iosUpdate(GymWorkoutStats s) async {
    try {
      await _iosChannel.invokeMethod('updateActivity', _toMap(s));
    } on PlatformException catch (e) {
      debugPrint('GymLiveActivity update error: $e');
    }
  }

  Future<void> _iosStop() async {
    try {
      await _iosChannel.invokeMethod('stopActivity');
    } on PlatformException catch (e) {
      debugPrint('GymLiveActivity stop error: $e');
    }
  }
}
