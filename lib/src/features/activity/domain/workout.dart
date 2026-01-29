import 'activity.dart';

class Workout extends Activity {
  // HIIT/Interval specific
  final int? exercises;
  final int? rounds;
  final int? workDuration;
  final int? restDuration;

  Workout({
    required super.id,
    required super.type,
    required super.duration,
    required super.calories,
    required super.date,
    super.averagePace,
    super.averageBPM,
    super.distance,
    this.exercises,
    this.rounds,
    this.workDuration,
    this.restDuration,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? 'workout',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      calories: (json['caloriesBurned'] as num? ?? json['calories'] as num? ?? 0.0).toDouble(),
      averagePace: (json['averagePace'] as num?)?.toDouble() ?? 0.0,
      averageBPM: (json['averageBPM'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      exercises: (json['exercises'] as num?)?.toInt(),
      rounds: (json['rounds'] as num?)?.toInt(),
      workDuration: (json['workDuration'] as num?)?.toInt(),
      restDuration: (json['restDuration'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'duration': duration,
      'caloriesBurned': calories,
      'averagePace': averagePace,
      'averageBPM': averageBPM,
      'date': date.toIso8601String(),
      'distance': distance,
      'exercises': exercises,
      'rounds': rounds,
      'workDuration': workDuration,
      'restDuration': restDuration,
    };
  }
}
