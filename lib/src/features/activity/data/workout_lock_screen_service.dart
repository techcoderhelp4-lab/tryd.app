import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Entry point for the background isolate ───────────────────────────────────
@pragma('vm:entry-point')
void workoutTaskEntryPoint() {
  FlutterForegroundTask.setTaskHandler(_WorkoutTaskHandler());
}

// ── Task handler (runs in background isolate) ─────────────────────────────────
class _WorkoutTaskHandler extends TaskHandler {
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

// ── Public data model ─────────────────────────────────────────────────────────
class WorkoutStats {
  final int elapsedSeconds;
  final double distanceKm;
  final double pacePerKm;
  final double calories;
  final int steps;
  final bool isPaused;
  final String workoutType;

  const WorkoutStats({
    required this.elapsedSeconds,
    required this.distanceKm,
    required this.pacePerKm,
    required this.calories,
    required this.steps,
    required this.isPaused,
    this.workoutType = 'running',
  });
}

// ── Singleton provider ────────────────────────────────────────────────────────
final workoutLockScreenServiceProvider = Provider<WorkoutLockScreenService>(
  (ref) => WorkoutLockScreenService(),
);

// ── Service ───────────────────────────────────────────────────────────────────
class WorkoutLockScreenService {
  static const _iosChannel = MethodChannel('tryd.app/live_activity');
  static const _androidChannel = MethodChannel('tryd.app/workout_notification');

  final StreamController<String> _actionController = StreamController.broadcast();
  Stream<String> get actionStream => _actionController.stream;

  final StreamController<int> _openTabController = StreamController.broadcast();
  Stream<int> get openTabStream => _openTabController.stream;

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
      } else if (call.method == 'openTab') {
        final tab = call.arguments as int?;
        if (tab != null) _openTabController.add(tab);
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
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  void _initIosHandler() {
    if (_iosHandlerSet) return;
    _iosHandlerSet = true;
    // Listen for actions sent from iOS via URL scheme (tryd://workout/<action>)
    // that AppDelegate parses and forwards here as onAction method calls.
    _iosChannel.setMethodCallHandler((call) async {
      if (call.method == 'onAction') {
        final action = call.arguments as String?;
        if (action != null) _actionController.add(action);
      }
    });
  }

  Future<void> start({required WorkoutStats stats}) async {
    if (Platform.isAndroid) {
      _initAndroidHandler();
      _initForegroundTask();
      await FlutterForegroundTask.startService(
        serviceId: 8881,
        notificationTitle: 'Workout in Progress',
        notificationText: 'Starting…',
        callback: workoutTaskEntryPoint,
      );
      _running = true;
      // Override the foreground service's plain notification with our custom UI.
      // Both use the same notification ID (8881) so ours replaces it in the shade.
      await _androidChannel.invokeMethod('show', _toMap(stats));
    } else if (Platform.isIOS) {
      _initIosHandler();
      await _iosStart(stats);
    }
  }

  Future<void> update({required WorkoutStats stats}) async {
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

  // ── iOS Live Activity helpers ─────────────────────────────────────────────

  Map<String, dynamic> _toMap(WorkoutStats s) => {
    'elapsedSeconds': s.elapsedSeconds,
    'distanceKm': s.distanceKm,
    'pacePerKm': s.pacePerKm,
    'calories': s.calories,
    'steps': s.steps,
    'isPaused': s.isPaused,
    'workoutType': s.workoutType,
  };

  Future<void> _iosStart(WorkoutStats s) async {
    try {
      await _iosChannel.invokeMethod('startActivity', _toMap(s));
    } on PlatformException catch (e) {
      debugPrint('LiveActivity start error: $e');
    }
  }

  Future<void> _iosUpdate(WorkoutStats s) async {
    try {
      await _iosChannel.invokeMethod('updateActivity', _toMap(s));
    } on PlatformException catch (e) {
      debugPrint('LiveActivity update error: $e');
    }
  }

  Future<void> _iosStop() async {
    try {
      await _iosChannel.invokeMethod('stopActivity');
    } on PlatformException catch (e) {
      debugPrint('LiveActivity stop error: $e');
    }
  }
}
