import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../domain/reward.dart';

part 'reward_repository.g.dart';

class RewardRepository {
  final Dio _dio;

  RewardRepository(this._dio);

  Future<List<Reward>> getRewards() async {
    try {
      final response = await _dio.get(ApiConstants.rewards);
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
          imageUrl: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&q=80&w=200',
          partner: 'Starbucks',
        ),
        Reward(
          id: '2',
          title: '20% Off Sportswear',
          description: 'Get 20% discount on any sportswear item.',
          requiredPoints: 1500,
          imageUrl: 'https://images.unsplash.com/photo-1576185850227-1f72b7f9d683?auto=format&fit=crop&q=80&w=200',
          partner: 'Adidas',
        ),
        Reward(
          id: '3',
          title: 'Gym Membership',
          description: '1 month free gym membership.',
          requiredPoints: 5000,
          imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&q=80&w=200',
          partner: 'Gold\'s Gym',
        ),
        Reward(
          id: '4',
          title: 'Healthy Meal',
          description: 'A free healthy meal from our menu.',
          requiredPoints: 800,
          imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=200',
          partner: 'Green Eats',
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

  Future<List<dynamic>> getMyRedemptions() async {
    try {
       final response = await _dio.get(ApiConstants.myRedemptions);
       return response.data['data'] ?? response.data;
    } catch (e) {
      rethrow;
    }
  }
}

@riverpod
RewardRepository rewardRepository(RewardRepositoryRef ref) {
  final dio = ref.watch(apiClientProvider);
  return RewardRepository(dio);
}

@riverpod
Future<List<Reward>> rewardsList(RewardsListRef ref) {
  final repository = ref.watch(rewardRepositoryProvider);
  return repository.getRewards();
}
