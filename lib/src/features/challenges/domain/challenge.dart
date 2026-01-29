import 'package:json_annotation/json_annotation.dart';

part 'challenge.g.dart';

@JsonSerializable()
class Challenge {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final double targetKm;
  final int rewardPoints;
  final String? imageUrl;
  final bool isJoined;
  final double userProgress;
  final double progressPercentage;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.targetKm,
    required this.rewardPoints,
    this.imageUrl,
    this.isJoined = false,
    this.userProgress = 0,
    this.progressPercentage = 0,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : DateTime.now(),
      targetKm: (json['targetKm'] ?? 0).toDouble(),
      rewardPoints: (json['rewardPoints'] ?? 0).toInt(),
      imageUrl: json['imageUrl'],
      isJoined: json['isJoined'] ?? false,
      userProgress: (json['userProgress'] ?? json['completedKm'] ?? 0).toDouble(),
      progressPercentage: (json['progressPercentage'] ?? 0).toDouble(),
    );
  }
  Map<String, dynamic> toJson() => _$ChallengeToJson(this);
}
