import 'dart:math';
import 'package:trainforge/features/food_reference/domain/food_reference.dart';

typedef Json = Map<String, dynamic>;
Json object(Object? raw) => Map<String, dynamic>.from(raw as Map);
List<Json> objects(Object? raw) => (raw as List).map(object).toList();
String mutationKey() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 15) | 64;
  b[8] = (b[8] & 63) | 128;
  final h = b.map((n) => n.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

String localDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String offsetZone(DateTime d) {
  final m = d.timeZoneOffset.inMinutes;
  return '${m < 0 ? '-' : '+'}${(m.abs() ~/ 60).toString().padLeft(2, '0')}:${(m.abs() % 60).toString().padLeft(2, '0')}';
}

bool validDecimal(String s, {bool positive = false}) =>
    RegExp(r'^[0-9]{1,7}(\.[0-9]{1,6})?$').hasMatch(s) &&
    (!positive || RegExp('[1-9]').hasMatch(s));
String decimal(String s) => s.trim().replaceAll(',', '.');

class NutritionPageData {
  final List<Json> items;
  final String? cursor;
  final FoodNameCatalog? nameCatalog;
  NutritionPageData.fromJson(Json j)
    : items = objects(j['items']),
      cursor = j['nextCursor'] as String?,
      nameCatalog = j['nameCatalog'] == null
          ? null
          : FoodNameCatalog.fromJson(object(j['nameCatalog']));
}

abstract interface class NutritionRepository {
  Future<NutritionPageData> foods({String q = '', String? cursor});
  Future<Json> createFood(Json body, String key);
  Future<NutritionPageData> entries(String day, String zone, {String? cursor});
  Future<Json> summary(String day, String zone);
  Future<Json> saveEntry(Json body, String key, {String? id});
  Future<void> deleteEntry(String id, int revision, String key);
}

abstract interface class LocalizedNutritionRepository {
  Future<NutritionPageData> localizedEntries(
    String day,
    String zone, {
    required String locale,
    String? cursor,
    String? namesVersion,
  });
  Future<Json> localizedEntry(String id, {required String locale});
}

/// Current editorial display metadata is never a member of the saved calculation.
class EntryFoodDisplay {
  final String foodId, foodVersion;
  final FoodNameCatalog catalog;
  final ReviewedFoodName? name;
  EntryFoodDisplay._(this.foodId, this.foodVersion, this.catalog, this.name);
  static EntryFoodDisplay? fromEntry(Json entry) {
    if (entry['foodDisplay'] == null) return null;
    final d = object(entry['foodDisplay']),
        food = object(object(entry['calculation'])['food']);
    if (d['foodId'] != entry['foodId'] ||
        d['foodVersion'] != entry['foodVersion'] ||
        food['id'] != entry['foodId'] ||
        food['versionId'] != entry['foodVersion']) {
      throw const FormatException('Entry name identity mismatch');
    }
    final catalog = FoodNameCatalog.fromJson(object(d['nameCatalog']));
    final personal =
        food['sourceId'] == 'personal' ||
        (entry['foodId'] as String).startsWith('own:');
    final name = personal || d['reviewedName'] == null
        ? null
        : ReviewedFoodName.fromJson(object(d['reviewedName']));
    if (name != null &&
        (!RegExp(r'^food:[a-f0-9]{64}$').hasMatch(entry['foodId'] as String) ||
            !RegExp(
              r'^[a-f0-9]{64}$',
            ).hasMatch(entry['foodVersion'] as String) ||
            name.locale != catalog.locale)) {
      throw const FormatException('Entry name locale mismatch');
    }
    return EntryFoodDisplay._(
      d['foodId'] as String,
      d['foodVersion'] as String,
      catalog,
      name,
    );
  }
}

String entryDisplayName(Json entry, String locale) {
  final food = object(object(entry['calculation'])['food']);
  final display = EntryFoodDisplay.fromEntry(entry);
  return displayLabel(
    display?.catalog.locale == locale
        ? (display?.name?.name ?? food['nameOriginal'])
        : food['nameOriginal'],
  );
}

FoodReference entryPresentationFood(Json entry, String locale) {
  final food = object(object(entry['calculation'])['food']);
  final display = EntryFoodDisplay.fromEntry(entry);
  return asFood({
    ...food,
    if (display?.name != null && display?.catalog.locale == locale)
      'reviewedName': object(entry['foodDisplay'])['reviewedName'],
  });
}

FoodReference asFood(Json value) => FoodReference.fromJson(value);

String displayLabel(Object? value) =>
    (value as String).replaceAll(RegExp(r'\s+'), ' ').trim();
String localTimestamp(String raw) {
  final d = DateTime.parse(raw).toLocal();
  return "${localDay(d)} às ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} (${offsetZone(d)})";
}
