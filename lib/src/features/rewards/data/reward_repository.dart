import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../domain/reward.dart';
import '../domain/redemption.dart';

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return RewardRepository(dio);
});

class RewardRepository {
  final Dio _dio;

  RewardRepository(this._dio);

  Future<List<Reward>> getRewards({String? category}) async {
    try {
      final response = await _dio.get(
        ApiConstants.rewards,
        queryParameters: category != null && category != 'All' ? {'category': category.toLowerCase()} : null,
      );
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => Reward.fromJson(json)).toList();
    } catch (e) {
      // Fallback to mock data for demonstration purposes or when API is unavailable
      return [
        Reward(
          id: '1',
          title: 'Free Coffee',
          description: 'Get a free coffee of your choice.',
          requiredPoints: 500,
          imageUrl: 'https://images.unsplash.com/photo-1509042239263-09126823f45a?auto=format&fit=crop&q=80&w=200',
          partner: 'Starbucks',
          category: 'coffee',
          requiresApproval: false,
        ),
        Reward(
          id: '2',
          title: '20% Off Sportswear',
          description: 'Get 20% discount on any sportswear item.',
          requiredPoints: 1500,
          imageUrl: 'https://images.unsplash.com/photo-1556906781-9a412961c28c?auto=format&fit=crop&q=80&w=200',
          partner: 'Adidas',
          category: 'shop',
          requiresApproval: false,
        ),
        Reward(
          id: '3',
          title: 'Gym Membership',
          description: '1 month free gym membership.',
          requiredPoints: 5000,
          imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&q=80&w=200',
          partner: 'Gold\'s Gym',
          category: 'gym',
          requiresApproval: true,
        ),
      ];
    }
  }

  Future<void> redeemReward(String id) async {
    try {
      await _dio.post(ApiConstants.redeemReward(id));
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Redemption>> getMyRedemptions() async {
    try {
       final response = await _dio.get(ApiConstants.myRedemptions);
       final List<dynamic> data = response.data['data'] ?? response.data;
       return data.map((json) => Redemption.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}

final rewardsListProvider = FutureProvider<List<Reward>>((ref) {
  final repository = ref.watch(rewardRepositoryProvider);
  return repository.getRewards();
});

final filteredRewardsProvider = FutureProvider.family<List<Reward>, String?>((ref, category) {
  final repository = ref.watch(rewardRepositoryProvider);
  return repository.getRewards(category: category);
});

final myRedemptionsProvider = FutureProvider<List<Redemption>>((ref) {
  final repository = ref.watch(rewardRepositoryProvider);
  return repository.getMyRedemptions();
});
