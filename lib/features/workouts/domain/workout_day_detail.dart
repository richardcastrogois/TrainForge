//lib/features/workouts/domain/workout_day_detail.dart
class WorkoutDayExerciseDetail {
  final String id;
  final String name;
  final int order;
  final String workoutDayId;
  final int sets;
  final int reps;
  final int restTimeInSeconds;

  WorkoutDayExerciseDetail({
    required this.id,
    required this.name,
    required this.order,
    required this.workoutDayId,
    required this.sets,
    required this.reps,
    required this.restTimeInSeconds,
  });

  factory WorkoutDayExerciseDetail.fromJson(Map<String, dynamic> json) {
    return WorkoutDayExerciseDetail(
      id: json['id'],
      name: json['name'],
      order: json['order'],
      workoutDayId: json['workoutDayId'],
      sets: json['sets'],
      reps: json['reps'],
      restTimeInSeconds: json['restTimeInSeconds'],
    );
  }
}

class WorkoutSessionSummary {
  final String id;
  final String workoutDayId;
  final String? startedAt;
  final String? completedAt;

  WorkoutSessionSummary({
    required this.id,
    required this.workoutDayId,
    required this.startedAt,
    required this.completedAt,
  });

  factory WorkoutSessionSummary.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionSummary(
      id: json['id'],
      workoutDayId: json['workoutDayId'],
      startedAt: json['startedAt'],
      completedAt: json['completedAt'],
    );
  }
}

class WorkoutDayDetail {
  final String id;
  final String name;
  final bool isRest;
  final String? coverImageUrl;
  final int estimatedDurationInSeconds;
  final String weekDay;
  final List<WorkoutDayExerciseDetail> exercises;
  final List<WorkoutSessionSummary> sessions;

  WorkoutDayDetail({
    required this.id,
    required this.name,
    required this.isRest,
    required this.coverImageUrl,
    required this.estimatedDurationInSeconds,
    required this.weekDay,
    required this.exercises,
    required this.sessions,
  });

  factory WorkoutDayDetail.fromJson(Map<String, dynamic> json) {
    final exercisesJson = (json['exercises'] as List<dynamic>? ?? []);
    final sessionsJson = (json['sessions'] as List<dynamic>? ?? []);

    return WorkoutDayDetail(
      id: json['id'],
      name: json['name'],
      isRest: json['isRest'],
      coverImageUrl: json['coverImageUrl'],
      estimatedDurationInSeconds: json['estimatedDurationInSeconds'],
      weekDay: json['weekDay'],
      exercises: exercisesJson
          .map(
            (e) => WorkoutDayExerciseDetail.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      sessions: sessionsJson
          .map((s) => WorkoutSessionSummary.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
