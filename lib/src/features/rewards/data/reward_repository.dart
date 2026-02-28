import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/database/local_database.dart';
import '../domain/reward.dart';
import '../domain/redemption.dart';
import 'package:flutter/foundation.dart';

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  final localDb = ref.watch(localDatabaseProvider);
  return RewardRepository(dio, localDb);
});

class RewardRepository {
  final Dio _dio;
  final LocalDatabase _localDb;

  RewardRepository(this._dio, this._localDb);

  Future<List<Reward>> getRewards() async {
    try {
      final response = await _dio.get(ApiConstants.rewards);
      final dynamic rawData = response.data;
      final List<dynamic> data;
      if (rawData is List) {
        data = rawData;
      } else if (rawData is Map) {
        data = rawData['data'] is List ? rawData['data'] : [];
      } else {
        data = [];
      }
      
      final rewards = data.map((json) => Reward.fromJson(json)).toList();
      
      // Cache for offline use
      final List<Map<String, dynamic>> toCache = rewards.map((r) {
        final json = r.toJson();
        json['requiresApproval'] = r.requiresApproval == true ? 1 : 0;
        return json;
      }).toList();
      await _localDb.saveRewards(toCache);

      return rewards;
    } catch (e) {
      debugPrint("Failed to fetch rewards: $e");
      // Fallback to local DB
      final localData = await _localDb.getRewards();
      List<Reward> localRewards = localData.map((json) {
        final map = Map<String, dynamic>.from(json);
        map['requiresApproval'] = map['requiresApproval'] == 1;
        return Reward.fromJson(map);
      }).toList();
      return localRewards;
    }
  }

  Future<void> redeemReward(String id) async {
    try {
      final response = await _dio.post(ApiConstants.redeemReward(id));
      debugPrint("Redemption success: ${response.data}");
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? e.response?.data['message'] ?? 'Redemption failed'
          : 'Redemption failed';
      throw Exception(message);
    } catch (e) {
      debugPrint("Redemption failed: $e");
      rethrow;
    }
  }

  Future<List<Redemption>> getMyRedemptions() async {
    try {
       final response = await _dio.get(ApiConstants.myRedemptions);
       final dynamic rawData = response.data;
       final List<dynamic> data = (rawData is List) ? rawData : (rawData['data'] ?? []);
       return data.map((json) => Redemption.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Failed to fetch redemptions: $e");
      return [];
    }
  }
}

// Fetches ALL rewards once — used as the single source of truth
final rewardsListProvider = FutureProvider<List<Reward>>((ref) async {
  final repository = ref.watch(rewardRepositoryProvider);
  return repository.getRewards();
});

// Filters locally from the already-fetched list — no extra API call, no shimmer
final filteredRewardsProvider = Provider.family<AsyncValue<List<Reward>>, String?>((ref, category) {
  final allRewards = ref.watch(rewardsListProvider);
  return allRewards.whenData((rewards) {
    if (category == null || category == 'All') return rewards;
    return rewards.where((r) => r.category.toLowerCase() == category.toLowerCase()).toList();
  });
});

final myRedemptionsProvider = FutureProvider<List<Redemption>>((ref) {
  final repository = ref.watch(rewardRepositoryProvider);
  return repository.getMyRedemptions();
});
