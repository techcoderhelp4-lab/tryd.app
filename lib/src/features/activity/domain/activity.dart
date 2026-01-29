class Activity {
  final String id;
  final String type; // 'run', 'walk', 'cycling'
  final double distance; // km
  final int duration; // seconds
  final double calories;
  final double averagePace;
  final double averageBPM;
  final DateTime date;

  Activity({
    required this.id,
    required this.type,
    this.distance = 0.0,
    required this.duration,
    this.calories = 0.0,
    this.averagePace = 0.0,
    this.averageBPM = 0.0,
    required this.date,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? 'run',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      calories: (json['caloriesBurned'] as num? ?? json['calories'] as num? ?? 0.0).toDouble(),
      averagePace: (json['averagePace'] as num?)?.toDouble() ?? 0.0,
      averageBPM: (json['averageBPM'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'distance': distance,
      'duration': duration,
      'caloriesBurned': calories,
      'averagePace': averagePace,
      'averageBPM': averageBPM,
      'date': date.toIso8601String(),
    };
  }
}
