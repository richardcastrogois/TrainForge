//lib/features/stats/domain/stats_data.dart
class DailyConsistency {
  final String date;
  final bool workoutDayCompleted;
  final bool workoutDayStarted;

  DailyConsistency({
    required this.date,
    required this.workoutDayCompleted,
    required this.workoutDayStarted,
  });
}

class StatsData {
  final int workoutStreak;
  final int completedWorkoutsCount;
  final double conclusionRate;
  final int totalTimeInSeconds;
  final List<DailyConsistency> consistency;

  StatsData({
    required this.workoutStreak,
    required this.completedWorkoutsCount,
    required this.conclusionRate,
    required this.totalTimeInSeconds,
    required this.consistency,
  });

  String get formattedConclusionRate {
    return '${(conclusionRate * 100).toStringAsFixed(0)}%';
  }

  String get formattedTotalTime {
    final totalMinutes = totalTimeInSeconds ~/ 60;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }

    return '${minutes}min';
  }

  factory StatsData.fromJson(Map<String, dynamic> json) {
    final map = (json['consistencyByDay'] as Map<String, dynamic>? ?? {});

    final consistency = map.entries.map((entry) {
      final value = entry.value as Map<String, dynamic>;

      return DailyConsistency(
        date: entry.key,
        workoutDayCompleted: value['workoutDayCompleted'] == true,
        workoutDayStarted: value['workoutDayStarted'] == true,
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    return StatsData(
      workoutStreak: json['workoutStreak'] ?? 0,
      completedWorkoutsCount: json['completedWorkoutsCount'] ?? 0,
      conclusionRate: (json['conclusionRate'] ?? 0).toDouble(),
      totalTimeInSeconds: json['totalTimeInSeconds'] ?? 0,
      consistency: consistency,
    );
  }
}
