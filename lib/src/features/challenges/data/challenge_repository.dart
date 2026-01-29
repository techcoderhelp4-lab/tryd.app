import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../domain/challenge.dart';
import '../domain/leaderboard_data.dart';

part 'challenge_repository.g.dart';

class ChallengeRepository {
  final Dio _dio;

  ChallengeRepository(this._dio);

  Future<List<Challenge>> getChallenges() async {
    try {
      final response = await _dio.get(ApiConstants.challenges);
      final data = response.data;
      
      List<Challenge> allChallenges = [];
      
      if (data is Map<String, dynamic>) {
        if (data.containsKey('myChallenges') && data['myChallenges'] is List) {
          final List<dynamic> my = data['myChallenges'];
          allChallenges.addAll(my.map((json) {
            final map = Map<String, dynamic>.from(json);
            map['isJoined'] = true;
            return Challenge.fromJson(map);
          }));
        }
        
        if (data.containsKey('joinChallenges') && data['joinChallenges'] is List) {
          final List<dynamic> join = data['joinChallenges'];
          allChallenges.addAll(join.map((json) {
            final map = Map<String, dynamic>.from(json);
            map['isJoined'] = false;
            return Challenge.fromJson(map);
          }));
        }

        // Fallback for old/other format
        if (allChallenges.isEmpty && data.containsKey('data') && data['data'] is List) {
          final List<dynamic> raw = data['data'];
          allChallenges.addAll(raw.map((json) => Challenge.fromJson(json)));
        }
      } else if (data is List) {
        allChallenges.addAll(data.map((json) => Challenge.fromJson(json)));
      }
      
      return allChallenges;
    } catch (e) {
      rethrow;
    }
  }

  Future<Challenge> getChallengeDetails(String id) async {
    try {
      final response = await _dio.get(ApiConstants.challengeDetails(id));
      return Challenge.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> joinChallenge(String id) async {
    try {
      await _dio.post(ApiConstants.joinChallenge(id));
    } catch (e) {
      rethrow;
    }
  }

  Future<LeaderboardData> getLeaderboard(String id) async {
    try {
      final response = await _dio.get(ApiConstants.challengeLeaderboard(id));
      return LeaderboardData.fromJson(response.data);
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

@riverpod
Future<LeaderboardData> challengeLeaderboard(ChallengeLeaderboardRef ref, String id) {
  final repository = ref.watch(challengeRepositoryProvider);
  return repository.getLeaderboard(id);
}
