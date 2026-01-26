// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Workout _$WorkoutFromJson(Map<String, dynamic> json) => Workout(
  id: json['id'] as String,
  type: json['type'] as String,
  duration: (json['duration'] as num).toInt(),
  calories: (json['calories'] as num).toDouble(),
  date: DateTime.parse(json['date'] as String),
  distance: (json['distance'] as num?)?.toDouble(),
);

Map<String, dynamic> _$WorkoutToJson(Workout instance) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'duration': instance.duration,
  'calories': instance.calories,
  'date': instance.date.toIso8601String(),
  'distance': instance.distance,
};
