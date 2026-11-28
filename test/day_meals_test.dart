import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/nutrition/domain/day_meals.dart';
import 'package:trainforge/features/nutrition/domain/food_goals.dart';

Map<String, Object?> entry(int h, int m, {String? kcal, String food = 'f'}) => {
  'foodId': food,
  'deletedAt': null,
  'occurredAt': DateTime(2026, 11, 28, h, m).toUtc().toIso8601String(),
  'calculation': {
    'nutrients': [
      {'nutrientId': 'energy_kcal', 'unit': 'kcal', 'value': kcal},
    ],
  },
};

void main() {
  test('entries within an hour form one meal; water is left out', () {
    final meals = groupMeals([
      entry(12, 40, kcal: '200'),
      entry(7, 40, kcal: '300'),
      entry(8, 30, kcal: '120'),
      entry(10, 0, food: 'water'),
      entry(12, 15, kcal: '420'),
    ], waterId: 'water');
    expect(meals, hasLength(2));
    expect(meals.first.slot, 'breakfast');
    expect(meals.first.kcal, 420);
    expect(meals.last.slot, 'lunch');
    expect(meals.last.kcal, 620);
  });

  test('a meal without exact kcal on every entry shows no kcal', () {
    final meals = groupMeals([
      entry(19, 0, kcal: '300'),
      entry(19, 20),
    ], waterId: 'water');
    expect(meals.single.slot, 'dinner');
    expect(meals.single.kcal, isNull);
  });

  test('the next meal comes 3 h 30 later, until the plan is done', () {
    final two = groupMeals([
      entry(7, 40, kcal: '1'),
      entry(12, 10, kcal: '1'),
    ], waterId: 'water');
    expect(
      nextMeal(two, FoodGoal.gainMuscle.meals),
      DateTime(2026, 11, 28, 15, 45),
    );
    expect(nextMeal(two, 2), isNull);
    final late = groupMeals([entry(19, 0, kcal: '1')], waterId: 'water');
    expect(nextMeal(late, 4), isNull);
  });

  test('every food reference has a DOI and a label', () {
    expect(foodGoalSources, hasLength(4));
    for (final s in foodGoalSources) {
      expect(s.doi, startsWith('10.'));
      expect(s.url, 'https://doi.org/${s.doi}');
    }
  });
}
