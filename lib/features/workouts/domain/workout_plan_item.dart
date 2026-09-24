//lib/features/workouts/domain/workout_plan_item.dart
class WorkoutExerciseItem {
  final String id;
  final int order;
  final String name;
  final int sets;
  final int reps;
  final int restTimeInSeconds;

  WorkoutExerciseItem({
    required this.id,
    required this.order,
    required this.name,
    required this.sets,
    required this.reps,
    required this.restTimeInSeconds,
  });

  factory WorkoutExerciseItem.fromJson(Map<String, dynamic> json) {
    return WorkoutExerciseItem(
      id: json['id'],
      order: json['order'],
      name: json['name'],
      sets: json['sets'],
      reps: json['reps'],
      restTimeInSeconds: json['restTimeInSeconds'],
    );
  }
}

class WorkoutDayItem {
  final String id;
  final String name;
  final String weekDay;
  final bool isRest;
  final int estimatedDurationInSeconds;
  final String? coverImageUrl;
  final List<WorkoutExerciseItem> exercises;

  WorkoutDayItem({
    required this.id,
    required this.name,
    required this.weekDay,
    required this.isRest,
    required this.estimatedDurationInSeconds,
    required this.coverImageUrl,
    required this.exercises,
  });

  factory WorkoutDayItem.fromJson(Map<String, dynamic> json) {
    final exercisesJson = (json['exercises'] as List<dynamic>? ?? []);

    return WorkoutDayItem(
      id: json['id'],
      name: json['name'],
      weekDay: json['weekDay'],
      isRest: json['isRest'],
      estimatedDurationInSeconds: json['estimatedDurationInSeconds'],
      coverImageUrl: json['coverImageUrl'],
      exercises: exercisesJson
          .map((e) => WorkoutExerciseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WorkoutPlanItem {
  final String id;
  final String name;
  final bool isActive;
  final List<WorkoutDayItem> workoutDays;

  WorkoutPlanItem({
    required this.id,
    required this.name,
    required this.isActive,
    required this.workoutDays,
  });

  factory WorkoutPlanItem.fromJson(Map<String, dynamic> json) {
    final daysJson = (json['workoutDays'] as List<dynamic>? ?? []);

    return WorkoutPlanItem(
      id: json['id'],
      name: json['name'],
      isActive: json['isActive'],
      workoutDays: daysJson
          .map((d) => WorkoutDayItem.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}
