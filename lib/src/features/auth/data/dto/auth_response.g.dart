// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  success: json['success'] as bool? ?? false,
  message: json['message'] as String?,
  accessToken: json['accessToken'] as String?,
  refreshToken: json['refreshToken'] as String?,
  user: json['user'] == null
      ? null
      : User.fromJson(json['user'] as Map<String, dynamic>),
  grantedDownloadRewardPoints: (json['grantedDownloadRewardPoints'] as num?)?.toInt(),
  grantedReferralBonusPoints: (json['grantedReferralBonusPoints'] as num?)?.toInt(),
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'user': instance.user,
      'grantedDownloadRewardPoints': instance.grantedDownloadRewardPoints,
      'grantedReferralBonusPoints': instance.grantedReferralBonusPoints,
    };
