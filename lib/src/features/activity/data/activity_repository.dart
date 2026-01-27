import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../domain/activity.dart';
import '../domain/workout.dart';

part 'activity_repository.g.dart';

const String kWorkoutHistoryKey = 'workoutHistory';
const String kActivityHistoryKey = 'activityHistory';

class ActivityRepository {
  final Dio _dio;

  ActivityRepository(this._dio);

  Future<List<Activity>> getUserActivities() async {

    return [
      Activity(id: '1', type: 'run', distance: 2.5, duration: 1245, calories: 300, date: DateTime.now().subtract(const Duration(days: 1))),
      Activity(id: '2', type: 'run', distance: 3.0, duration: 1500, calories: 350, date: DateTime.now().subtract(const Duration(days: 3))),
    ];
  }

  Future<List<Workout>> getWorkoutHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(kWorkoutHistoryKey);
      if (historyJson == null) return [];
      
      final List<dynamic> decoded = jsonDecode(historyJson);
      return decoded.map((json) {
        // Handle migration if needed, or just parse
        // Ensure id exists
        if (json['id'] == null) json['id'] = DateTime.now().millisecondsSinceEpoch.toString();
        if (json['type'] == null) json['type'] = 'hiit';
        if (json['duration'] == null && json['totalTime'] != null) json['duration'] = json['totalTime']; // Map totalTime to duration
        if (json['calories'] == null) json['calories'] = 0.0;
        
        return Workout.fromJson(json);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveWorkout(Workout workout) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getWorkoutHistory();
    final newHistory = [workout, ...history];
    if (newHistory.length > 50) newHistory.removeRange(50, newHistory.length);
    
    await prefs.setString(kWorkoutHistoryKey, jsonEncode(newHistory.map((e) => e.toJson()).toList()));
  }

  // Combined stream or future could go here
}

@riverpod
ActivityRepository activityRepository(ActivityRepositoryRef ref) {
  final dio = ref.watch(apiClientProvider);
  return ActivityRepository(dio);
}

@riverpod
Future<List<Activity>> activityList(ActivityListRef ref) {
  final repository = ref.watch(activityRepositoryProvider);
  return repository.getUserActivities();
}

@riverpod
class WorkoutHistory extends _$WorkoutHistory {
  @override
  Future<List<Workout>> build() async {
    final repository = ref.watch(activityRepositoryProvider);
    return repository.getWorkoutHistory();
  }

  Future<void> addWorkout(Workout workout) async {
    final repository = ref.read(activityRepositoryProvider);
    await repository.saveWorkout(workout);
    // Invalidate self to refresh the list
    ref.invalidateSelf();
    await future;
  }
}
