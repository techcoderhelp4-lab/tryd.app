import 'package:json_annotation/json_annotation.dart';

part 'reward.g.dart';

@JsonSerializable()
class Reward {
  final String id;
  final String title;
  final String description;
  final int requiredPoints;
  final String imageUrl;
  final String partner;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredPoints,
    required this.imageUrl,
    required this.partner,
  });

  factory Reward.fromJson(Map<String, dynamic> json) => _$RewardFromJson(json);
  Map<String, dynamic> toJson() => _$RewardToJson(this);
}
