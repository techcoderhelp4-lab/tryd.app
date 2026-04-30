import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/database/local_database.dart';
import '../domain/activity.dart';
import '../domain/workout.dart';
import '../domain/activity_stats.dart';
import '../../profile/data/user_repository.dart';
import '../../challenges/data/challenge_repository.dart';
import '../../notifications/data/notification_repository.dart';

const String kWorkoutHistoryKey = 'workoutHistory';
const String kActivityHistoryKey = 'activityHistory';

class ActivityRepository {
  final Dio _dio;
  final LocalDatabase _localDb;

  ActivityRepository(this._dio, this._localDb);

  Future<List<Activity>> getUserActivities({bool triggerSync = true}) async {
    // 1. Fetch from Local Database first (Instant)
    final localData = await _localDb.getActivities();
    final List<Activity> localActivities = localData.map((json) {
      final type = json['type']?.toString().toLowerCase() ?? 'run';
      if (type == 'workout' || type == 'hiit') {
        return Workout.fromJson(json);
      }
      return Activity.fromJson(json);
    }).where((a) => !a.id.startsWith('mock_')).toList();
    
    if (triggerSync) {
      _fetchAndSyncRemote();
    }
    
    return localActivities;
  }

  Future<bool> _fetchAndSyncRemote() async {
    final oldActivitiesCount = (await _localDb.getActivities()).length;

    // Fetch Activities + Workouts in parallel
    Future<Response?> safeFetch(String url) async {
      try {
        return await _dio.get(url);
      } catch (e) {
        debugPrint("Sync fetch failed ($url): $e");
        return null;
      }
    }

    final results = await Future.wait([
      safeFetch(ApiConstants.activities),
      safeFetch(ApiConstants.workouts),
    ]);

    // Process Activities
    final activityResponse = results[0];
    if (activityResponse != null) {
      final dynamic rawData = activityResponse.data;
      final List<dynamic> data = (rawData is List) ? rawData : (rawData['data'] ?? []);
      for (var json in data) {
        final a = Activity.fromJson(json);
        await _localDb.insertActivityFromRemote(_cleanForSql(a.toJson(), a.id));
      }
      debugPrint("Activity sync success: ${data.length} items synced");
    }

    // Process Workouts
    final workoutResponse = results[1];
    if (workoutResponse != null) {
      final dynamic rawData = workoutResponse.data;
      final List<dynamic> data = (rawData is List) ? rawData : (rawData['data'] ?? []);
      for (var json in data) {
        final w = Workout.fromJson(json);
        await _localDb.insertActivityFromRemote(_cleanForSql(w.toJson(), w.id));
      }
      debugPrint("Workout sync success: ${data.length} items synced");
    }

    final newActivitiesCount = (await _localDb.getActivities()).length;
    return newActivitiesCount != oldActivitiesCount;
  }

  Map<String, dynamic> _cleanForSql(Map<String, dynamic> json, String id, {String status = 'synced'}) {
    // Only keep keys that exist in our SQL schema to prevent crashes
    final sqfKeys = [
      'id', 'type', 'distance', 'duration', 'caloriesBurned', 
      'averagePace', 'averageBPM', 'exercisesCount', 'roundsCount', 
      'workTime', 'restTime', 'date', 'syncStatus'
    ];
    
    final Map<String, dynamic> cleaned = {};
    for (var key in sqfKeys) {
      if (json.containsKey(key)) {
        cleaned[key] = json[key];
      }
    }
    
    // Explicitly handle field name mapping if they were passed differently (e.g. from domain models)
    if (json.containsKey('calories') && !cleaned.containsKey('caloriesBurned')) {
      cleaned['caloriesBurned'] = json['calories'];
    }
    if (json.containsKey('totalDuration') && !cleaned.containsKey('duration')) {
      cleaned['duration'] = json['totalDuration'];
    }
    if (json.containsKey('workDuration') && !cleaned.containsKey('workTime')) {
      cleaned['workTime'] = json['workDuration'];
    }
    if (json.containsKey('restDuration') && !cleaned.containsKey('restTime')) {
      cleaned['restTime'] = json['restDuration'];
    }
    if (json.containsKey('exercises') && !cleaned.containsKey('exercisesCount')) {
      cleaned['exercisesCount'] = json['exercises'];
    }
    if (json.containsKey('rounds') && !cleaned.containsKey('roundsCount')) {
      cleaned['roundsCount'] = json['rounds'];
    }

    // Ensure ID and syncStatus are set correctly for SQL
    cleaned['id'] = id;
    cleaned['syncStatus'] = status;
    
    // Ensure date is a string (SQFlite doesn't support DateTime)
    if (json['date'] is DateTime) {
      cleaned['date'] = (json['date'] as DateTime).toIso8601String();
    } else if (json['date'] != null) {
      cleaned['date'] = json['date'].toString();
    }

    return cleaned;
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
       } else if (period == 'all') {
         startDate = DateTime(2020); // Far enough in past
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
         dailyDistances[dateKey] = (dailyDistances[dateKey] ?? 0) + a.distance;
         dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
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
      final response = await _dio.get(ApiConstants.workouts);
      final dynamic rawData = response.data;
      final List<dynamic> data = (rawData is List) ? rawData : (rawData['data'] ?? []);
      final List<Workout> remoteWorkouts = data.map((json) => Workout.fromJson(json)).toList();

      // Sort newest first
      remoteWorkouts.sort((a, b) => b.date.compareTo(a.date));

      // Sync back to local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kWorkoutHistoryKey, jsonEncode(remoteWorkouts.map((e) => e.toJson()).toList()));

      return remoteWorkouts;
    } catch (e) {
      // Local fallback
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(kWorkoutHistoryKey);
      if (historyJson == null) return [];
      
      final List<dynamic> decoded = jsonDecode(historyJson);
      final workouts = decoded.map((json) {
        if (json['id'] == null) json['id'] = DateTime.now().millisecondsSinceEpoch.toString();
        return Workout.fromJson(json);
      }).toList();
      workouts.sort((a, b) => b.date.compareTo(a.date));
      return workouts;
    }
  }


  Future<void> logActivity(Activity activity, {String? customEndpoint}) async {
    final String endpoint = customEndpoint ?? ApiConstants.activities;
    
    // 1. SAVE LOCALLY IMMEDIATELY (Instant Feedback)
    final json = activity.toJson();
    final cleanedJson = _cleanForSql(json, activity.id, status: 'pending');
    
    try {
      await _localDb.insertActivity(cleanedJson);
      debugPrint("Logged activity locally: ${activity.id} (Status: pending)");
    } catch (e) {
      debugPrint("Failed to log activity locally: $e");
      // Even if local save fails (unlikely after cleaning), we attempt remote
    }

    // 2. ATTEMPT REMOTE SAVE
    try {
      final Map<String, dynamic> remotePayload = activity.toJson();
      remotePayload.remove('_id'); 
      
      final response = await _dio.post(endpoint, data: remotePayload);
      
      // 3. ON SUCCESS: Update local record with server ID and mark as 'synced'
      final serverId = response.data['_id']?.toString() ?? response.data['id']?.toString();
      if (serverId != null) {
        await _localDb.updateSyncStatusAndId(activity.id, serverId, 'synced');
        debugPrint("Logged activity remotely: $serverId");
      } else {
        await _localDb.updateSyncStatus(activity.id, 'synced');
        debugPrint("Logged activity remotely: ${activity.id}");
      }
    } catch (e) {
      debugPrint('API logActivity failed ($endpoint), remaining pending locally: $e');
    }
  }

  Future<void> syncPendingActivities() async {
    final pending = await _localDb.getPendingActivities();
    if (pending.isEmpty) return;
    
    debugPrint("Syncing ${pending.length} pending activities from local database...");

    for (var item in pending) {
      try {
        final Map<String, dynamic> dataToSend = Map.from(item);
        dataToSend.remove('syncStatus'); 
        dataToSend.remove('id'); 
        
        final type = item['type']?.toString().toLowerCase();
        final isWorkout = (type == 'workout' || type == 'hiit');
        final endpoint = isWorkout ? ApiConstants.workouts : ApiConstants.activities;

        // Map SQL fields to Backend fields if necessary
        if (isWorkout) {
          if (dataToSend.containsKey('duration')) {
            dataToSend['totalDuration'] = dataToSend['duration'];
          }
        }

        final response = await _dio.post(endpoint, data: dataToSend);
        
        final serverId = response.data['_id']?.toString() ?? response.data['id']?.toString();
        if (serverId != null) {
          await _localDb.updateSyncStatusAndId(item['id'], serverId, 'synced');
        } else {
          await _localDb.updateSyncStatus(item['id'], 'synced');
        }
        debugPrint("Successfully synced pending activity: ${item['id']} to $endpoint");
      } catch (e) {
        debugPrint("Failed to sync activity: ${item['id']} - $e");
        if (e is DioException && e.response?.statusCode == 401) {
          debugPrint("Sync halted: Unauthorized (401). Token might be expired.");
          break; // Stop the loop if unauthorized to avoid spamming API
        }
      }
    }
  }

  Future<void> saveWorkout(Workout workout) async {
    await logActivity(workout, customEndpoint: ApiConstants.workouts);
  }

  Future<List<Activity>> _getLocalActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(kActivityHistoryKey);
    if (historyJson == null) return [];
    final List<dynamic> decoded = jsonDecode(historyJson);
    return decoded.map((json) {
      if (json['type'] == 'workout') {
        return Workout.fromJson(json);
      }
      return Activity.fromJson(json);
    }).toList();
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
  final localDb = ref.watch(localDatabaseProvider);
  return ActivityRepository(dio, localDb);
});

final activityListProvider = FutureProvider<List<Activity>>((ref) async {
  final repository = ref.watch(activityRepositoryProvider);
  
  // 1. Fetch from Local Database first (Instant)
  final localActivities = await repository.getUserActivities(triggerSync: false);

  // 2. Trigger background sync
  // We don't await this to keep the UI responsive, especially on Android with potential network issues
  repository._fetchAndSyncRemote().then((didUpdate) {
    if (didUpdate) {
      // Invalidate the provider to refresh the UI with new data from local DB
      ref.invalidateSelf();
    }
  }).catchError((e) {
    debugPrint("Background activity sync error: $e");
  });

  return localActivities;
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

    // Also persist to SharedPreferences so workoutHistory fallback stays in sync
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(kWorkoutHistoryKey);
    final List<dynamic> list = existing != null ? jsonDecode(existing) : [];
    list.insert(0, workout.toJson());
    await prefs.setString(kWorkoutHistoryKey, jsonEncode(list));

    // Batch invalidate — all refresh in parallel
    ref.invalidate(userProfileProvider);
    ref.invalidate(activitySummaryProvider);
    ref.invalidate(activityListProvider);
    ref.invalidate(activityStatsProvider('week'));
    ref.invalidate(activityStatsProvider('month'));
    ref.invalidate(notificationsListProvider);
    ref.invalidate(unreadNotificationCountProvider);
    ref.invalidateSelf();
  }
}

final workoutHistoryProvider = AsyncNotifierProvider<WorkoutHistoryNotifier, List<Workout>>(
  () => WorkoutHistoryNotifier(),
);

