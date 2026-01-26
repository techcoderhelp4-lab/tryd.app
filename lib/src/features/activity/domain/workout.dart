import 'package:json_annotation/json_annotation.dart';

part 'workout.g.dart';

@JsonSerializable()
class Workout {
  final String id;
  final String type;
  final int duration; // minutes
  final double calories;
  final DateTime date;
  final double? distance;

  Workout({
    required this.id,
    required this.type,
    required this.duration,
    required this.calories,
    required this.date,
    this.distance,
  });

  factory Workout.fromJson(Map<String, dynamic> json) => _$WorkoutFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutToJson(this);
}
