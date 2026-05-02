import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';

class ReferralInfo {
  final String? referralCode;
  final int referralCount;
  final int pointsPerReferral;

  const ReferralInfo({
    required this.referralCode,
    required this.referralCount,
    required this.pointsPerReferral,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) => ReferralInfo(
        referralCode: json['referralCode'] as String?,
        referralCount: (json['referralCount'] as num?)?.toInt() ?? 0,
        pointsPerReferral: (json['pointsPerReferral'] as num?)?.toInt() ?? 20,
      );
}

class ReferralRepository {
  const ReferralRepository(this._dio);

  final Dio _dio;

  Future<ReferralInfo> getMyReferralInfo() async {
    final response = await _dio.get(ApiConstants.myReferralInfo);
    return ReferralInfo.fromJson(response.data as Map<String, dynamic>);
  }
}

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return ReferralRepository(dio);
});

final myReferralInfoProvider = FutureProvider<ReferralInfo>((ref) {
  return ref.watch(referralRepositoryProvider).getMyReferralInfo();
});

