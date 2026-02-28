import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/database/local_database.dart';
import '../../activity/data/activity_repository.dart';
import '../../auth/domain/user.dart';
import 'package:flutter/foundation.dart';

const _kUserCacheKey = 'cached_user_profile';
const _kActivitySummaryCacheKey = 'cached_activity_summary_';

class UserRepository {
  final Dio _dio;
  final LocalDatabase _localDb;

  UserRepository(this._dio, this._localDb);

  Future<User> getProfile() async {
    try {
      final response = await _dio.get(ApiConstants.profile);
      final user = User.fromJson(response.data);

      // Cache the profile for instant loading next time
      _cacheUserProfile(response.data);

      return user;
    } catch (e) {
      // Try loading from cache first
      final cached = await _getCachedUserProfile();
      if (cached != null) return cached;

      if (e is DioException && (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout)) {
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

  Future<void> _cacheUserProfile(dynamic data) async {
    try {
      await _localDb.setKV(_kUserCacheKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<User?> _getCachedUserProfile() async {
    try {
      final json = await _localDb.getKV(_kUserCacheKey);
      if (json == null) return null;
      return User.fromJson(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  Future<User> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        ApiConstants.updateProfile,
        data: data,
      );
      final user = User.fromJson(response.data['user']);

      // Cache the updated profile immediately
      _cacheUserProfile(response.data['user']);

      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User> uploadProfilePicture(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'profilePicture': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        ApiConstants.uploadProfilePicture,
        data: formData,
      );

      debugPrint('Upload response: ${response.data}');

      // Check if response has user data
      if (response.data == null) {
        throw Exception('No data in response');
      }

      if (response.data['user'] == null) {
        throw Exception('No user data in response');
      }

      // Get the updated user from response and cache it
      final userData = response.data['user'];
      debugPrint('User data: $userData');

      final user = User.fromJson(userData);
      _cacheUserProfile(userData);

      return user;
    } catch (e) {
      debugPrint('Upload error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getActivitySummary({String period = 'week', Ref? ref}) async {
    try {
      final response = await _dio.get(
        ApiConstants.activitySummary,
        queryParameters: {'period': period},
      );

      final rawData = response.data as Map<String, dynamic>;

      // Normalize data for the UI (Handle both flat and nested 'summary' structures)
      final source = rawData.containsKey('summary') ? rawData['summary'] : rawData;

      final normalized = {
        'distance': (source['distance'] ?? source['totalDistance'] ?? 0.0) as num,
        'duration': (source['duration'] ?? source['totalDuration'] ?? 0) as num,
        'calories': (source['calories'] ?? source['totalCalories'] ?? source['caloriesBurned'] ?? 0.0) as num,
        'steps': (source['steps'] ?? source['totalSteps'] ?? ((source['distance'] ?? source['totalDistance'] ?? 0.0) * 1312).toInt()) as num,
        'bpm': (source['bpm'] ?? source['averageBPM'] ?? 0.0) as num,
      };

      // Cache the normalized summary
      _cacheActivitySummary(period, normalized);

      return normalized;
    } catch (e) {
      // API Failed: Prioritize Local Database (Fresh Reality) over Cache (Stale History)
      if (ref != null) {
        try {
          final activityRepo = ref.read(activityRepositoryProvider);
          final stats = await activityRepo.getActivityStats(period: period);

          final Map<String, dynamic> localSummary = {
            'distance': stats.totalDistance,
            'duration': stats.totalDuration,
            'calories': stats.totalCalories,
            'steps': (stats.totalDistance * 1312).toInt(),
            'bpm': stats.averageBPM,
          };

          // Update cache with these fresh local stats
          _cacheActivitySummary(period, localSummary);
          return localSummary;
        } catch (innerError) {
          debugPrint("Local aggregate fallback failed: $innerError");
        }
      }

      // Last resort: Stale cache
      final cached = await _getCachedActivitySummary(period);
      if (cached != null) return cached;

      return {
        'distance': 0.0,
        'duration': 0,
        'calories': 0.0,
        'steps': 0,
        'bpm': 0.0,
      };
    }
  }

  Future<void> _cacheActivitySummary(String period, dynamic data) async {
    try {
      await _localDb.setKV('$_kActivitySummaryCacheKey$period', jsonEncode(data));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _getCachedActivitySummary(String period) async {
    try {
      final json = await _localDb.getKV('$_kActivitySummaryCacheKey$period');
      if (json == null) return null;
      return Map<String, dynamic>.from(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }
}

// ── Manual providers (keepAlive — no re-fetch on revisit) ──

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  final localDb = ref.watch(localDatabaseProvider);
  return UserRepository(dio, localDb);
});

final userProfileProvider = FutureProvider<User>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getProfile();
});

final activitySummaryProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, period) {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getActivitySummary(period: period, ref: ref);
});
