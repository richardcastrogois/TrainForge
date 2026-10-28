import 'dart:convert';
import 'nutrition.dart';
import '../../food_reference/domain/food_reference.dart';

bool mealUuid(Object? value) =>
    value is String &&
    RegExp(r'^[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}$').hasMatch(value);
Json copyMealJson(Json value) => object(jsonDecode(jsonEncode(value)));
bool sameMealQuantity(String a, String b) {
  if (!validDecimal(a, positive: true) || !validDecimal(b, positive: true)) {
    return false;
  }
  String normalized(String value) {
    final parts = value.split('.');
    final whole = parts.first.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final fraction = (parts.length == 2 ? parts[1] : '').replaceFirst(
      RegExp(r'0+$'),
      '',
    );
    return fraction.isEmpty ? whole : '$whole.$fraction';
  }

  return normalized(a) == normalized(b);
}

bool sameMealInstant(Object? a, Object? b) {
  final left = a is String ? DateTime.tryParse(a) : null;
  final right = b is String ? DateTime.tryParse(b) : null;
  return left != null && right != null && left.isAtSameMomentAs(right);
}

class MealMetadata {
  final String id, title, occurredAt, timezone;
  final int revision, totalActiveItems;
  MealMetadata.fromJson(Json j)
    : id = j['id'] as String,
      title = j['title'] as String,
      occurredAt = j['occurredAt'] as String,
      timezone = j['timezone'] as String,
      revision = j['revision'] as int,
      totalActiveItems = j['totalActiveItems'] as int {
    if (!mealUuid(id) ||
        title.runes.length > 80 ||
        DateTime.tryParse(occurredAt) == null ||
        timezone.isEmpty ||
        timezone.length > 80 ||
        revision < 1 ||
        revision > 2147483647 ||
        totalActiveItems < 0 ||
        totalActiveItems > 32) {
      throw const FormatException('Invalid meal metadata');
    }
  }
}

class MealGroup {
  final MealMetadata meal;
  final List<String> entryIds;
  final int otherActiveItems;
  final Json totals;
  MealGroup.fromJson(Json j)
    : meal = MealMetadata.fromJson(object(j['meal'])),
      entryIds = List.unmodifiable(List<String>.from(j['entryIds'] as List)),
      otherActiveItems = j['otherActiveItems'] as int,
      totals = Map.unmodifiable(object(j['totals'])) {
    if (entryIds.isEmpty ||
        entryIds.length > 32 ||
        entryIds.toSet().length != entryIds.length ||
        entryIds.any((id) => !mealUuid(id)) ||
        otherActiveItems < 0 ||
        entryIds.length + otherActiveItems != meal.totalActiveItems ||
        totals['entries'] != entryIds.length) {
      throw const FormatException('Invalid meal group coverage');
    }
  }
}

/// The two views reference the same entry IDs. There is no client-side scaling.
class MealDay {
  final String date, timezone;
  final List<Json> entries;
  final List<MealGroup> meals;
  final List<String> ungroupedEntryIds;
  final Json totals;
  final bool complete;
  final FoodNameCatalog? nameCatalog;
  MealDay._(
    this.date,
    this.timezone,
    this.entries,
    this.meals,
    this.ungroupedEntryIds,
    this.totals,
    this.complete,
    this.nameCatalog,
  );
  factory MealDay.fromJson(Json j) {
    final d = object(j['diary']);
    final entries = objects(d['entries']);
    final meals = objects(d['meals']).map(MealGroup.fromJson).toList();
    final ungrouped = List<String>.from(d['ungroupedEntryIds'] as List);
    final totals = object(d['totals']);
    final complete = d['complete'] as bool;
    final ids = <String>{}, covered = <String>{}, groupIds = <String>{};
    if (entries.length > 100 ||
        meals.length > entries.length ||
        totals['entries'] != entries.length ||
        totals['complete'] != complete) {
      throw const FormatException('Invalid meal diary coverage');
    }
    for (final e in entries) {
      if (!mealUuid(e['id']) ||
          !ids.add(e['id'] as String) ||
          e['deletedAt'] != null) {
        throw const FormatException('Invalid diary intake identity');
      }
    }
    for (final g in meals) {
      if (!groupIds.add(g.meal.id)) {
        throw const FormatException('Duplicate meal');
      }
      for (final id in g.entryIds) {
        if (!ids.contains(id) || !covered.add(id)) {
          throw const FormatException('Invalid diary membership');
        }
      }
    }
    for (final id in ungrouped) {
      if (!ids.contains(id) || !covered.add(id)) {
        throw const FormatException('Invalid ungrouped intake');
      }
    }
    if (covered.length != ids.length) {
      throw const FormatException('Intake missing from both diary views');
    }
    return MealDay._(
      j['date'] as String,
      j['timezone'] as String,
      List.unmodifiable(entries),
      List.unmodifiable(meals),
      List.unmodifiable(ungrouped),
      Map.unmodifiable(totals),
      complete,
      j['nameCatalog'] == null
          ? null
          : FoodNameCatalog.fromJson(object(j['nameCatalog'])),
    );
  }
}

class ConfirmedMeal {
  final MealMetadata meal;
  final List<Json> entries;
  final String? deletedAt;
  ConfirmedMeal.fromJson(Json j)
    : meal = MealMetadata.fromJson(object(j['meal'])),
      entries = List.unmodifiable(objects(j['entries'])),
      deletedAt = j['deletedAt'] as String? {
    final ids = <String>{};
    if (entries.isEmpty ||
        entries.length > 32 ||
        entries.any((e) => !mealUuid(e['id']) || !ids.add(e['id'] as String)) ||
        entries.where((e) => e['deletedAt'] == null).length !=
            meal.totalActiveItems ||
        (deletedAt != null &&
            (DateTime.tryParse(deletedAt!) == null ||
                meal.totalActiveItems != 0))) {
      throw const FormatException('Invalid meal confirmation');
    }
  }
}

abstract interface class MealRepository {
  Future<MealDay> mealDay(
    String day,
    String timezone, {
    required String locale,
  });
  Future<ConfirmedMeal> meal(String id, {required String locale});
  Future<ConfirmedMeal> createMeal(Json body, String key);
  Future<ConfirmedMeal> editMeal(String id, Json body, String key);
  Future<ConfirmedMeal> deleteMeal(String id, int revision, String key);
}
