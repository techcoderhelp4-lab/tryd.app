import 'package:json_annotation/json_annotation.dart';

part 'activity.g.dart';

@JsonSerializable()
class Activity {
  final String id;
  final String type; // 'run', 'walk', 'cycling'
  final double distance; // km
  final int duration; // seconds
  final double calories;
  final DateTime date;

  Activity({
    required this.id,
    required this.type,
    required this.distance,
    required this.duration,
    required this.calories,
    required this.date,
  });

  factory Activity.fromJson(Map<String, dynamic> json) => _$ActivityFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityToJson(this);
}
