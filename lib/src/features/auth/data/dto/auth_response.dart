import 'package:json_annotation/json_annotation.dart';
import '../../domain/user.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponse {
  final bool success;
  final String? message;
  final String? accessToken;
  final String? refreshToken;
  final User? user;
  final int? grantedDownloadRewardPoints;
  final int? grantedReferralBonusPoints;

  AuthResponse({
    this.success = false,
    this.message,
    this.accessToken,
    this.refreshToken,
    this.user,
    this.grantedDownloadRewardPoints,
    this.grantedReferralBonusPoints,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

