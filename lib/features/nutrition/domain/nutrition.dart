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
  NutritionPageData.fromJson(Json j)
    : items = objects(j['items']),
      cursor = j['nextCursor'] as String?;
}

abstract interface class NutritionRepository {
  Future<NutritionPageData> foods({String q = '', String? cursor});
  Future<Json> createFood(Json body, String key);
  Future<NutritionPageData> entries(String day, String zone, {String? cursor});
  Future<Json> summary(String day, String zone);
  Future<Json> saveEntry(Json body, String key, {String? id});
  Future<void> deleteEntry(String id, int revision, String key);
}

FoodReference asFood(Json value) => FoodReference.fromJson(value);

String displayLabel(Object? value) =>
    (value as String).replaceAll(RegExp(r'\s+'), ' ').trim();
String localTimestamp(String raw) {
  final d = DateTime.parse(raw).toLocal();
  return "${localDay(d)} às ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} (${offsetZone(d)})";
}
