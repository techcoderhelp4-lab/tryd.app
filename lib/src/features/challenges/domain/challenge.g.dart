// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Challenge _$ChallengeFromJson(Map<String, dynamic> json) => Challenge(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  targetKm: (json['targetKm'] as num).toDouble(),
  rewardPoints: (json['rewardPoints'] as num).toInt(),
  imageUrl: json['imageUrl'] as String?,
  isJoined: json['isJoined'] as bool? ?? false,
);

Map<String, dynamic> _$ChallengeToJson(Challenge instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
  'targetKm': instance.targetKm,
  'rewardPoints': instance.rewardPoints,
  'imageUrl': instance.imageUrl,
  'isJoined': instance.isJoined,
};
