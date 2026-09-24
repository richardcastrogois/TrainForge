//lib/features/onboarding/data/onboarding_repository.dart
import 'package:trainforge/features/onboarding/data/onboarding_api.dart';

class OnboardingRepository {
  final OnboardingApi api = OnboardingApi();

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
  }) {
    return api.createManualPlan(
      weightInGrams: weightInGrams,
      heightInCentimeters: heightInCentimeters,
      age: age,
      bodyFatPercentage: bodyFatPercentage,
      goal: goal,
      daysPerWeek: daysPerWeek,
      experienceLevel: experienceLevel,
      sessionDurationInMinutes: sessionDurationInMinutes,
      restrictions: restrictions,
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
  }) {
    return api.createAiPlan(
      weightInGrams: weightInGrams,
      heightInCentimeters: heightInCentimeters,
      age: age,
      bodyFatPercentage: bodyFatPercentage,
      goal: goal,
      daysPerWeek: daysPerWeek,
      experienceLevel: experienceLevel,
      sessionDurationInMinutes: sessionDurationInMinutes,
      restrictions: restrictions,
    );
  }
}
