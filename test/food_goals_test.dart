import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/nutrition/domain/food_goals.dart';
import 'package:trainforge/features/onboarding/onboarding_profile.dart';

void main() {
  test('each goal has the meals and protein of its reference', () {
    expect(FoodGoal.gainMuscle.meals, 5);
    expect(FoodGoal.loseFat.meals, 4);
    // ISSN 1.4–2.0 g/kg for people who exercise; 0.8 g/kg RDA otherwise.
    expect(FoodGoal.gainMuscle.proteinGrams(70), 112);
    expect(FoodGoal.loseFat.proteinGrams(70), 140);
    expect(FoodGoal.eatBetter.proteinGrams(70), 56);
    expect(FoodGoal.maintain.proteinGrams(null), isNull);
  });

  test('water to drink follows EFSA minus food water', () {
    expect(FoodGoal.waterMl('woman'), 1600);
    expect(FoodGoal.waterMl('man'), 2000);
    expect(FoodGoal.waterMl('nonbinary'), 1800);
    expect(FoodGoal.waterMl(null), 1800);
  });

  test('the chosen goal is kept and unknown ids are dropped', () {
    final saved = const OnboardingProfile(foodGoal: 'ganhar').toJson();
    expect(OnboardingProfile.fromJson(saved).foodGoal, 'ganhar');
    expect(FoodGoal.fromId('ganhar'), FoodGoal.gainMuscle);
    expect(
      OnboardingProfile.fromJson({...saved, 'foodGoal': 'dieta-x'}).foodGoal,
      isNull,
    );
    for (final goal in FoodGoal.values) {
      expect(OnboardingProfile.foodGoals, contains(goal.id));
    }
  });
}
