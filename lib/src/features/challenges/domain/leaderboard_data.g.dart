// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaderboardData _$LeaderboardDataFromJson(Map<String, dynamic> json) =>
    LeaderboardData(
      leaderboard: (json['leaderboard'] as List<dynamic>)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentUserRank: (json['currentUserRank'] as num).toInt(),
      challenge: LeaderboardChallengeInfo.fromJson(
        json['challenge'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$LeaderboardDataToJson(LeaderboardData instance) =>
    <String, dynamic>{
      'leaderboard': instance.leaderboard,
      'currentUserRank': instance.currentUserRank,
      'challenge': instance.challenge,
    };

LeaderboardEntry _$LeaderboardEntryFromJson(Map<String, dynamic> json) =>
    LeaderboardEntry(
      rank: (json['rank'] as num).toInt(),
      user: LeaderboardUserInfo.fromJson(json['user'] as Map<String, dynamic>),
      completedKm: (json['completedKm'] as num).toDouble(),
      isCurrentUser: json['isCurrentUser'] as bool,
    );

Map<String, dynamic> _$LeaderboardEntryToJson(LeaderboardEntry instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'user': instance.user,
      'completedKm': instance.completedKm,
      'isCurrentUser': instance.isCurrentUser,
    };

LeaderboardUserInfo _$LeaderboardUserInfoFromJson(Map<String, dynamic> json) =>
    LeaderboardUserInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      profilePicture: json['profilePicture'] as String?,
    );

Map<String, dynamic> _$LeaderboardUserInfoToJson(
  LeaderboardUserInfo instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'profilePicture': instance.profilePicture,
};

LeaderboardChallengeInfo _$LeaderboardChallengeInfoFromJson(
  Map<String, dynamic> json,
) => LeaderboardChallengeInfo(
  title: json['title'] as String,
  targetKm: (json['targetKm'] as num).toDouble(),
  startDate: json['startDate'] == null
      ? null
      : DateTime.parse(json['startDate'] as String),
  endDate: json['endDate'] == null
      ? null
      : DateTime.parse(json['endDate'] as String),
  userProgress: (json['userProgress'] as num?)?.toDouble(),
  progressPercentage: (json['progressPercentage'] as num?)?.toDouble(),
);

Map<String, dynamic> _$LeaderboardChallengeInfoToJson(
  LeaderboardChallengeInfo instance,
) => <String, dynamic>{
  'title': instance.title,
  'targetKm': instance.targetKm,
  'startDate': instance.startDate?.toIso8601String(),
  'endDate': instance.endDate?.toIso8601String(),
  'userProgress': instance.userProgress,
  'progressPercentage': instance.progressPercentage,
};

