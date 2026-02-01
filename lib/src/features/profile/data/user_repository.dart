import 'dart:io';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../activity/data/activity_repository.dart';
import '../../activity/domain/activity.dart';
import '../../auth/domain/user.dart';

part 'user_repository.g.dart';

class UserRepository {
  final Dio _dio;

  UserRepository(this._dio);

  Future<User> getProfile() async {
    try {
      final response = await _dio.get(ApiConstants.profile);
      return User.fromJson(response.data);
    } catch (e) {
      if (e is DioException && (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout)) {
        // Fallback to mock data for development if API is unreachable
        return User(
          id: '1',
          name: 'User',
          email: 'user@example.com',
          profilePicture: null,
        );
      }
      rethrow;
    }
  }

  Future<User> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        ApiConstants.updateProfile,
        data: data,
      );
      return User.fromJson(response.data['user']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadProfilePicture(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'profilePicture': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      await _dio.post(
        ApiConstants.uploadProfilePicture,
        data: formData,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getActivitySummary({String period = 'week', Ref? ref}) async {
    try {
      final response = await _dio.get(
        ApiConstants.activitySummary,
        queryParameters: {'period': period},
      );
      return response.data;
    } catch (e) {
      if (ref != null) {
        // Fallback to local calculation using ActivityRepository
        final activityRepo = ref.read(activityRepositoryProvider);
        final stats = await activityRepo.getActivityStats(period: period);
        
        // Match the Map structure expected by the Home Screen
        return {
          'distance': stats.totalDistance,
          'duration': stats.totalDuration,
          'calories': stats.totalCalories,
          'steps': (stats.totalDistance * 1312).toInt(), // More realistic heuristic (avg steps per km)
          'bpm': stats.averageBPM,
        };
      }
      return {
        'distance': 0.0,
        'duration': 0,
        'calories': 0.0,
        'steps': 0,
        'bpm': 0.0,
      };
    }
  }
}

@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  final dio = ref.watch(apiClientProvider);
  return UserRepository(dio);
}

@riverpod
Future<User> userProfile(UserProfileRef ref) {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getProfile();
}

final activitySummaryProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, period) {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getActivitySummary(period: period, ref: ref);
});
