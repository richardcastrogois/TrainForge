//lib/features/onboarding/data/onboarding_api.dart
import 'package:dio/dio.dart';
import 'package:trainforge/core/http/app_dio.dart';

class OnboardingApi {
  final Dio dio = AppDio.instance;

  Future<void> createManualPlan({
    required int weightInGrams,
    required int heightInCentimeters,
    required int age,
    required int bodyFatPercentage,
    required String goal,
    required int daysPerWeek,
    required String experienceLevel,
    required int sessionDurationInMinutes,
    required String restrictions,
  }) async {
    await dio.post(
      '/mobile/onboarding/manual-plan',
      data: {
        'trainData': {
          'weightInGrams': weightInGrams,
          'heightInCentimeters': heightInCentimeters,
          'age': age,
          'bodyFatPercentage': bodyFatPercentage,
        },
        'preferences': {
          'goal': goal,
          'daysPerWeek': daysPerWeek,
          'experienceLevel': experienceLevel,
          'sessionDurationInMinutes': sessionDurationInMinutes,
          'restrictions': restrictions,
        },
      },
    );
  }

  Future<void> createAiPlan({
    required int weightInGrams,
    required int heightInCentimeters,
    required int age,
    required int bodyFatPercentage,
    required String goal,
    required int daysPerWeek,
    required String experienceLevel,
    required int sessionDurationInMinutes,
    required String restrictions,
  }) async {
    await dio.post(
      '/mobile/onboarding/ai-plan',
      data: {
        'trainData': {
          'weightInGrams': weightInGrams,
          'heightInCentimeters': heightInCentimeters,
          'age': age,
          'bodyFatPercentage': bodyFatPercentage,
        },
        'preferences': {
          'goal': goal,
          'daysPerWeek': daysPerWeek,
          'experienceLevel': experienceLevel,
          'sessionDurationInMinutes': sessionDurationInMinutes,
          'restrictions': restrictions,
        },
      },
      options: Options(
        sendTimeout: const Duration(seconds: 30),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
  }
}
