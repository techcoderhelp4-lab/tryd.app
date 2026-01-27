import 'package:json_annotation/json_annotation.dart';

part 'workout.g.dart';

@JsonSerializable()
class Workout {
  final String id;
  final String type;
  final int duration; // total seconds
  final double calories;
  final DateTime date;
  final double? distance;
  
  // HIIT/Interval specific
  final int? exercises;
  final int? rounds;
  final int? workDuration;
  final int? restDuration;

  Workout({
    required this.id,
    required this.type,
    required this.duration,
    required this.calories,
    required this.date,
    this.distance,
    this.exercises,
    this.rounds,
    this.workDuration,
    this.restDuration,
  });

  factory Workout.fromJson(Map<String, dynamic> json) => _$WorkoutFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutToJson(this);
}
