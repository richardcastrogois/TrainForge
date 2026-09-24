//lib/features/workouts/domain/workout_session_action.dart
class StartWorkoutSessionResult {
  final String userWorkoutSessionId;

  StartWorkoutSessionResult({required this.userWorkoutSessionId});

  factory StartWorkoutSessionResult.fromJson(Map<String, dynamic> json) {
    return StartWorkoutSessionResult(
      userWorkoutSessionId: json['userWorkoutSessionId'],
    );
  }
}

class FinishWorkoutSessionResult {
  final String id;
  final String startedAt;
  final String completedAt;

  FinishWorkoutSessionResult({
    required this.id,
    required this.startedAt,
    required this.completedAt,
  });

  factory FinishWorkoutSessionResult.fromJson(Map<String, dynamic> json) {
    return FinishWorkoutSessionResult(
      id: json['id'],
      startedAt: json['startedAt'],
      completedAt: json['completedAt'],
    );
  }
}
