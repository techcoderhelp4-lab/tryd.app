import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../domain/challenge.dart';

part 'challenge_repository.g.dart';

class ChallengeRepository {
  final Dio _dio;

  ChallengeRepository(this._dio);

  Future<List<Challenge>> getChallenges() async {
    try {
      final response = await _dio.get(ApiConstants.challenges);
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => Challenge.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Challenge> getChallengeDetails(String id) async {
    try {
      final response = await _dio.get(ApiConstants.challengeDetails(id));
      return Challenge.fromJson(response.data);
    } catch (e) {
      // Fallback mock data for development
      return Challenge(
        id: id,
        title: 'End March 160 KM Challenge',
        description: 'Push your limits with this 160km endurance challenge! Join thousands of other runners in this month-long event found to help you stay consistent and reach new fitness heights.',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 22)),
        targetKm: 160.0,
        rewardPoints: 10000,
        imageUrl: 'assets/images/running.png',
        isJoined: false,
      );
    }
  }

  Future<void> joinChallenge(String id) async {
    try {
      await _dio.post(ApiConstants.joinChallenge(id));
    } catch (e) {
      rethrow;
    }
  }
}

@riverpod
ChallengeRepository challengeRepository(ChallengeRepositoryRef ref) {
  final dio = ref.watch(apiClientProvider);
  return ChallengeRepository(dio);
}

@riverpod
Future<List<Challenge>> challengesList(ChallengesListRef ref) {
  final repository = ref.watch(challengeRepositoryProvider);
  return repository.getChallenges();
}

@riverpod
Future<Challenge> challengeDetails(ChallengeDetailsRef ref, String id) {
  final repository = ref.watch(challengeRepositoryProvider);
  return repository.getChallengeDetails(id);
}
