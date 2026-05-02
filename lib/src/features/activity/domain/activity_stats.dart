class ActivityStats {
  final double totalDistance;
  final int totalDuration;
  final double totalCalories;
  final double averagePace;
  final double averageBPM;
  final int activityCount;
  final List<DailyStat> dailyStats;

  ActivityStats({
    required this.totalDistance,
    required this.totalDuration,
    required this.totalCalories,
    required this.averagePace,
    required this.averageBPM,
    required this.activityCount,
    required this.dailyStats,
  });

  factory ActivityStats.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] ?? {};
    final List<dynamic> daily = json['dailyStats'] ?? [];

    return ActivityStats(
      totalDistance: (summary['totalDistance'] as num?)?.toDouble() ?? 0.0,
      totalDuration: (summary['totalDuration'] as num?)?.toInt() ?? 0,
      totalCalories: (summary['totalCalories'] as num?)?.toDouble() ?? 0.0,
      averagePace: (summary['averagePace'] as num?)?.toDouble() ?? 0.0,
      averageBPM: (summary['averageBPM'] as num?)?.toDouble() ?? 0.0,
      activityCount: (summary['activityCount'] as num?)?.toInt() ?? 0,
      dailyStats: daily.map((e) => DailyStat.fromJson(e)).toList(),
    );
  }
}

class DailyStat {
  final String date;
  final double distance;
  final int activities;

  DailyStat({
    required this.date,
    required this.distance,
    required this.activities,
  });

  factory DailyStat.fromJson(Map<String, dynamic> json) {
    return DailyStat(
      date: json['_id'] ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      activities: (json['activities'] as num?)?.toInt() ?? 0,
    );
  }
}

