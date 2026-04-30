import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/database/local_database.dart';
import '../domain/challenge.dart';
import '../domain/leaderboard_data.dart';
import 'package:flutter/foundation.dart';

class ChallengeRepository {
  final Dio _dio;
  final LocalDatabase _localDb;

  // Debounce sync to prevent infinite provider loops
  DateTime? _lastChallengesSync;
  final Map<String, DateTime> _lastLeaderboardSync = {};
  static const _syncDebounce = Duration(seconds: 10);

  ChallengeRepository(this._dio, this._localDb);

  // ── Challenges List ─────────────────────────────────────

  Future<List<Challenge>> getChallenges({bool triggerSync = true}) async {
    final localData = await _localDb.getChallenges();
    final List<Challenge> localChallenges = localData.map((json) {
      final map = Map<String, dynamic>.from(json);
      map['isJoined'] = map['isJoined'] == 1;
      return Challenge.fromJson(map);
    }).toList();

    if (triggerSync) {
      fetchAndSyncChallenges();
    }

    return localChallenges;
  }

  /// Fetches from remote and updates local DB.
  /// Returns true if data was fetched (triggers UI refresh).
  /// Debounced to prevent rapid re-fetching. Use [force] to bypass.
  Future<bool> fetchAndSyncChallenges({bool force = false}) async {
    if (!force && _lastChallengesSync != null &&
        DateTime.now().difference(_lastChallengesSync!) < _syncDebounce) {
      return false;
    }

    try {
      final response = await _dio.get(ApiConstants.challenges);
      final data = response.data;

      List<Challenge> allChallenges = [];

      if (data is Map<String, dynamic>) {
        if (data['myChallenges'] is List) {
          allChallenges.addAll((data['myChallenges'] as List).map((json) {
            final map = Map<String, dynamic>.from(json);
            map['isJoined'] = true;
            return Challenge.fromJson(map);
          }));
        }

        if (data['joinChallenges'] is List) {
          allChallenges.addAll((data['joinChallenges'] as List).map((json) {
            final map = Map<String, dynamic>.from(json);
            map['isJoined'] = false;
            return Challenge.fromJson(map);
          }));
        }

        // Ended challenges visible to everyone regardless of join status
        if (data['previousChallenges'] is List) {
          allChallenges.addAll((data['previousChallenges'] as List).map((json) {
            final map = Map<String, dynamic>.from(json);
            map['isJoined'] = false;
            return Challenge.fromJson(map);
          }));
        }

        if (allChallenges.isEmpty && data['data'] is List) {
          allChallenges.addAll((data['data'] as List).map((json) => Challenge.fromJson(json)));
        }
      } else if (data is List) {
        allChallenges.addAll(data.map((json) => Challenge.fromJson(json)));
      }

      final List<Map<String, dynamic>> challengesToSave = allChallenges.map((c) {
        final json = c.toJson();
        json['id'] = c.id;
        json['isJoined'] = c.isJoined ? 1 : 0;
        return json;
      }).toList();

      await _localDb.saveChallenges(challengesToSave);
      _lastChallengesSync = DateTime.now();
      return true;
    } catch (e) {
      debugPrint("Challenges remote sync failed: $e");
      return false;
    }
  }

  // ── Challenge Details (local-first) ─────────────────────

  /// Returns challenge from local DB instantly, or null if not cached.
  Future<Challenge?> getChallengeDetailsLocal(String id) async {
    final localData = await _localDb.getChallenges();
    final match = localData.where((c) => c['id'] == id).toList();
    if (match.isNotEmpty) {
      final map = Map<String, dynamic>.from(match.first);
      map['isJoined'] = map['isJoined'] == 1;
      return Challenge.fromJson(map);
    }
    return null;
  }

  /// Returns local data instantly if available, otherwise fetches from API.
  Future<Challenge> getChallengeDetails(String id) async {
    final local = await getChallengeDetailsLocal(id);
    if (local != null) return local;

    final response = await _dio.get(ApiConstants.challengeDetails(id));
    return Challenge.fromJson(response.data);
  }

  /// Fetches fresh challenge detail from API and updates local DB.
  Future<Challenge?> syncChallengeDetail(String id) async {
    try {
      final response = await _dio.get(ApiConstants.challengeDetails(id));
      final challenge = Challenge.fromJson(response.data);
      final json = challenge.toJson();
      json['id'] = challenge.id;
      json['isJoined'] = challenge.isJoined ? 1 : 0;
      await _localDb.saveChallenges([json]);
      return challenge;
    } catch (e) {
      debugPrint("Challenge detail sync failed: $e");
      return null;
    }
  }

  // ── Leaderboard (cached in kv_store) ────────────────────

  /// Returns cached leaderboard from local kv_store, or null.
  Future<LeaderboardData?> getCachedLeaderboard(String id) async {
    try {
      final cached = await _localDb.getKV('leaderboard_$id');
      if (cached != null) {
        return LeaderboardData.fromJson(jsonDecode(cached));
      }
    } catch (e) {
      debugPrint("Leaderboard cache read failed: $e");
    }
    return null;
  }

  /// Fetches leaderboard from API and caches it locally.
  Future<LeaderboardData> fetchAndCacheLeaderboard(String id, {bool force = false}) async {
    if (!force && _lastLeaderboardSync.containsKey(id) &&
        DateTime.now().difference(_lastLeaderboardSync[id]!) < _syncDebounce) {
      final cached = await getCachedLeaderboard(id);
      if (cached != null) return cached;
    }

    final response = await _dio.get(ApiConstants.challengeLeaderboard(id));
    final data = LeaderboardData.fromJson(response.data);
    _lastLeaderboardSync[id] = DateTime.now();
    try {
      await _localDb.setKV('leaderboard_$id', jsonEncode(data.toJson()));
    } catch (_) {}
    return data;
  }

  Future<LeaderboardData> getLeaderboard(String id) async {
    return fetchAndCacheLeaderboard(id);
  }

  // ── Join Challenge ──────────────────────────────────────

  Future<void> joinChallenge(String id) async {
    // 1. Optimistic local update
    final localData = await _localDb.getChallenges();
    final challengeJson = localData.firstWhere((c) => c['id'] == id, orElse: () => {});
    if (challengeJson.isNotEmpty) {
      final Map<String, dynamic> updated = Map.from(challengeJson);
      updated['isJoined'] = 1;
      await _localDb.saveChallenges([updated]);
    }

    // 2. Queue for background sync
    await _localDb.enqueueAction(ApiConstants.joinChallenge(id), 'POST', {});

    // Try immediate sync
    try {
      await _dio.post(ApiConstants.joinChallenge(id));
    } catch (_) {}
  }

  // ── Progress Updates ────────────────────────────────────

  Future<Map<String, dynamic>> updateChallengeProgress({
    required String challengeId,
    required double distanceKm,
    required int durationSeconds,
    required double calories,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.challengeProgress(challengeId),
        data: {
          'distance': distanceKm,
          'duration': durationSeconds,
          'calories': calories,
        },
      );
      return response.data is Map<String, dynamic>
          ? response.data
          : {'success': true};
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAllChallengesProgress({
    required double distanceKm,
    required int durationSeconds,
    required double calories,
  }) async {
    try {
      final challenges = await getChallenges();
      final now = DateTime.now();
      final activeChallenges = challenges.where((c) => c.isJoined && c.startDate.isBefore(now) && c.endDate.isAfter(now)).toList();

      for (final challenge in activeChallenges) {
        try {
          await updateChallengeProgress(
            challengeId: challenge.id,
            distanceKm: distanceKm,
            durationSeconds: durationSeconds,
            calories: calories,
          );
        } catch (e) {
          print('Failed to update challenge ${challenge.id}: $e');
        }
      }
    } catch (e) {
      print('Error fetching challenges for progress update: $e');
    }
  }
}

// ── Providers ──────────────────────────────────────────────

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  final localDb = ref.watch(localDatabaseProvider);
  return ChallengeRepository(dio, localDb);
});

/// Challenges list: returns local data instantly, syncs in background.
/// Debounced sync prevents infinite invalidation loops.
final challengesListProvider = FutureProvider<List<Challenge>>((ref) async {
  final repository = ref.watch(challengeRepositoryProvider);

  // 1. Get local data first (instant)
  final localData = await repository.getChallenges(triggerSync: false);

  // 2. Background sync (debounced — won't re-trigger within 10s)
  repository.fetchAndSyncChallenges().then((didUpdate) {
    if (didUpdate) {
      Future.delayed(const Duration(milliseconds: 100), () {
        ref.invalidateSelf();
      });
    }
  });

  return localData;
});

/// Challenge details: local-first from SQLite, background API sync.
final challengeDetailsProvider = FutureProvider.family<Challenge, String>((ref, id) async {
  final repository = ref.watch(challengeRepositoryProvider);

  // Return local data instantly
  final local = await repository.getChallengeDetailsLocal(id);

  // Background sync (fire-and-forget, updates local DB for next access)
  repository.syncChallengeDetail(id);

  if (local != null) return local;

  // No local data — fallback to API
  return repository.getChallengeDetails(id);
});

/// Leaderboard: returns cached data instantly if available,
/// fetches fresh in background. Falls back to API if no cache.
final challengeLeaderboardProvider = FutureProvider.family<LeaderboardData, String>((ref, id) async {
  final repository = ref.watch(challengeRepositoryProvider);

  // Try cache first for instant display
  final cached = await repository.getCachedLeaderboard(id);

  if (cached != null) {
    // Background refresh (debounced)
    repository.fetchAndCacheLeaderboard(id).then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        ref.invalidateSelf();
      });
    }).catchError((_) {});
    return cached;
  }

  // No cache — fetch from API (first visit)
  return repository.getLeaderboard(id);
});
