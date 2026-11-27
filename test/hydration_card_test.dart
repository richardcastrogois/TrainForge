import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/presentation/hydration_card.dart';
import 'nutrition_test.dart' show FakeNutrition;

/// Keeps what was saved and returns it as the day's entries.
class WaterDiary extends FakeNutrition {
  final saved = <Json>[];
  final deleted = <String>[];
  @override
  Future<Json> saveEntry(Json b, String k, {String? id}) async {
    await super.saveEntry(b, k, id: id);
    final entry = {
      'id': 'water-${saved.length}',
      'foodId': b['foodId'],
      'quantity': b['quantity'],
      'deletedAt': null,
      'calculation': {'revision': 1},
    };
    saved.add(entry);
    return entry;
  }

  @override
  Future<NutritionPageData> entries(
    String day,
    String zone, {
    String? cursor,
  }) async => NutritionPageData.fromJson({
    'items': [
      for (final e in saved)
        if (!deleted.contains(e['id'])) e,
      // Other foods never count as water.
      {
        'id': 'rice',
        'foodId': 'food:rice',
        'quantity': '150',
        'deletedAt': null,
      },
    ],
    'nextCursor': null,
  });

  @override
  Future<void> deleteEntry(String id, int revision, String key) async =>
      deleted.add(id);
}

void main() {
  testWidgets('one tap records water in grams, shows ml and can be undone', (
    t,
  ) async {
    final diary = WaterDiary();
    var changes = 0;
    await t.pumpWidget(
      MaterialApp(
        theme: TrainForgeTheme.light,
        home: Scaffold(
          body: HydrationCard(
            repository: diary,
            now: () => DateTime(2026, 11, 27, 10),
            changed: () => changes++,
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('0 ml'), findsOneWidget);
    await t.tap(find.text('+ 1 copo'));
    await t.pumpAndSettle();
    expect(diary.body?['foodId'], waterFoodId);
    expect(diary.body?['quantity'], '200');
    expect(diary.body?['unit'], 'g');
    expect(diary.body?['quantityEvidence'], 'estimated');
    expect(find.text('200 ml'), findsNWidgets(2)); // total and button
    expect(changes, 1);
    await t.tap(find.text('+ 1 garrafa'));
    await t.pumpAndSettle();
    expect(find.text('700 ml'), findsOneWidget);
    await t.tap(find.text('Desfazer').last);
    await t.pumpAndSettle();
    expect(diary.deleted, ['water-1']);
    expect(find.text('200 ml'), findsNWidgets(2)); // total and button
  });
}
