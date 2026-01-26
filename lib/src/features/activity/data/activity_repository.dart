import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../domain/activity.dart';
import '../domain/workout.dart';

part 'activity_repository.g.dart';

class ActivityRepository {
  final Dio _dio;

  ActivityRepository(this._dio);

  Future<List<Activity>> getUserActivities() async {
    try {
      final response = await _dio.get(ApiConstants.activities);
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => Activity.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Activity> logActivity(Activity activity) async {
    try {
      final response = await _dio.post(
        ApiConstants.activities,
        data: activity.toJson(),
      );
      return Activity.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Workout>> getWorkoutHistory() async {
    try {
      final response = await _dio.get(ApiConstants.workouts);
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => Workout.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Workout> logWorkout(Workout workout) async {
    try {
      final response = await _dio.post(
        ApiConstants.workouts,
        data: workout.toJson(),
      );
      return Workout.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
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
Future<List<Workout>> workoutList(WorkoutListRef ref) {
  final repository = ref.watch(activityRepositoryProvider);
  return repository.getWorkoutHistory();
}
