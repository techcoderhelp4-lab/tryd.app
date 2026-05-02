import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';

class ShareRewardRepository {
  const ShareRewardRepository(this._dio);
  final Dio _dio;

  Future<ShareRewardResult> claimReward(String platform) async {
    final response = await _dio.post(
      ApiConstants.shareReward,
      data: {'platform': platform},
    );
    return ShareRewardResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ShareRewardStatus> getStatus() async {
    final response = await _dio.get(ApiConstants.shareRewardStatus);
    return ShareRewardStatus.fromJson(response.data as Map<String, dynamic>);
  }
}

class ShareRewardResult {
  final bool alreadyRewarded;
  final int pointsAwarded;
  final String platform;
  final String message;

  const ShareRewardResult({
    required this.alreadyRewarded,
    required this.pointsAwarded,
    required this.platform,
    required this.message,
  });

  factory ShareRewardResult.fromJson(Map<String, dynamic> json) {
    return ShareRewardResult(
      alreadyRewarded: json['alreadyRewarded'] as bool? ?? false,
      pointsAwarded: (json['pointsAwarded'] as num?)?.toInt() ?? 0,
      platform: json['platform'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

class ShareRewardStatus {
  final int sharePoints;
  final List<String> claimedToday;
  final List<String> platforms;

  const ShareRewardStatus({
    required this.sharePoints,
    required this.claimedToday,
    required this.platforms,
  });

  factory ShareRewardStatus.fromJson(Map<String, dynamic> json) {
    return ShareRewardStatus(
      sharePoints: (json['sharePoints'] as num?)?.toInt() ?? 10,
      claimedToday: List<String>.from(json['claimedToday'] as List? ?? []),
      platforms: List<String>.from(json['platforms'] as List? ?? []),
    );
  }

  bool isClaimed(String platform) => claimedToday.contains(platform.toLowerCase());
}

final shareRewardRepositoryProvider = Provider<ShareRewardRepository>((ref) {
  return ShareRewardRepository(ref.watch(apiClientProvider));
});

final shareRewardStatusProvider = FutureProvider<ShareRewardStatus>((ref) {
  return ref.watch(shareRewardRepositoryProvider).getStatus();
});

