//lib/features/workouts/domain/workout_plan_detail.dart
class WorkoutPlanDaySummary {
  final String id;
  final String weekDay;
  final String name;
  final bool isRest;
  final String? coverImageUrl;
  final int estimatedDurationInSeconds;
  final int exercisesCount;

  WorkoutPlanDaySummary({
    required this.id,
    required this.weekDay,
    required this.name,
    required this.isRest,
    required this.coverImageUrl,
    required this.estimatedDurationInSeconds,
    required this.exercisesCount,
  });

  factory WorkoutPlanDaySummary.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanDaySummary(
      id: json['id'],
      weekDay: json['weekDay'],
      name: json['name'],
      isRest: json['isRest'],
      coverImageUrl: json['coverImageUrl'],
      estimatedDurationInSeconds: json['estimatedDurationInSeconds'],
      exercisesCount: json['exercisesCount'],
    );
  }
}

class WorkoutPlanDetail {
  final String id;
  final String name;
  final List<WorkoutPlanDaySummary> workoutDays;

  WorkoutPlanDetail({
    required this.id,
    required this.name,
    required this.workoutDays,
  });

  factory WorkoutPlanDetail.fromJson(Map<String, dynamic> json) {
    final daysJson = (json['workoutDays'] as List<dynamic>? ?? []);

    return WorkoutPlanDetail(
      id: json['id'],
      name: json['name'],
      workoutDays: daysJson
          .map((d) => WorkoutPlanDaySummary.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}
