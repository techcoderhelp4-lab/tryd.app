import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class HealthRepository {
  final Health _health = Health();

  Future<bool> requestPermissions() async {
    // For Android 14+ / Health Connect, we MUST configure first
    if (!_isConfigured) {
      await _health.configure();
      _isConfigured = true;
    }

    // Define the types to get
    var types = [
      HealthDataType.STEPS,
      HealthDataType.DISTANCE_DELTA,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.HEART_RATE,
    ];

    var permissions = [
      HealthDataAccess.READ_WRITE,
      HealthDataAccess.READ_WRITE,
      HealthDataAccess.READ_WRITE,
      HealthDataAccess.READ_WRITE,
    ];

    try {
      bool requested = await _health.requestAuthorization(types, permissions: permissions);
      return requested;
    } catch (e) {
      print("Health authorization error: $e");
      return false;
    }
  }

  bool _isConfigured = false;

  Future<HealthConnectSdkStatus> getSdkStatus() async {
    try {
      if (!_isConfigured) {
        await _health.configure();
        _isConfigured = true;
      }
      final status = await _health.getHealthConnectSdkStatus();
      return status ?? HealthConnectSdkStatus.sdkUnavailable;
    } catch (e) {
      print("Health: Error getting SDK status (expected on some emulators): $e");
      return HealthConnectSdkStatus.sdkUnavailable;
    }
  }

  Future<int> getStepsToday() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return getStepsInInterval(midnight, now);
  }

  Future<int> getStepsInInterval(DateTime start, DateTime end) async {
    try {
      int? steps = await _health.getTotalStepsInInterval(start, end);
      return steps ?? 0;
    } catch (e) {
      print("Error fetching steps: $e");
      return 0;
    }
  }

  Future<double> getEnergyInInterval(DateTime start, DateTime end) async {
    double calories = 0.0;
    try {
      List<HealthDataPoint> points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );
      
      for (var point in points) {
        if (point.value is NumericHealthValue) {
            calories += (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }
    } catch (e) {
      print("Error fetching energy: $e");
    }
    return calories;
  }

  Future<Map<String, dynamic>> getDailyStats() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    int steps = 0;
    double distance = 0.0;
    double calories = 0.0;
    
    try {
      // Steps
      steps = (await _health.getTotalStepsInInterval(midnight, now)) ?? 0;

      // Other data points need manual fetching
      List<HealthDataPoint> distancePoints = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.DISTANCE_DELTA],
      );
      
      for (var point in distancePoints) {
        if (point.value is NumericHealthValue) {
            distance += (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }

      List<HealthDataPoint> caloriePoints = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );

       for (var point in caloriePoints) {
        if (point.value is NumericHealthValue) {
            calories += (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }

    } catch (e) {
      print("Error fetching daily stats: $e");
    }

    return {
      'steps': steps,
      'distance': distance, // in meters
      'calories': calories, // in kcal
    };
  }

  Future<List<HealthDataPoint>> getHeartRateData(DateTime startTime, DateTime endTime) async {
    try {
      return await _health.getHealthDataFromTypes(
        startTime: startTime,
        endTime: endTime,
        types: [HealthDataType.HEART_RATE],
      );
    } catch (e) {
      print("Error fetching heart rate: $e");
      return [];
    }
  }

  Future<bool> saveRunToHealth({
    required DateTime startTime,
    required DateTime endTime,
    required double totalDistanceMeters,
    required double totalEnergyBurned, // kcal
  }) async {
    try {
      return await _health.writeWorkoutData(
        activityType: HealthWorkoutActivityType.RUNNING,
        start: startTime,
        end: endTime,
        totalDistance: totalDistanceMeters.toInt(),
        totalEnergyBurned: totalEnergyBurned.toInt(), 
      );
    } catch (e) {
      print("Error saving to health: $e");
      return false;
    }
  }

  Future<void> installHealthConnect() async {
    await _health.installHealthConnect();
  }
  
}

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository();
});
