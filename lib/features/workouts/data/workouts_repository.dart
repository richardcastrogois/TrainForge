//lib/features/workouts/data/workouts_repository.dart
import 'package:trainforge/features/workouts/data/workouts_api.dart';
import 'package:trainforge/features/workouts/domain/workout_day_detail.dart';
import 'package:trainforge/features/workouts/domain/workout_plan_detail.dart';
import 'package:trainforge/features/workouts/domain/workout_plan_item.dart';
import 'package:trainforge/features/workouts/domain/workout_session_action.dart';

class WorkoutsRepository {
  final WorkoutsApi api = WorkoutsApi();

  Future<List<WorkoutPlanItem>> getWorkoutPlans() {
    return api.fetchWorkoutPlans();
  }

  Future<WorkoutPlanDetail> getWorkoutPlanDetail(String workoutPlanId) {
    return api.fetchWorkoutPlanDetail(workoutPlanId);
  }

  Future<WorkoutDayDetail> getWorkoutDayDetail({
    required String workoutPlanId,
    required String workoutDayId,
  }) {
    return api.fetchWorkoutDayDetail(
      workoutPlanId: workoutPlanId,
      workoutDayId: workoutDayId,
    );
  }

  Future<StartWorkoutSessionResult> startWorkoutSession({
    required String workoutPlanId,
    required String workoutDayId,
  }) {
    return api.startWorkoutSession(
      workoutPlanId: workoutPlanId,
      workoutDayId: workoutDayId,
    );
  }

  Future<FinishWorkoutSessionResult> finishWorkoutSession({
    required String workoutPlanId,
    required String workoutDayId,
    required String sessionId,
    required String completedAt,
  }) {
    return api.finishWorkoutSession(
      workoutPlanId: workoutPlanId,
      workoutDayId: workoutDayId,
      sessionId: sessionId,
      completedAt: completedAt,
    );
  }
}
