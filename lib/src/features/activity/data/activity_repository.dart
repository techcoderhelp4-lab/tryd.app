import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../domain/activity.dart';
import '../domain/workout.dart';
import '../domain/activity_stats.dart';
import '../../profile/data/user_repository.dart';

const String kWorkoutHistoryKey = 'workoutHistory';
const String kActivityHistoryKey = 'activityHistory';

class ActivityRepository {
  final Dio _dio;

  ActivityRepository(this._dio);

  Future<List<Activity>> getUserActivities() async {
    // Big App logic: Everything is an Activity.
    // Merge local runs and local workouts first for instant offline access.
    final localActivities = await _getLocalActivities();
    final localWorkouts = await _getLocalWorkoutHistory();
    
    // Map workouts to activities if they aren't already
    final List<Activity> unifiedLocal = [
      ...localActivities,
      ...localWorkouts.map((w) => Activity(
        id: w.id,
        type: 'workout',
        duration: w.duration,
        calories: w.calories,
        date: w.date,
        // Workouts don't have distance/pace usually
        distance: 0.0,
        averagePace: 0.0,
        averageBPM: 0.0,
      )),
    ];

    try {
      final response = await _dio.get(ApiConstants.activities);
      final List<dynamic> data = response.data['data'] ?? response.data;
      final List<Activity> remoteActivities = data.map((json) => Activity.fromJson(json)).toList();
      
      // Deduplicate by ID
      final Map<String, Activity> activityMap = {
        for (var a in unifiedLocal) a.id: a,
      };
      for (var a in remoteActivities) {
        activityMap[a.id] = a;
      }
      
      final result = activityMap.values.toList();
      result.sort((a, b) => b.date.compareTo(a.date));
      
      // Sync back to local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kActivityHistoryKey, jsonEncode(result.map((e) => e.toJson()).toList()));
      
      return result;
    } catch (e) {
      unifiedLocal.sort((a, b) => b.date.compareTo(a.date));
      return unifiedLocal;
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
       // Calculation fallback from local data (Strava/NRC style unified calculation)
       final activities = await getUserActivities();
       final now = DateTime.now();
       
       DateTime startDate;
       final today = DateTime(now.year, now.month, now.day);
       
       if (period == 'month') {
         startDate = DateTime(now.year, now.month, 1);
       } else if (period == 'year') {
         startDate = DateTime(now.year, 1, 1);
       } else {
         // Default to "Last 7 Days" including today
         startDate = today.subtract(const Duration(days: 6));
       }

       final filtered = activities.where((a) => a.date.isAfter(startDate.subtract(const Duration(seconds: 1)))).toList();
       
       double totalDist = 0;
       int totalDur = 0;
       double totalCals = 0;
       double runningPaceSum = 0;
       int runningCount = 0;
       double totalBpm = 0;
       int bpmCount = 0;

       Map<String, double> dailyDistances = {};
       Map<String, int> dailyCounts = {};

       // Initialize current week in dailyStats even if empty (Big App detail)
       if (period == 'week') {
          for (int i = 0; i < 7; i++) {
            final day = startDate.add(Duration(days: i));
            final key = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
            dailyDistances[key] = 0.0;
            dailyCounts[key] = 0;
          }
       }

       for (var a in filtered) {
         totalDist += a.distance;
         totalDur += a.duration;
         totalCals += a.calories;
         
         if (a.type == 'run' && a.averagePace > 0) {
           runningPaceSum += a.averagePace;
           runningCount++;
         }
         
         if (a.averageBPM > 0) {
           totalBpm += a.averageBPM;
           bpmCount++;
         }

         final dateKey = "${a.date.year}-${a.date.month.toString().padLeft(2, '0')}-${a.date.day.toString().padLeft(2, '0')}";
         if (period == 'week' || period == 'month') {
            dailyDistances[dateKey] = (dailyDistances[dateKey] ?? 0) + a.distance;
            dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
         }
       }

       List<DailyStat> dailyStats = dailyDistances.entries.map((e) => DailyStat(
         date: e.key,
         distance: e.value,
         activities: dailyCounts[e.key] ?? 0,
       )).toList();
       
       dailyStats.sort((a, b) => a.date.compareTo(b.date));

       return ActivityStats(
         totalDistance: totalDist,
         totalDuration: totalDur,
         totalCalories: totalCals,
         averagePace: runningCount == 0 ? 0 : runningPaceSum / runningCount,
         averageBPM: bpmCount == 0 ? 0 : totalBpm / bpmCount,
         activityCount: filtered.length,
         dailyStats: dailyStats,
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
    // PREPARE DATA: Convert to JSON and add 'syncStatus' = 'pending'
    final activityJson = activity.toJson();
    activityJson['syncStatus'] = 'pending';

    // 1. SAVE LOCALLY (Instant Persistence)
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(kActivityHistoryKey);
    List<dynamic> history = historyJson != null ? jsonDecode(historyJson) : [];
    
    // Check if activity with this ID already exists
    final existingIndex = history.indexWhere((item) => (item['_id'] ?? item['id']) == activity.id);
    if (existingIndex != -1) {
      history[existingIndex] = activityJson;
    } else {
      history.insert(0, activityJson);
    }
    
    // Maintain buffer limit
    if (history.length > 100) history.removeRange(100, history.length);
    await prefs.setString(kActivityHistoryKey, jsonEncode(history));

    // 2. ATTEMPT REMOTE SAVE (Dual Saving)
    try {
      final Map<String, dynamic> remotePayload = activity.toJson();
      remotePayload.remove('_id'); // Server generates its own ID
      
      await _dio.post(ApiConstants.activities, data: remotePayload);
      
      // 3. ON SUCCESS: Update status to 'synced'
      activityJson['syncStatus'] = 'synced';
      
      // Update local storage again with synced status
      // Re-read in case of race conditions (simple approach here)
      final updatedHistoryJson = prefs.getString(kActivityHistoryKey);
      if (updatedHistoryJson != null) {
         history = jsonDecode(updatedHistoryJson);
         final index = history.indexWhere((item) => (item['_id'] ?? item['id']) == activity.id);
         if (index != -1) {
           history[index]['syncStatus'] = 'synced';
           await prefs.setString(kActivityHistoryKey, jsonEncode(history));
         }
      }

    } catch (e) {
      // API failed, but we already saved locally as pending.
      // It will show as "Pending Sync" in UI if UI checks this field.
      debugPrint('API logActivity failed, remaining pending: $e');
    }
  }

  Future<void> syncPendingActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(kActivityHistoryKey);
    if (historyJson == null) return;
    
    List<dynamic> history = jsonDecode(historyJson);
    bool changed = false;

    for (var item in history) {
      if (item['syncStatus'] == 'pending') {
        try {
          // Attempt upload
          // Reconstruct Activity object to strip extra fields if necessary or just send json
          // The API expects standard Activity JSON. 'syncStatus' might be ignored or accepted.
          // Safer to remove it before sending if API is strict, but usually fine.
          final Map<String, dynamic> dataToSend = Map.from(item);
          dataToSend.remove('syncStatus'); // Remove local-only field

          await _dio.post(ApiConstants.activities, data: dataToSend);
          
          item['syncStatus'] = 'synced';
          changed = true;
          debugPrint("Synced pending activity: ${item['id']}");
        } catch (e) {
          debugPrint("Failed to sync activity: ${item['id']} - $e");
        }
      }
    }

    if (changed) {
      await prefs.setString(kActivityHistoryKey, jsonEncode(history));
    }
  }

  Future<void> saveWorkout(Workout workout) async {
    await logActivity(workout);
  }

  Future<List<Activity>> _getLocalActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(kActivityHistoryKey);
    if (historyJson == null) return [];
    final List<dynamic> decoded = jsonDecode(historyJson);
    return decoded.map((json) => Activity.fromJson(json)).toList();
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
    ref.invalidate(userProfileProvider);
    ref.invalidateSelf();
    await future;
  }
}

final workoutHistoryProvider = AsyncNotifierProvider<WorkoutHistoryNotifier, List<Workout>>(
  () => WorkoutHistoryNotifier(),
);

