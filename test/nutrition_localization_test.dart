import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:trainforge/features/privacy/presentation/privacy_controller.dart';
import 'package:trainforge/features/privacy/presentation/privacy_page.dart';
import 'package:trainforge/shared/widgets/evaluation_guide_page.dart';
import 'privacy_test.dart' show FixturePrivacy, fixturePolicy;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/l10n/locale_controller.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_forms.dart';
import 'package:trainforge/features/nutrition/presentation/entry_detail_page.dart';
import 'package:trainforge/l10n/generated/app_localizations.dart';
import 'food_reference_test.dart' show fixtureFood;
import 'nutrition_test.dart' show FakeNutrition;
import 'frontend_remaining_flows_test.dart'
    show confirmedFixture, DeleteNutrition;

Finder vertical() => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;
Future<void> reach(WidgetTester t, Finder target, {double delta = 250}) async {
  await t.scrollUntilVisible(
    target.hitTestable(),
    delta,
    scrollable: vertical(),
    maxScrolls: 100,
  );
  await t.pumpAndSettle();
}

Widget shell(Locale locale, Widget page) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: supportedAppLocales,
  theme: TrainForgeTheme.dark,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
    child: child!,
  ),
  home: page,
);
void small(WidgetTester t) {
  t.view.physicalSize = const Size(320, 640);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

void main() {
  for (final locale in supportedAppLocales) {
    final strings = lookupAppLocalizations(locale);
    testWidgets(
      'uncertain retry survives locale change without payload or key change for $locale',
      (t) async {
        small(t);
        final languages = ValueNotifier(locale);
        addTearDown(languages.dispose);
        final repo = FakeNutrition()
          ..error = DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionError,
          );
        final food = asFood(fixtureFood('isolated-locale-write'));
        final page = EntryFormPage(food: food, repository: repo);
        await t.pumpWidget(
          ValueListenableBuilder<Locale>(
            valueListenable: languages,
            builder: (_, locale, _) => shell(locale, page),
          ),
        );
        await t.pumpAndSettle();
        await reach(t, find.byKey(const Key('entry-quantity')));
        await t.enterText(find.byKey(const Key('entry-quantity')), '25,500001');
        await reach(t, find.text(strings.estimatedChoice));
        await t.tap(find.text(strings.estimatedChoice));
        await t.pumpAndSettle();
        await reach(t, find.text(strings.confirmIntake));
        await t.tap(find.text(strings.confirmIntake));
        await t.pumpAndSettle();
        expect(repo.body!['quantity'], '25.500001');
        expect(repo.body!['quantityEvidence'], 'estimated');
        expect(repo.body!['foodId'], food.id);
        expect(repo.body!['foodVersion'], food.versionId);
        expect(repo.body!['revision'], 0);
        expect(repo.body!['occurredAt'], endsWith('Z'));
        final body = jsonEncode(repo.body);
        final key = repo.keys.single;
        expect(find.text(strings.nutritionRetrySafe), findsOneWidget);
        // The locale is presentation state; changing it must not rebuild the draft.
        final next = locale.languageCode == 'en'
            ? const Locale('es')
            : const Locale('en');
        languages.value = next;
        await t.pumpAndSettle();
        final changed = lookupAppLocalizations(next);
        expect(
          t
              .widget<TextFormField>(find.byKey(const Key('entry-quantity')))
              .controller!
              .text,
          '25,500001',
        );
        expect(
          t
              .widget<TextFormField>(find.byKey(const Key('entry-quantity')))
              .enabled,
          false,
        );
        expect(find.text(changed.nutritionRetrySafe), findsOneWidget);
        await t.state<NavigatorState>(find.byType(Navigator).first).maybePop();
        await t.pumpAndSettle();
        expect(find.text(changed.checkBeforeLeaving), findsOneWidget);
        expect(find.text(changed.uncertainDraftNotice), findsOneWidget);
        await t.tap(find.text(changed.continueEditing));
        await t.pumpAndSettle();
        await reach(t, find.text(changed.retryConfirmation));
        await t.tap(find.text(changed.retryConfirmation));
        await t.pumpAndSettle();
        expect(repo.entryWrites, 2);
        expect(repo.keys, [key, key]);
        expect(jsonEncode(repo.body), body);
        expect(t.takeException(), isNull);
      },
    );
    testWidgets('private food keeps unknown distinct from zero for $locale', (
      t,
    ) async {
      small(t);
      final repo = FakeNutrition();
      await t.pumpWidget(shell(locale, OwnFoodFormPage(repository: repo)));
      await t.pumpAndSettle();
      await reach(t, find.byKey(const Key('own-food-name')));
      await t.enterText(
        find.byKey(const Key('own-food-name')),
        'Fixture original name',
      );
      for (var i = 0; i < 2; i++) {
        await reach(t, find.text(strings.addNutrient));
        await t.tap(find.text(strings.addNutrient));
        await t.pumpAndSettle();
        final name = find
            .widgetWithText(TextFormField, strings.nutrientName)
            .last;
        await reach(t, name, delta: -250);
        await t.enterText(name, i == 0 ? 'Fixture unknown' : 'Fixture zero');
        if (i == 1) {
          final value = find
              .widgetWithText(TextFormField, strings.optionalBasisValue)
              .last;
          await reach(t, value);
          await t.enterText(value, '0');
        }
      }
      await reach(t, find.text(strings.saveFoodOnly));
      await t.tap(find.text(strings.saveFoodOnly));
      await t.pumpAndSettle();
      expect(repo.foodWrites, 1);
      expect(repo.entryWrites, 0);
      expect(repo.body!['name'], 'Fixture original name');
      expect(repo.body!['basis'], {'quantity': null, 'unit': null});
      expect(repo.body!['nutrients'], [
        {'name': 'Fixture unknown', 'unit': 'g', 'value': null},
        {'name': 'Fixture zero', 'unit': 'g', 'value': '0'},
      ]);
      expect(t.takeException(), isNull);
    });
    testWidgets('localized deletion can be canceled at320 text2x for $locale', (
      t,
    ) async {
      small(t);
      final repo = DeleteNutrition();
      final entry = confirmedFixture();
      final before = jsonEncode(entry);
      await t.pumpWidget(
        shell(locale, EntryDetailPage(entry: entry, repository: repo)),
      );
      await t.pumpAndSettle();
      await reach(t, find.text(strings.deleteThisIntake));
      await t.tap(find.text(strings.deleteThisIntake));
      await t.pumpAndSettle();
      expect(find.text(strings.deleteIntakeQuestion), findsOneWidget);
      expect(find.text(strings.deleteIntakeNotice), findsOneWidget);
      await t.tap(find.text(strings.cancel));
      await t.pumpAndSettle();
      expect(repo.deletions, 0);
      expect(jsonEncode(entry), before);
      expect(t.takeException(), isNull);
    });
    testWidgets(
      'privacy phrase and effective policy stay original for $locale',
      (t) async {
        small(t);
        final repo = FixturePrivacy();
        final controller = PrivacyController(repo);
        addTearDown(controller.dispose);
        await t.pumpWidget(
          shell(
            locale,
            PrivacyPage(authenticated: true, controller: controller),
          ),
        );
        await t.pumpAndSettle();
        await reach(t, find.text(strings.policyOriginalNotice));
        expect(find.text(strings.policyOriginalNotice), findsOneWidget);
        await reach(t, find.text(fixturePolicy().accountDeletion));
        expect(find.text(fixturePolicy().accountDeletion), findsOneWidget);
        await reach(t, find.text(strings.readDeletionLimits));
        await t.tap(find.text(strings.readDeletionLimits));
        await t.pumpAndSettle();
        await reach(t, find.text(strings.requestDeletionIntent));
        await t.tap(find.text(strings.requestDeletionIntent));
        await t.pumpAndSettle();
        await reach(t, find.byType(TextField));
        await t.enterText(find.byType(TextField), 'DELETE MY ACCOUNT');
        await reach(t, find.text(strings.deleteAccountData));
        expect(
          t
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, strings.deleteAccountData),
              )
              .onPressed,
          isNull,
        );
        await reach(t, find.byType(TextField), delta: -200);
        await t.enterText(find.byType(TextField), 'EXCLUIR MINHA CONTA');
        await reach(t, find.text(strings.deleteAccountData));
        expect(
          t
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, strings.deleteAccountData),
              )
              .onPressed,
          isNotNull,
        );
        await reach(t, find.text(strings.cancelDeletion));
        await t.tap(find.text(strings.cancelDeletion));
        await t.pumpAndSettle();
        expect(controller.deletionIntent, isNull);
        expect(repo.intents, 1);
        expect(repo.erases, 0);
        expect(t.takeException(), isNull);
      },
    );
    testWidgets(
      'all help topics fit and match available preferences for $locale',
      (t) async {
        small(t);
        for (final topic in EvaluationTopic.values) {
          await t.pumpWidget(
            shell(
              locale,
              EvaluationGuidePage(key: ValueKey(topic), topic: topic),
            ),
          );
          await t.pumpAndSettle();
          if (topic == EvaluationTopic.profile) {
            await reach(t, find.text(strings.devicePreferencesHint));
            expect(find.text(strings.devicePreferencesHint), findsOneWidget);
          }
          if (topic == EvaluationTopic.firstAccess) {
            await reach(t, find.text(strings.scopeCaregivers));
            expect(find.text(strings.scopeCaregivers), findsOneWidget);
          }
          await reach(t, find.text(strings.browseFoods));
          expect(t.takeException(), isNull);
        }
      },
    );
  }
  testWidgets('localized form previews contain fixtures only', (t) async {
    if (!const bool.fromEnvironment('TF_RENDER_LOCALE_WRITE')) return;
    await t.runAsync(() async {
      final font = FontLoader('Inter')
        ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final repo = FakeNutrition();
    for (final locale in [const Locale('en'), const Locale('pt', 'PT')]) {
      final boundary = GlobalKey();
      await t.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedAppLocales,
          theme: TrainForgeTheme.dark,
          home: RepaintBoundary(
            key: boundary,
            child: EntryFormPage(
              key: ValueKey(locale),
              food: asFood(fixtureFood('isolated-preview')),
              repository: repo,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(
          '.local/localization/portion-${locale.toLanguageTag()}.png',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
      });
    }
    expect(repo.entryWrites, 0);
    expect(repo.foodWrites, 0);
  });
}
