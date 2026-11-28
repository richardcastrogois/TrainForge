import 'package:trainforge/features/nutrition/domain/nutrition.dart';

/// Food (not water) recorded within an hour of the previous entry belongs
/// to the same meal.
const mealGap = Duration(minutes: 60);

/// One meal of the day: the entries recorded close together.
class DayMeal {
  final DateTime start;
  final List<Json> entries;
  const DayMeal(this.start, this.entries);

  /// Energy of the meal, only when every entry has an exact kcal value.
  double? get kcal {
    var total = 0.0;
    for (final entry in entries) {
      final value = entryKcal(entry);
      if (value == null) return null;
      total += value;
    }
    return total;
  }

  /// Name by the time of day (the diary does not store one).
  String get slot {
    final h = start.toLocal().hour;
    if (h >= 5 && h < 10) return 'breakfast';
    if (h >= 10 && h < 12) return 'morningSnack';
    if (h >= 12 && h < 15) return 'lunch';
    if (h >= 15 && h < 18) return 'afternoonSnack';
    if (h >= 18 && h < 22) return 'dinner';
    return 'supper';
  }
}

/// Today's meals, oldest first, from the diary entries (water left out).
List<DayMeal> groupMeals(Iterable<Json> entries, {required String waterId}) {
  final food = [
    for (final e in entries)
      if (e['deletedAt'] == null &&
          e['foodId'] != waterId &&
          DateTime.tryParse('${e['occurredAt']}') != null)
        e,
  ]..sort((a, b) => _at(a).compareTo(_at(b)));
  final meals = <DayMeal>[];
  DateTime? last;
  for (final e in food) {
    final at = _at(e);
    if (last == null || at.difference(last) > mealGap) {
      meals.add(DayMeal(at, [e]));
    } else {
      meals.last.entries.add(e);
    }
    last = at;
  }
  return meals;
}

/// kcal of one entry, or null when the source has no exact value.
double? entryKcal(Json entry) {
  for (final n in objects(object(entry['calculation'])['nutrients'])) {
    if (n['unit'] == 'kcal' && n['value'] != null) {
      return double.tryParse('${n['value']}');
    }
  }
  return null;
}

/// When the next meal fits, 3–4 h after the last one (ISSN nutrient
/// timing, Kerksick et al., 2017): the midpoint, 3 h 30, rounded to 15 min.
/// Null once the planned meals are done or it would fall after 22:00.
DateTime? nextMeal(List<DayMeal> meals, int target) {
  if (meals.isEmpty || meals.length >= target) return null;
  final last = meals.last.entries
      .map(_at)
      .reduce((a, b) => a.isAfter(b) ? a : b);
  final next = last.toLocal().add(const Duration(minutes: 210));
  final rounded = DateTime(
    next.year,
    next.month,
    next.day,
    next.hour,
    (next.minute / 15).round() * 15,
  );
  if (rounded.day != last.toLocal().day || rounded.hour >= 22) return null;
  return rounded;
}

DateTime _at(Json e) => DateTime.parse('${e['occurredAt']}');
