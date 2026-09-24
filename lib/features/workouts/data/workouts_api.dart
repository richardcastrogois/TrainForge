//lib/features/workouts/data/workouts_api.dart
import 'package:dio/dio.dart';
import 'package:trainforge/core/http/app_dio.dart';
import 'package:trainforge/features/workouts/domain/workout_day_detail.dart';
import 'package:trainforge/features/workouts/domain/workout_plan_detail.dart';
import 'package:trainforge/features/workouts/domain/workout_plan_item.dart';
import 'package:trainforge/features/workouts/domain/workout_session_action.dart';

class WorkoutsApi {
  final Dio dio = AppDio.instance;

  Future<List<WorkoutPlanItem>> fetchWorkoutPlans() async {
    final response = await dio.get(
      '/mobile/workout-plans',
      queryParameters: {'active': 'true'},
    );

    final data = response.data as List<dynamic>;

    return data
        .map((item) => WorkoutPlanItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<WorkoutPlanDetail> fetchWorkoutPlanDetail(String workoutPlanId) async {
    final response = await dio.get('/mobile/workout-plans/$workoutPlanId');
    return WorkoutPlanDetail.fromJson(response.data);
  }

  Future<WorkoutDayDetail> fetchWorkoutDayDetail({
    required String workoutPlanId,
    required String workoutDayId,
  }) async {
    final response = await dio.get(
      '/mobile/workout-plans/$workoutPlanId/days/$workoutDayId',
    );

    return WorkoutDayDetail.fromJson(response.data);
  }

  Future<StartWorkoutSessionResult> startWorkoutSession({
    required String workoutPlanId,
    required String workoutDayId,
  }) async {
    final response = await dio.post(
      '/mobile/workout-plans/$workoutPlanId/days/$workoutDayId/sessions',
      data: <String, dynamic>{},
    );

    return StartWorkoutSessionResult.fromJson(response.data);
  }

  Future<FinishWorkoutSessionResult> finishWorkoutSession({
    required String workoutPlanId,
    required String workoutDayId,
    required String sessionId,
    required String completedAt,
  }) async {
    final response = await dio.patch(
      '/mobile/workout-plans/$workoutPlanId/days/$workoutDayId/sessions/$sessionId',
      data: {'completedAt': completedAt},
    );

    return FinishWorkoutSessionResult.fromJson(response.data);
  }
}
