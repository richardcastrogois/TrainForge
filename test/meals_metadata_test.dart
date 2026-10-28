import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/nutrition/domain/meals.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/presentation/meal_metadata_controller.dart';
import 'package:trainforge/features/nutrition/presentation/meal_metadata_page.dart';
import 'package:trainforge/features/nutrition/presentation/own_food_picker_page.dart';
import 'package:trainforge/features/nutrition/presentation/meal_draft_page.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_forms.dart';
import 'package:trainforge/features/food_reference/domain/food_reference.dart';
import 'package:trainforge/l10n/generated/app_localizations.dart';
import 'meals_client_test.dart';
import 'meals_ui_test.dart' show mealShell;
import 'nutrition_localization_test.dart' show reach, small;
import 'nutrition_test.dart' show FakeNutrition;
import 'food_reference_test.dart' show fixtureFood;

class MetadataMeals extends FixtureMeals {
  final edits = <Json>[];
  final editKeys = <String>[];
  final editIds = <String>[];
  @override
  Future<ConfirmedMeal> editMeal(String id, Json body, String key) async {
    edits.add(copyMealJson(body));
    editKeys.add(key);
    editIds.add(id);
    if (failure != null) throw failure!;
    if (pending != null) return pending!.future;
    final result = confirmedFixture();
    result['meal'] = {
      ...object(result['meal']),
      ...body,
      'revision': (body['revision'] as int) + 1,
    }..remove('reviewed');
    return ConfirmedMeal.fromJson(result);
  }
}

MealMetadataController metadata(
  MetadataMeals r,
  String? Function() account, {
  Duration retryWindow = const Duration(hours: 24),
}) => MealMetadataController(
  repository: r,
  original: MealMetadata.fromJson(metadataFixture()),
  accountId: 'a',
  currentAccountId: account,
  retryWindow: retryWindow,
);

class PickerNutrition extends FakeNutrition {
  final queries = <String>[];
  @override
  Future<NutritionPageData> foods({String q = '', String? cursor}) async {
    queries.add('$q/${cursor ?? ''}');
    return NutritionPageData.fromJson({
      'items': [
        fixtureFood('own:fixture')..['nameOriginal'] = 'Private fixture',
      ],
      'nextCursor': null,
    });
  }
}

void main() {
  test(
    'metadata review is explicit and title edit sends no intake fields',
    () async {
      final r = MetadataMeals();
      final original = metadataFixture()..['timezone'] = 'America/Sao_Paulo';
      final subject = MealMetadataController(
        repository: r,
        original: MealMetadata.fromJson(original),
        accountId: 'a',
        currentAccountId: () => 'a',
      );
      addTearDown(subject.dispose);
      subject.setReviewed(true);
      await subject.submit();
      expect(r.edits, isEmpty); // No unchanged revision written.
      subject.setTitle('Reviewed fixture');
      expect(subject.reviewed, false);
      await subject.submit();
      expect(r.edits, isEmpty);
      subject.setReviewed(true);
      await subject.submit();
      expect(r.edits.single.keys.toSet(), {
        'title',
        'occurredAt',
        'timezone',
        'reviewed',
        'revision',
      });
      expect(r.edits.single['timezone'], 'America/Sao_Paulo');
      expect(
        sameMealInstant(r.edits.single['occurredAt'], original['occurredAt']),
        true,
      );
      expect(r.editIds, [mealId]);
      expect(subject.confirmed?.meal.revision, 2);
      expect(subject.confirmed?.entries.single, entryFixture());
    },
  );

  test('time-only changes are dirty and invalidate previous review', () {
    final c = metadata(MetadataMeals(), () => 'a');
    final d = draft(FixtureMeals(), () => 'a');
    addTearDown(c.dispose);
    addTearDown(d.dispose);
    expect(c.dirty, false);
    expect(d.dirty, false);
    c.setReviewed(true);
    c.setWhen(c.when.add(const Duration(minutes: 30)));
    d.setWhen(d.when.add(const Duration(minutes: 30)));
    expect(c.dirty, true);
    expect(c.reviewed, false);
    expect(d.dirty, true);
  });

  test(
    'uncertain metadata edit freezes key/revision/body; retry recovers once',
    () async {
      final r = MetadataMeals()..failure = TimeoutException('fixture');
      final c = metadata(r, () => 'a');
      addTearDown(c.dispose);
      c.setTitle('First fixture');
      c.setReviewed(true);
      await c.submit();
      expect(c.uncertain, true);
      c.setTitle('Forbidden new intent');
      c.setWhen(c.when.add(const Duration(days: 1)));
      r.failure = null;
      await c.submit();
      expect(r.edits, [r.edits.first, r.edits.first]);
      expect(r.editKeys.toSet(), hasLength(1));
      expect(c.confirmed?.meal.title, 'First fixture');
      expect(c.uncertain, false);
    },
  );

  test(
    'metadata conflict and expired retry never become another revision',
    () async {
      for (final expired in [false, true]) {
        final r = MetadataMeals()
          ..failure = expired ? TimeoutException('fixture') : requestError(409);
        final c = metadata(
          r,
          () => 'a',
          retryWindow: expired ? Duration.zero : const Duration(hours: 24),
        );
        c.setTitle('Fixture');
        c.setReviewed(true);
        await c.submit();
        r.failure = null;
        await c.submit();
        expect(c.conflict, true);
        expect(r.edits, hasLength(1));
        expect(c.title, 'Fixture');
        c.dispose();
      }
    },
  );

  test(
    'known metadata rejection requires another review and a fresh intent key',
    () async {
      final r = MetadataMeals()..failure = requestError(400);
      final c = metadata(r, () => 'a');
      addTearDown(c.dispose);
      c.setTitle('Rejected fixture');
      c.setReviewed(true);
      await c.submit();
      expect(c.uncertain, false);
      expect(c.reviewed, false);
      c.setTitle('Corrected fixture');
      r.failure = null;
      await c.submit();
      expect(r.edits, hasLength(1));
      c.setReviewed(true);
      await c.submit();
      expect(r.editKeys.toSet(), hasLength(2));
      expect(c.confirmed?.meal.title, 'Corrected fixture');
    },
  );

  test('account change erases edit and ignores late confirmation', () async {
    String? account = 'a';
    final r = MetadataMeals()..pending = Completer<ConfirmedMeal>();
    final c = metadata(r, () => account);
    addTearDown(c.dispose);
    c.setTitle('Private fixture');
    c.setReviewed(true);
    final saving = c.submit();
    account = 'b';
    c.accountChanged();
    r.pending!.complete(ConfirmedMeal.fromJson(confirmedFixture()));
    await saving;
    expect(c.title, isEmpty);
    expect(c.confirmed, isNull);
    expect(c.uncertain, false);
    expect(c.active, false);
  });

  testWidgets(
    'metadata form reviews then PATCHes existing meal without intake writes',
    (t) async {
      final r = MetadataMeals(), changes = ChangeNotifier();
      addTearDown(changes.dispose);
      ConfirmedMeal? result;
      final s = lookupAppLocalizations(const Locale('pt', 'BR'));
      await t.pumpWidget(
        mealShell(
          const Locale('pt', 'BR'),
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.push<ConfirmedMeal>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MealMetadataPage(
                        repository: r,
                        meal: MealMetadata.fromJson(metadataFixture()),
                        accountId: 'a',
                        currentAccountId: () => 'a',
                        sessionChanges: changes,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await reach(t, find.byType(TextFormField));
      await t.enterText(find.byType(TextFormField), 'Corrected fixture');
      FocusManager.instance.primaryFocus?.unfocus();
      await reach(t, find.byType(CheckboxListTile));
      await t.tap(find.byType(CheckboxListTile));
      await t.pumpAndSettle();
      await reach(t, find.text(s.confirmMeal));
      await t.tap(find.text(s.confirmMeal));
      await t.pumpAndSettle();
      expect(result?.meal.revision, 2);
      expect(r.writes, isEmpty);
      expect(r.edits.single.containsKey('items'), false);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'private picker returns source identity without saving anything',
    (t) async {
      final r = PickerNutrition(), changes = ChangeNotifier();
      addTearDown(changes.dispose);
      FoodReference? result;
      await t.pumpWidget(
        mealShell(
          const Locale('pt', 'BR'),
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.push<FoodReference>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OwnFoodPickerPage(
                        repository: r,
                        accountId: 'a',
                        currentAccountId: () => 'a',
                        sessionChanges: changes,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await reach(t, find.text('Private fixture'));
      await t.tap(find.text('Private fixture'));
      await t.pumpAndSettle();
      expect(result?.id, 'own:fixture');
      expect(r.queries, ['/']);
      expect(r.entryWrites, 0);
      expect(r.foodWrites, 0);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('meal source chooser prepares a private item without saving it', (
    t,
  ) async {
    final r = PickerNutrition(), changes = ChangeNotifier();
    addTearDown(changes.dispose);
    final s = lookupAppLocalizations(const Locale('pt', 'BR'));
    await t.pumpWidget(
      mealShell(
        const Locale('pt', 'BR'),
        MealDraftPage(
          repository: MetadataMeals(),
          nutrition: r,
          accountId: 'a',
          currentAccountId: () => 'a',
          sessionChanges: changes,
        ),
      ),
    );
    await t.pumpAndSettle();
    await reach(t, find.text(s.addMealItem));
    await t.tap(find.text(s.addMealItem));
    await t.pumpAndSettle();
    await t.tap(find.text(s.mealOwnFoods));
    await t.pumpAndSettle();
    await reach(t, find.text('Private fixture'));
    await t.tap(find.text('Private fixture'));
    await t.pumpAndSettle();
    expect(
      t.widget<EntryFormPage>(find.byType(EntryFormPage)).food.id,
      'own:fixture',
    );
    expect(find.byKey(const Key('entry-quantity')), findsOneWidget);
    expect(r.entryWrites, 0);
    expect(r.foodWrites, 0);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
  });

  for (final locale in AppLocalizations.supportedLocales.where(
    (l) => l.countryCode != null || l.languageCode != 'pt',
  )) {
    for (final dark in [false, true]) {
      testWidgets('metadata review fits 320px/text2x $locale dark=$dark', (
        t,
      ) async {
        small(t);
        final changes = ChangeNotifier();
        addTearDown(changes.dispose);
        await t.pumpWidget(
          mealShell(
            locale,
            MealMetadataPage(
              repository: MetadataMeals(),
              meal: MealMetadata.fromJson(metadataFixture()),
              accountId: 'a',
              currentAccountId: () => 'a',
              sessionChanges: changes,
            ),
            dark: dark,
          ),
        );
        await t.pumpAndSettle();
        final s = lookupAppLocalizations(locale);
        await reach(t, find.text(s.confirmMeal));
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets(
    'empty private search can open library, cancel and preserve its query',
    (t) async {
      final nutrition = FakeNutrition(), changes = ChangeNotifier();
      addTearDown(changes.dispose);
      var opens = 0;
      FoodReference? selected;
      final s = lookupAppLocalizations(const Locale('pt', 'BR'));
      await t.pumpWidget(
        mealShell(
          const Locale('pt', 'BR'),
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  selected = await Navigator.push<FoodReference>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OwnFoodPickerPage(
                        repository: nutrition,
                        accountId: 'a',
                        currentAccountId: () => 'a',
                        sessionChanges: changes,
                        chooseReference: (_) async {
                          opens++;
                          return opens == 1
                              ? null
                              : FoodReference.fromJson(fixtureFood(sourceId));
                        },
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await reach(t, find.byType(TextField));
      await t.enterText(find.byType(TextField), 'arroz');
      await t.pump(const Duration(milliseconds: 450));
      FocusManager.instance.primaryFocus?.unfocus();
      await reach(t, find.text(s.mealLibraryFood), delta: -200);
      await t.tap(find.text(s.mealLibraryFood));
      await t.pumpAndSettle();
      expect(opens, 1);
      expect(selected, isNull);
      await reach(t, find.byType(TextField));
      expect(
        t.widget<TextField>(find.byType(TextField)).controller?.text,
        'arroz',
      );
      await reach(t, find.text(s.mealLibraryFood), delta: -200);
      await t.tap(find.text(s.mealLibraryFood));
      await t.pumpAndSettle();
      expect(selected?.id, sourceId);
      expect(nutrition.entryWrites, 0);
      expect(nutrition.foodWrites, 0);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'late library selection cannot return food to a different account',
    (t) async {
      String? account = 'a';
      final nutrition = FakeNutrition(), changes = ChangeNotifier();
      addTearDown(changes.dispose);
      final pending = Completer<FoodReference?>();
      final s = lookupAppLocalizations(const Locale('pt', 'BR'));
      await t.pumpWidget(
        mealShell(
          const Locale('pt', 'BR'),
          OwnFoodPickerPage(
            repository: nutrition,
            accountId: 'a',
            currentAccountId: () => account,
            sessionChanges: changes,
            chooseReference: (_) => pending.future,
          ),
        ),
      );
      await t.pumpAndSettle();
      await reach(t, find.text(s.mealLibraryFood));
      await t.tap(find.text(s.mealLibraryFood));
      await t.pump();
      account = 'b';
      changes.notifyListeners();
      await t.pumpAndSettle();
      pending.complete(FoodReference.fromJson(fixtureFood(sourceId)));
      await t.pumpAndSettle();
      expect(nutrition.entryWrites, 0);
      expect(nutrition.foodWrites, 0);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
}
