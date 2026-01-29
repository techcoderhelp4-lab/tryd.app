import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../domain/activity.dart';
import '../domain/workout.dart';
import '../domain/activity_stats.dart';

const String kWorkoutHistoryKey = 'workoutHistory';
const String kActivityHistoryKey = 'activityHistory';

class ActivityRepository {
  final Dio _dio;

  ActivityRepository(this._dio);

  Future<List<Activity>> getUserActivities() async {
    try {
      final response = await _dio.get(ApiConstants.activities);
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => Activity.fromJson(json)).toList();
    } catch (e) {
      // Fallback or rethrow
      return [];
    }
  }

  Future<ActivityStats> getActivityStats({String period = 'week'}) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.activities}/stats',
        queryParameters: {'period': period},
      );
      return ActivityStats.fromJson(response.data);
    } catch (e) {
       return ActivityStats(
         totalDistance: 0.0,
         totalDuration: 0,
         totalCalories: 0.0,
         averagePace: 0.0,
         averageBPM: 0.0,
         activityCount: 0,
         dailyStats: [],
       );
    }
  }

  Future<List<Workout>> getWorkoutHistory() async {
    try {
      // For now, we still use local storage for specific workout details if needed, 
      // but ideally we fetch all from activities API since workouts ARE activities in backend.
      final response = await _dio.get(
        ApiConstants.activities,
        queryParameters: {'type': 'workout'},
      );
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => Workout.fromJson(json)).toList();
    } catch (e) {
      // Local fallback
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(kWorkoutHistoryKey);
      if (historyJson == null) return [];
      
      final List<dynamic> decoded = jsonDecode(historyJson);
      return decoded.map((json) {
        if (json['id'] == null) json['id'] = DateTime.now().millisecondsSinceEpoch.toString();
        return Workout.fromJson(json);
      }).toList();
    }
  }

  Future<void> logActivity(Activity activity) async {
    try {
      await _dio.post(ApiConstants.activities, data: activity.toJson());
    } catch (e) {
      // Local save fallback for activities if needed
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(kActivityHistoryKey);
      List<dynamic> history = historyJson != null ? jsonDecode(historyJson) : [];
      history.insert(0, activity.toJson());
      if (history.length > 50) history.removeRange(50, history.length);
      await prefs.setString(kActivityHistoryKey, jsonEncode(history));
    }
  }

  Future<void> saveWorkout(Workout workout) async {
    await logActivity(workout);
  }

  Future<List<Workout>> _getLocalWorkoutHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(kWorkoutHistoryKey);
    if (historyJson == null) return [];
    final List<dynamic> decoded = jsonDecode(historyJson);
    return decoded.map((json) => Workout.fromJson(json)).toList();
  }
}

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return ActivityRepository(dio);
});

final activityListProvider = FutureProvider<List<Activity>>((ref) {
  final repository = ref.watch(activityRepositoryProvider);
  return repository.getUserActivities();
});

final activityStatsProvider = FutureProvider.family<ActivityStats, String>((ref, period) {
  final repository = ref.watch(activityRepositoryProvider);
  return repository.getActivityStats(period: period);
});

class WorkoutHistoryNotifier extends AsyncNotifier<List<Workout>> {
  @override
  FutureOr<List<Workout>> build() async {
    final repository = ref.watch(activityRepositoryProvider);
    return repository.getWorkoutHistory();
  }

  Future<void> addWorkout(Workout workout) async {
    final repository = ref.read(activityRepositoryProvider);
    await repository.saveWorkout(workout);
    ref.invalidateSelf();
    await future;
  }
}

final workoutHistoryProvider = AsyncNotifierProvider<WorkoutHistoryNotifier, List<Workout>>(
  () => WorkoutHistoryNotifier(),
);

