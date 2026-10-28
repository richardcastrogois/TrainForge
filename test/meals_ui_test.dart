import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/l10n/locale_controller.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/nutrition/domain/meals.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/presentation/meal_diary_page.dart';
import 'package:trainforge/features/nutrition/presentation/meal_draft_page.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_forms.dart';
import 'package:trainforge/l10n/generated/app_localizations.dart';
import 'nutrition_test.dart' show FakeNutrition;
import 'nutrition_localization_test.dart' show small, reach;
import 'meals_client_test.dart' show FixtureMeals, dayFixture, sourceId;
import 'food_reference_test.dart' show fixtureFood;
import 'package:trainforge/features/food_reference/domain/food_reference.dart';

Widget mealShell(Locale locale, Widget page, {bool dark = false}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedAppLocales,
      theme: dark ? TrainForgeTheme.dark : TrainForgeTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(2),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: page,
    );

Future<void> scrollFormTo(WidgetTester t, Finder target) async {
  final view = find
      .byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.vertical,
      )
      .first;
  for (var i = 0; i < 80; i++) {
    if (target.hitTestable().evaluate().isNotEmpty) {
      return;
    }
    await t.drag(view, const Offset(0, -180));
    await t.pumpAndSettle();
  }
  fail('Form field could not be reached with vertical gestures');
}

void main() {
  testWidgets('preparing an item returns a draft and never writes an intake', (
    t,
  ) async {
    final nutrition = FakeNutrition();
    Json? prepared;
    final strings = lookupAppLocalizations(const Locale('pt', 'BR'));
    await t.pumpWidget(
      mealShell(
        const Locale('pt', 'BR'),
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                prepared = await Navigator.push<Json>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EntryFormPage(
                      food: FoodReference.fromJson(fixtureFood(sourceId)),
                      repository: nutrition,
                      prepareForMeal: true,
                      initialWhen: DateTime.utc(2026, 10, 23, 14),
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
    expect(find.text(strings.prepareMealItem), findsOneWidget);
    expect(find.byKey(const Key('entry-quantity')), findsOneWidget);
    await reach(t, find.byKey(const Key('entry-quantity')));
    await t.enterText(find.byKey(const Key('entry-quantity')), '1,25');
    FocusManager.instance.primaryFocus?.unfocus();
    await scrollFormTo(t, find.text(strings.estimatedChoice));
    await t.tap(find.text(strings.estimatedChoice));
    await t.pumpAndSettle();
    await scrollFormTo(t, find.text(strings.addMealItem));
    await t.tap(find.text(strings.addMealItem));
    await t.pumpAndSettle();
    expect(prepared?['quantity'], '1.25');
    expect(prepared?['revision'], 0);
    expect(prepared?['occurredAt'], '2026-10-23T14:00:00.000Z');
    expect(prepared?['quantityEvidence'], 'estimated');
    expect(nutrition.entryWrites, 0);
    expect(nutrition.foodWrites, 0);
    expect(prepared?.containsKey('calculation'), false);
    expect(t.takeException(), isNull);
  });
  for (final locale in supportedAppLocales) {
    final strings = lookupAppLocalizations(locale);
    for (final dark in [false, true]) {
      testWidgets(
        'draft and shared diary fit 320px/text2x in $locale dark=$dark',
        (t) async {
          small(t);
          final changes = ChangeNotifier();
          addTearDown(changes.dispose);
          final repository = FixtureMeals(), nutrition = FakeNutrition();
          await t.pumpWidget(
            mealShell(
              locale,
              MealDraftPage(
                repository: repository,
                nutrition: nutrition,
                accountId: 'a',
                currentAccountId: () => 'a',
                sessionChanges: changes,
              ),
              dark: dark,
            ),
          );
          await t.pumpAndSettle();
          await reach(t, find.text(strings.mealReviewConfirmation));
          expect(t.takeException(), isNull);
          expect(repository.writes, isEmpty);
          // New screen: no user draft is discarded by the runtime; these are isolated widgets.
          await t.pumpWidget(const SizedBox());
          final date = DateTime.utc(2026, 10, 28);
          await t.pumpWidget(
            mealShell(
              locale,
              MealDiaryPage(
                repository: repository,
                nutrition: nutrition,
                accountId: 'a',
                currentAccountId: () => 'a',
                sessionChanges: changes,
                initialDate: date,
              ),
              dark: dark,
            ),
          );
          await t.pump();
          repository.reads.single.complete(
            MealDay.fromJson(
              dayFixture(zone: '+00:00', locale: locale.toLanguageTag()),
            ),
          );
          await t.pumpAndSettle();
          await reach(t, find.text(strings.mealUnnamed));
          expect(find.text(strings.mealUnnamed), findsOneWidget);
          final count = repository.reads.length;
          await reach(t, find.text(strings.byFood), delta: -250);
          await t.tap(find.text(strings.byFood));
          await t.pumpAndSettle();
          expect(find.text(strings.mealUnnamed), findsNothing);
          expect(repository.reads.length, count);
          expect(repository.writes, isEmpty);
          await reach(t, find.text(strings.daySubtotalCount(1)));
          expect(t.takeException(), isNull);
        },
      );
    }
  }
}
