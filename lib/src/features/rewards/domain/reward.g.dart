// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reward _$RewardFromJson(Map<String, dynamic> json) => Reward(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  requiredPoints: (json['requiredPoints'] as num).toInt(),
  imageUrl: json['imageUrl'] as String,
  partner: json['partner'] as String,
);

Map<String, dynamic> _$RewardToJson(Reward instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'requiredPoints': instance.requiredPoints,
  'imageUrl': instance.imageUrl,
  'partner': instance.partner,
};
