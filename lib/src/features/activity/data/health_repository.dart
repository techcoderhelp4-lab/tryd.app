import 'package:health/health.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HealthSetupStatus { ready, notInstalled, needsPermissions }

class HealthRepository {
  final Health _health = Health();
  bool _isConfigured = false;
  bool _isHealthBroken = false;
  bool _isCrashGuardEnabled = false;

  // ============================================
  // FIXED: Added more granular data types for better accuracy
  // ============================================
  static List<HealthDataType> get _writeTypes => [
        HealthDataType.STEPS,
        if (Platform.isAndroid)
          HealthDataType.DISTANCE_DELTA
        else
          HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.HEART_RATE,
        HealthDataType.WORKOUT,
        // FIXED: Added speed for better pace calculation
        if (!Platform.isAndroid) HealthDataType.WALKING_SPEED,
      ];

  static List<HealthDataType> get _readOnlyTypes => [
        if (!Platform.isAndroid) HealthDataType.WALKING_SPEED,
        HealthDataType.FLIGHTS_CLIMBED,
        // FIXED: Added basal energy for total calorie calculation
        HealthDataType.BASAL_ENERGY_BURNED,
      ];

  static List<HealthDataType> get _allDataTypes =>
      [..._writeTypes, ..._readOnlyTypes];

  static List<HealthDataAccess> get _permissions => [
        ...List.filled(_writeTypes.length, HealthDataAccess.READ_WRITE),
        ...List.filled(_readOnlyTypes.length, HealthDataAccess.READ),
      ];

  Future<void> _ensureConfigured() async {
    if (!_isConfigured) {
      await _checkCrashGuard();
      await _health.configure();
      _isConfigured = true;
    }
  }

  Future<void> _checkCrashGuard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isVulnerable = prefs.getBool('health_crash_vulnerable') ?? false;
      if (isVulnerable) {
        debugPrint('Health: 🚨 CRASH GUARD TRIGGERED. Disabling health Connect due to previous fatal crash.');
        _isHealthBroken = true;
      }
    } catch (_) {}
  }

  Future<void> _setCrashVulnerable(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('health_crash_vulnerable', value);
    } catch (_) {}
  }

  // ==================== SETUP ====================

  Future<bool> hasPermissions() async {
    if (_isHealthBroken) return false;
    try {
      await _ensureConfigured();
      if (_isHealthBroken) return false;

      await _setCrashVulnerable(true);
      
      final result = await _health.hasPermissions(
        _allDataTypes,
        permissions: _permissions,
      );
      
      await _setCrashVulnerable(false);

      if (Platform.isAndroid && result == null) {
        debugPrint('Health: hasPermissions returned null (Android 11 limitation) — treating as authorized');
        return true;
      }
      return result == true;
    } catch (e) {
      await _setCrashVulnerable(false);
      debugPrint('Health: Error checking permissions: $e');
      if (e.toString().contains('RemoteException') || e.toString().contains('binding')) {
        _isHealthBroken = true;
      }
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    if (_isHealthBroken) return false;
    try {
      await _ensureConfigured();
      if (_isHealthBroken) return false;

      if (Platform.isAndroid) {
        final bool isBindable = await _channel.invokeMethod('isHealthConnectAvailable');
        if (!isBindable) {
          debugPrint('Health: Skipping permission request — Health Connect not bindable.');
          return false;
        }
        
        await Permission.activityRecognition.request();
      }

      final result = await hasPermissions();

      if (result == true) {
        debugPrint('Health: Already have all permissions.');
        return true;
      }

      await _setCrashVulnerable(true);
      
      final authorized = await _health.requestAuthorization(
        _allDataTypes,
        permissions: _permissions,
      );
      
      await _setCrashVulnerable(false);
      return authorized;
    } catch (e) {
      await _setCrashVulnerable(false);
      debugPrint('Health permission error: $e');
      if (e.toString().contains('RemoteException') || e.toString().contains('binding')) {
        _isHealthBroken = true;
      }
      
      try {
        final recheck = await hasPermissions();
        return recheck;
      } catch (_) {
        return false;
      }
    }
  }

  Future<bool> isHealthKitAvailable() async {
    if (_isHealthBroken) return false;
    if (Platform.isAndroid) {
      try {
        final bool isBindable = await _channel.invokeMethod('isHealthConnectAvailable');
        if (!isBindable) return false;
      } catch (_) {
        return false;
      }
    }
    return await _health.isHealthConnectAvailable();
  }

  // ==================== STATUS & PERSISTENCE ====================

  Future<bool> isHealthConnectInstalled() async {
    if (!Platform.isAndroid) return true; // iOS always has HealthKit
    try {
      final status = await _health.getHealthConnectSdkStatus();
      return status != null && status != HealthConnectSdkStatus.sdkUnavailable;
    } catch (_) {
      return false;
    }
  }

  Future<bool> wasInstallPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('health_install_prompted') ?? false;
  }

  Future<void> markInstallPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('health_install_prompted', true);
  }

  Future<HealthSetupStatus> getSetupStatus() async {
    if (!Platform.isAndroid) {
      // iOS: just check permissions
      final hasPerms = await hasPermissions();
      return hasPerms ? HealthSetupStatus.ready : HealthSetupStatus.needsPermissions;
    }

    // Android Step 1: Is Health Connect installed?
    final installed = await isHealthConnectInstalled();
    if (!installed) return HealthSetupStatus.notInstalled;

    // Android Step 2: Is it bindable? (Service ready)
    try {
      final bindable = await _channel.invokeMethod('isHealthConnectAvailable');
      if (!bindable) return HealthSetupStatus.notInstalled;
    } catch (_) {
      return HealthSetupStatus.notInstalled;
    }

    // Android Step 3: Check permissions
    final hasPerms = await hasPermissions();
    if (hasPerms == true) return HealthSetupStatus.ready;
    
    return HealthSetupStatus.needsPermissions;
  }

  Future<void> openHealthConnectPermissions() async {
    if (Platform.isAndroid) {
      try {
        // This opens Health Connect directly to your app's permissions page
        await _channel.invokeMethod('openHealthConnectPermissions');
      } catch (e) {
        debugPrint('Health: openHealthConnectPermissions failed, falling back to general settings: $e');
        try {
          await _channel.invokeMethod('openHealthConnectSettings');
        } catch (_) {}
      }
    } else {
      // iOS: Open generic app settings
      await openAppSettings();
    }
  }

  Future<HealthConnectSdkStatus> getSdkStatus() async {
    try {
      await _ensureConfigured();
      if (Platform.isAndroid) {
        HealthConnectSdkStatus officialStatus;
        try {
          officialStatus = await _health.getHealthConnectSdkStatus() ??
              HealthConnectSdkStatus.sdkUnavailable;
        } catch (_) {
          officialStatus = HealthConnectSdkStatus.sdkUnavailable;
        }

        if (officialStatus == HealthConnectSdkStatus.sdkUnavailable) {
          return HealthConnectSdkStatus.sdkUnavailable;
        }

        final bool isBindable =
            await _channel.invokeMethod('isHealthConnectAvailable');
        if (!isBindable) {
          debugPrint(
              'Health: SDK installed but service not bindable — device incompatible, disabling.');
          _isHealthBroken = true;
          await _setCrashVulnerable(false);
          return HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired;
        }

        _isHealthBroken = false;
        await _setCrashVulnerable(false);
        return officialStatus;
      }
      return HealthConnectSdkStatus.sdkAvailable;
    } catch (e) {
      debugPrint('Health: Error getting SDK status: $e');
      return HealthConnectSdkStatus.sdkUnavailable;
    }
  }

  static const _channel = MethodChannel('tryd.app/health_connect');

  Future<void> installHealthConnect() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('openHealthConnectSettings');
      } catch (e) {
        debugPrint('Health Connect settings error: $e');
        try {
          await _health.installHealthConnect();
        } catch (_) {}
      }
    }
  }

  Future<void> openHealthConnectSettings() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('openHealthConnectSettings');
      } catch (e) {
        debugPrint('Health Connect settings error: $e');
      }
    }
  }

  // ==================== FETCHING ====================

  Future<int> getStepsToday() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return getStepsInInterval(midnight, now);
  }

  Future<int> getStepsInInterval(DateTime start, DateTime end) async {
    try {
      final steps = await _health.getTotalStepsInInterval(start, end);
      return steps ?? 0;
    } catch (e) {
      debugPrint('Error fetching steps: $e');
      return 0;
    }
  }

  // ============================================
  // FIXED: Better distance calculation with validation
  // ============================================
  Future<double> getDistanceInInterval(DateTime start, DateTime end) async {
    try {
      final type = Platform.isAndroid
          ? HealthDataType.DISTANCE_DELTA
          : HealthDataType.DISTANCE_WALKING_RUNNING;
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [type],
      );
      
      double total = 0;
      double lastValue = 0;
      
      for (final p in points) {
        if (p.value is NumericHealthValue) {
          final value = (p.value as NumericHealthValue).numericValue.toDouble();
          
          // FIXED: Validate against unrealistic jumps (GPS glitch protection)
          if (value > lastValue * 10 && lastValue > 0) {
            debugPrint('Health: Skipping distance spike: $value vs last: $lastValue');
            continue;
          }
          
          total += value;
          lastValue = value;
        }
      }
      return total; // meters
    } catch (e) {
      debugPrint('Error fetching distance: $e');
      return 0;
    }
  }

  Future<double> getEnergyInInterval(DateTime start, DateTime end) async {
    try {
      // FIXED: Get both active and basal for total calories
      final activePoints = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );
      
      double activeTotal = 0;
      for (final p in activePoints) {
        if (p.value is NumericHealthValue) {
          activeTotal += (p.value as NumericHealthValue).numericValue.toDouble();
        }
      }
      
      // Only add basal on iOS (Android doesn't have reliable basal in Health Connect)
      if (!Platform.isAndroid) {
        final basalPoints = await _health.getHealthDataFromTypes(
          startTime: start,
          endTime: end,
          types: [HealthDataType.BASAL_ENERGY_BURNED],
        );
        
        for (final p in basalPoints) {
          if (p.value is NumericHealthValue) {
            activeTotal += (p.value as NumericHealthValue).numericValue.toDouble();
          }
        }
      }
      
      return activeTotal;
    } catch (e) {
      debugPrint('Error fetching energy: $e');
      return 0;
    }
  }

  Future<List<HealthDataPoint>> getHeartRateData(
      DateTime start, DateTime end) async {
    try {
      return await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.HEART_RATE],
      );
    } catch (e) {
      debugPrint('Error fetching heart rate: $e');
      return [];
    }
  }

  // ============================================
  // FIXED: Better current HR with median filtering
  // ============================================
  Future<double> getCurrentHeartRate() async {
    try {
      final end = DateTime.now();
      final start = end.subtract(const Duration(minutes: 2)); // Shorter window for real-time
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.HEART_RATE],
      );
      
      if (points.isEmpty) return 0;
      
      // FIXED: Use median instead of last to avoid outliers
      final values = points
          .where((p) => p.value is NumericHealthValue)
          .map((p) => (p.value as NumericHealthValue).numericValue.toDouble())
          .toList();
      
      if (values.isEmpty) return 0;
      
      values.sort();
      final median = values.length % 2 == 0
          ? (values[values.length ~/ 2 - 1] + values[values.length ~/ 2]) / 2
          : values[values.length ~/ 2];
      
      return median;
    } catch (e) {
      debugPrint('Error getting current heart rate: $e');
      return 0;
    }
  }

  // ============================================
  // FIXED: Better pace calculation with smoothing
  // ============================================
  Future<double> getRunningPace(DateTime start, DateTime end) async {
    if (Platform.isAndroid) {
      // Android: Calculate from distance/time since WALKING_SPEED not available
      try {
        final distance = await getDistanceInInterval(start, end);
        final duration = end.difference(start).inSeconds;
        
        if (duration > 0 && distance > 0) {
          final pace = (duration / 60.0) / (distance / 1000.0); // min/km
          return pace > 30 ? 0 : pace; // Validate: max 30 min/km (very slow walk)
        }
      } catch (e) {
        debugPrint('Error calculating Android pace: $e');
      }
      return 0;
    }
    
    // iOS: Use WALKING_SPEED
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.WALKING_SPEED],
      );
      
      if (points.isEmpty) return 0;
      
      // FIXED: Average multiple readings for stability
      double totalSpeed = 0;
      int count = 0;
      
      for (final p in points) {
        if (p.value is NumericHealthValue) {
          final speed = (p.value as NumericHealthValue).numericValue.toDouble();
          if (speed > 0.5 && speed < 8) { // Valid running range: 0.5-8 m/s
            totalSpeed += speed;
            count++;
          }
        }
      }
      
      if (count == 0) return 0;
      
      final avgSpeed = totalSpeed / count;
      return 1000 / (avgSpeed * 60); // → min/km
      
    } catch (e) {
      debugPrint('Error fetching pace: $e');
      return 0;
    }
  }

  Future<int> getFloorsClimbed(DateTime start, DateTime end) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.FLIGHTS_CLIMBED],
      );
      int total = 0;
      for (final p in points) {
        if (p.value is NumericHealthValue) {
          total += (p.value as NumericHealthValue).numericValue.toInt();
        }
      }
      return total;
    } catch (e) {
      debugPrint('Error fetching floors climbed: $e');
      return 0;
    }
  }

  Future<Map<String, dynamic>> getDailyStats() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return {
      'steps': await getStepsInInterval(midnight, now),
      'distance': await getDistanceInInterval(midnight, now),
      'calories': await getEnergyInInterval(midnight, now),
    };
  }

  Future<Map<String, dynamic>> getWorkoutData(
      DateTime start, DateTime end) async {
    return {
      'steps': await getStepsInInterval(start, end),
      'distance': await getDistanceInInterval(start, end),
      'calories': await getEnergyInInterval(start, end),
      'heartRate': await getCurrentHeartRate(),
      'pace': await getRunningPace(start, end),
      'floorsClimbed': await getFloorsClimbed(start, end),
    };
  }

  // ==================== REAL-TIME STREAMS ====================

  // ============================================
  // FIXED: Faster polling for real-time (1 second instead of 3)
  // ============================================
  Stream<int> getRealtimeSteps() async* {
    DateTime lastCheck = DateTime.now();
    int lastSteps = 0;
    
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      final now = DateTime.now();
      final totalSteps = await getStepsInInterval(lastCheck, now);
      
      // FIXED: Return delta, not total
      if (totalSteps > lastSteps) {
        yield totalSteps - lastSteps;
        lastSteps = totalSteps;
      } else if (totalSteps > 0) {
        yield totalSteps;
        lastSteps = totalSteps;
      }
      
      lastCheck = now;
    }
  }

  Stream<double> getRealtimeDistance() async* {
    DateTime lastCheck = DateTime.now();
    double lastDistance = 0;
    
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      final now = DateTime.now();
      final totalDistance = await getDistanceInInterval(lastCheck, now);
      
      // FIXED: Return delta with validation
      if (totalDistance > lastDistance) {
        final delta = totalDistance - lastDistance;
        if (delta < 100) { // Max 100m per second (360 km/h - impossible)
          yield delta;
        }
        lastDistance = totalDistance;
      } else if (totalDistance > 0) {
        yield totalDistance;
        lastDistance = totalDistance;
      }
      
      lastCheck = now;
    }
  }

  Stream<double> getRealtimeCalories() async* {
    DateTime lastCheck = DateTime.now();
    double lastCalories = 0;
    
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      final now = DateTime.now();
      final totalCalories = await getEnergyInInterval(lastCheck, now);
      
      if (totalCalories > lastCalories) {
        yield totalCalories - lastCalories;
        lastCalories = totalCalories;
      } else if (totalCalories > 0) {
        yield totalCalories;
        lastCalories = totalCalories;
      }
      
      lastCheck = now;
    }
  }

  Stream<double> getRealtimePace() async* {
    DateTime windowStart = DateTime.now();
    
    while (true) {
      await Future.delayed(const Duration(seconds: 2)); // Faster updates
      
      final end = DateTime.now();
      final pace = await getRunningPace(windowStart, end);
      
      if (pace > 0 && pace < 30) { // Valid range
        yield pace;
      }
      
      // Slide window
      windowStart = end.subtract(const Duration(seconds: 30));
    }
  }

  Stream<double> getRealtimeHeartRate() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      final hr = await getCurrentHeartRate();
      if (hr > 30 && hr < 250) { // Valid HR range
        yield hr;
      }
    }
  }

  // ==================== NATIVE PLATFORM CHANNELS ====================

  static const _healthChannel = MethodChannel('tryd.app/health_ultra');

  Future<void> startIOSHealthKitObserverQueries(
      void Function(String type, double value) onData) async {
    if (Platform.isIOS) {
      try {
        await _healthChannel.invokeMethod('startHealthKitObservers');
        _healthChannel.setMethodCallHandler((call) async {
          if (call.method == 'onHealthDataUpdate') {
            final data = call.arguments as Map<dynamic, dynamic>;
            final type = data['type'] as String;
            final value = (data['value'] as num).toDouble();
            onData(type, value);
          }
        });
      } catch (e) {
        debugPrint('Health: iOS observer queries not available, using streams: $e');
      }
    }
  }

  Future<void> startAndroidHealthConnectLiveData() async {
    if (Platform.isAndroid) {
      try {
        await _healthChannel.invokeMethod('startHealthConnectLiveData');
      } catch (e) {
        debugPrint('Health: Android live data channel not available: $e');
      }
    }
  }

  // ==================== WRITE DELTA (real-time) ====================

  Future<void> writeDistanceDelta(double meters, DateTime start, DateTime end) async {
    if (_isHealthBroken || meters <= 0) return;
    try {
      await _ensureConfigured();
      final type = Platform.isAndroid
          ? HealthDataType.DISTANCE_DELTA
          : HealthDataType.DISTANCE_WALKING_RUNNING;
      
      // FIXED: Validate before writing
      if (meters > 1000) { // Max 1km per write (impossible in <1 second)
        debugPrint('Health: Rejecting unrealistic distance delta: ${meters}m');
        return;
      }
      
      await _health.writeHealthData(
        value: meters,
        type: type,
        startTime: start,
        endTime: end,
      );
      debugPrint('Health: ✍️ Wrote distance delta: ${meters.toStringAsFixed(1)}m');
    } catch (e) {
      debugPrint('Health: Failed to write distance delta: $e');
    }
  }

  // ==================== SAVE ====================

  Future<bool> saveRunToHealth({
    required DateTime startTime,
    required DateTime endTime,
    required double totalDistanceMeters,
    required double totalEnergyBurned,
    required int totalSteps,
    required double averageHeartRate,
    required double averagePace,
    required int floorsClimbed,
  }) async {
    try {
      await _health.writeWorkoutData(
        activityType: HealthWorkoutActivityType.RUNNING,
        start: startTime,
        end: endTime,
        totalDistance: totalDistanceMeters.toInt(),
        totalDistanceUnit: HealthDataUnit.METER,
        totalEnergyBurned: totalEnergyBurned.toInt(),
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
      );

      final writes = <Future<bool>>[];

      if (totalDistanceMeters > 0) {
        writes.add(_health.writeHealthData(
          value: totalDistanceMeters,
          type: Platform.isAndroid
              ? HealthDataType.DISTANCE_DELTA
              : HealthDataType.DISTANCE_WALKING_RUNNING,
          startTime: startTime,
          endTime: endTime,
        ));
      }
      if (totalEnergyBurned > 0) {
        writes.add(_health.writeHealthData(
          value: totalEnergyBurned,
          type: HealthDataType.ACTIVE_ENERGY_BURNED,
          startTime: startTime,
          endTime: endTime,
        ));
      }
      if (totalSteps > 0) {
        writes.add(_health.writeHealthData(
          value: totalSteps.toDouble(),
          type: HealthDataType.STEPS,
          startTime: startTime,
          endTime: endTime,
        ));
      }
      if (floorsClimbed > 0) {
        writes.add(_health.writeHealthData(
          value: floorsClimbed.toDouble(),
          type: HealthDataType.FLIGHTS_CLIMBED,
          startTime: startTime,
          endTime: endTime,
        ));
      }
      if (averageHeartRate > 0) {
        writes.add(_health.writeHealthData(
          value: averageHeartRate,
          type: HealthDataType.HEART_RATE,
          startTime: startTime,
          endTime: endTime,
        ));
      }

      await Future.wait(writes);
      return true;
    } catch (e) {
      debugPrint('Error saving to Health Kit: $e');
      return false;
    }
  }
}

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository();
});