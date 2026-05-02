import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../domain/workout.dart';

class PreBuiltWorkoutRepository {
  final Dio _client;
  PreBuiltWorkoutRepository(this._client);

  Future<List<PreBuiltWorkout>> getPreBuiltWorkouts() async {
    try {
      final response = await _client.get(ApiConstants.preBuiltWorkouts);
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['workouts'] as List<dynamic>;
        return list.map((e) => PreBuiltWorkout.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

final preBuiltWorkoutRepositoryProvider = Provider<PreBuiltWorkoutRepository>((ref) {
  return PreBuiltWorkoutRepository(ref.watch(apiClientProvider));
});

final preBuiltWorkoutsProvider = FutureProvider<List<PreBuiltWorkout>>((ref) async {
  return ref.watch(preBuiltWorkoutRepositoryProvider).getPreBuiltWorkouts();
});

