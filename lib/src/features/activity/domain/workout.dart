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
      duration: (json['duration'] as num? ?? json['totalDuration'] as num? ?? 0).toInt(),
      calories: (json['caloriesBurned'] as num? ?? json['calories'] as num? ?? 0.0).toDouble(),
      averagePace: (json['averagePace'] as num?)?.toDouble() ?? 0.0,
      averageBPM: (json['averageBPM'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      exercises: (json['exercisesCount'] as num? ?? json['exercises'] as num?)?.toInt(),
      rounds: (json['roundsCount'] as num? ?? json['rounds'] as num?)?.toInt(),
      workDuration: (json['workTime'] as num? ?? json['workDuration'] as num?)?.toInt(),
      restDuration: (json['restTime'] as num? ?? json['restDuration'] as num?)?.toInt(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'duration': duration,
      'totalDuration': duration,
      'caloriesBurned': calories,
      'averagePace': averagePace,
      'averageBPM': averageBPM,
      'date': date.toIso8601String(),
      'distance': distance,
      // Backend specific fields
      'exercisesCount': exercises,
      'roundsCount': rounds,
      'workTime': workDuration,
      'restTime': restDuration,
      // Legacy fields for local storage compatibility
      'exercises': exercises,
      'rounds': rounds,
      'workDuration': workDuration,
      'restDuration': restDuration,
    };
  }
}

class PreBuiltWorkout {
  final String id;
  final String title;
  final String imageUrl;
  final int workDuration;
  final int restDuration;
  final int totalExercises;
  final int totalRounds;

  const PreBuiltWorkout({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.workDuration,
    required this.restDuration,
    required this.totalExercises,
    required this.totalRounds,
  });

  factory PreBuiltWorkout.fromJson(Map<String, dynamic> json) {
    return PreBuiltWorkout(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      workDuration: (json['workDuration'] as num? ?? 0).toInt(),
      restDuration: (json['restDuration'] as num? ?? 0).toInt(),
      totalExercises: (json['totalExercises'] as num? ?? 1).toInt(),
      totalRounds: (json['totalRounds'] as num? ?? 1).toInt(),
    );
  }

  int get totalDurationSeconds => totalExercises * totalRounds * (workDuration + restDuration);
  int get totalDurationMinutes => (totalDurationSeconds / 60).ceil();
}

