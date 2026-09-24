//lib/features/home/domain/home_summary.dart
class HomeSummary {
  final String? activeWorkoutPlanId;
  final String? todayWorkoutPlanId;
  final String? todayWorkoutId;
  final String? todayWorkoutName;
  final bool isRestDay;
  final int exercisesCount;
  final int workoutStreak;
  final int weeklyStarted;
  final int weeklyCompleted;

  HomeSummary({
    required this.activeWorkoutPlanId,
    required this.todayWorkoutPlanId,
    required this.todayWorkoutId,
    required this.todayWorkoutName,
    required this.isRestDay,
    required this.exercisesCount,
    required this.workoutStreak,
    required this.weeklyStarted,
    required this.weeklyCompleted,
  });

  factory HomeSummary.fromJson(Map<String, dynamic> json) {
    final todayWorkoutDay = json['todayWorkoutDay'] as Map<String, dynamic>?;
    final consistencyByDay =
        (json['consistencyByDay'] as Map<String, dynamic>? ?? {});

    int weeklyStarted = 0;
    int weeklyCompleted = 0;

    for (final value in consistencyByDay.values) {
      final day = value as Map<String, dynamic>;

      if (day['workoutDayStarted'] == true) {
        weeklyStarted++;
      }

      if (day['workoutDayCompleted'] == true) {
        weeklyCompleted++;
      }
    }

    return HomeSummary(
      activeWorkoutPlanId: json['activeWorkoutPlanId'],
      todayWorkoutPlanId: todayWorkoutDay?['workoutPlanId'],
      todayWorkoutId: todayWorkoutDay?['id'],
      todayWorkoutName: todayWorkoutDay?['name'],
      isRestDay: todayWorkoutDay?['isRest'] == true,
      exercisesCount: todayWorkoutDay?['exercisesCount'] ?? 0,
      workoutStreak: json['workoutStreak'] ?? 0,
      weeklyStarted: weeklyStarted,
      weeklyCompleted: weeklyCompleted,
    );
  }
}
