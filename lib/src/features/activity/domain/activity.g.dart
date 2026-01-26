// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Activity _$ActivityFromJson(Map<String, dynamic> json) => Activity(
  id: json['id'] as String,
  type: json['type'] as String,
  distance: (json['distance'] as num).toDouble(),
  duration: (json['duration'] as num).toInt(),
  calories: (json['calories'] as num).toDouble(),
  date: DateTime.parse(json['date'] as String),
);

Map<String, dynamic> _$ActivityToJson(Activity instance) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'distance': instance.distance,
  'duration': instance.duration,
  'calories': instance.calories,
  'date': instance.date.toIso8601String(),
};
