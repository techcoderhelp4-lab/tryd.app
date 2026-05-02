import 'package:json_annotation/json_annotation.dart';

part 'leaderboard_data.g.dart';

@JsonSerializable()
class LeaderboardData {
  final List<LeaderboardEntry> leaderboard;
  final int currentUserRank;
  final LeaderboardChallengeInfo challenge;

  LeaderboardData({
    required this.leaderboard,
    required this.currentUserRank,
    required this.challenge,
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> json) => _$LeaderboardDataFromJson(json);
  Map<String, dynamic> toJson() => _$LeaderboardDataToJson(this);
}

@JsonSerializable()
class LeaderboardEntry {
  final int rank;
  final LeaderboardUserInfo user;
  final double completedKm;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.user,
    required this.completedKm,
    required this.isCurrentUser,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => _$LeaderboardEntryFromJson(json);
  Map<String, dynamic> toJson() => _$LeaderboardEntryToJson(this);
}

@JsonSerializable()
class LeaderboardUserInfo {
  final String id;
  final String name;
  final String? profilePicture;

  LeaderboardUserInfo({
    required this.id,
    required this.name,
    this.profilePicture,
  });

  factory LeaderboardUserInfo.fromJson(Map<String, dynamic> json) {
    return LeaderboardUserInfo(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] ?? '',
      profilePicture: json['profilePicture'],
    );
  }
  Map<String, dynamic> toJson() => _$LeaderboardUserInfoToJson(this);
}

@JsonSerializable()
class LeaderboardChallengeInfo {
  final String title;
  final double targetKm;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? userProgress;
  final double? progressPercentage;

  LeaderboardChallengeInfo({
    required this.title,
    required this.targetKm,
    this.startDate,
    this.endDate,
    this.userProgress,
    this.progressPercentage,
  });

  factory LeaderboardChallengeInfo.fromJson(Map<String, dynamic> json) {
    return LeaderboardChallengeInfo(
      title: json['title'] ?? '',
      targetKm: (json['targetKm'] ?? 0).toDouble(),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      userProgress: (json['userProgress'] ?? 0).toDouble(),
      progressPercentage: (json['progressPercentage'] ?? 0).toDouble(),
    );
  }
  Map<String, dynamic> toJson() => _$LeaderboardChallengeInfoToJson(this);
}

