import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/l10n/locale_controller.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/food_reference/domain/food_reference.dart';
import 'package:trainforge/features/food_reference/presentation/food_detail_page.dart';
import 'package:trainforge/features/home/presentation/pages/today_page.dart';
import 'package:trainforge/features/nutrition/presentation/daily_summary_controller.dart';
import 'package:trainforge/l10n/generated/app_localizations.dart';
import 'package:trainforge/shared/widgets/product_overviews.dart';
import 'food_reference_test.dart' show FixtureFoods, fixtureFood;
import 'today_states_test.dart' show TodayData;

Widget localized(Locale locale, Widget child, {double scale = 1}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedAppLocales,
      theme: TrainForgeTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: child),
    );

void main() {
  final composition = [
    'Composição da fonte',
    'Composição da fonte',
    'Source composition',
    'Composición de la fuente',
  ];
  final trace = [
    'Traço (sem quantidade exata)',
    'Vestígio (sem quantidade exata)',
    'Trace (no exact quantity)',
    'Traza (sin cantidad exacta)',
  ];
  final choose = [
    'Usar esta versão para registrar consumo',
    'Usar esta versão para registar consumo',
    'Use this version to record intake',
    'Usar esta versión para registrar consumo',
  ];
  for (var i = 0; i < supportedAppLocales.length; i++) {
    final locale = supportedAppLocales[i];
    test('plurals distinguish zero, one and several records for $locale', () {
      final strings = lookupAppLocalizations(locale);
      expect(strings.confirmedDayCount(0), isNot(contains('1 ')));
      expect(strings.confirmedDayCount(1), startsWith('1 '));
      expect(strings.confirmedDayCount(2), startsWith('2 '));
      expect(strings.confirmedDayCount(1), isNot(strings.confirmedDayCount(2)));
    });
    testWidgets('food source data and selection stay original for $locale', (
      t,
    ) async {
      t.view.physicalSize = const Size(320, 640);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final food = FoodReference.fromJson(fixtureFood('locale-fixture'));
      FoodReference? selected;
      await t.pumpWidget(
        localized(
          locale,
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await Navigator.push<FoodReference>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoodDetailPage(
                      food: food,
                      repository: FixtureFoods(),
                      selectForConsumption: true,
                    ),
                  ),
                );
              },
              child: const Text('open fixture'),
            ),
          ),
          scale: 2,
        ),
      );
      await t.tap(find.text('open fixture'));
      await t.pumpAndSettle();
      expect(find.text(composition[i]), findsOneWidget);
      expect(find.text('Isolated food locale-fixture'), findsOneWidget);
      await t.scrollUntilVisible(
        find.text(trace[i]),
        300,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      expect(find.text(trace[i]), findsOneWidget);
      expect(find.text('0 g'), findsOneWidget);
      await t.scrollUntilVisible(
        find.text(choose[i]).hitTestable(),
        -300,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      await t.tap(find.text(choose[i]));
      await t.pumpAndSettle();
      expect(selected?.id, food.id);
      expect(selected?.name, food.name);
      expect(selected?.versionId, food.versionId);
      expect(selected?.basisQuantity, isNull);
      expect(t.takeException(), isNull);
    });
    testWidgets(
      'incomplete diary summary never advertises a complete count for $locale',
      (t) async {
        final repo = TodayData()
          ..data = {'entries': 100, 'complete': false, 'nutrients': []};
        final c = DailySummaryController(
          repository: repo,
          accountId: 'fixture',
          currentAccountId: () => 'fixture',
          now: () => DateTime(2026, 10, 26),
        );
        addTearDown(c.dispose);
        await c.load();
        await t.pumpWidget(
          localized(
            locale,
            DailyOverview(
              controller: c,
              name: 'Fixture',
              food: true,
              openNutrition: () {},
              openCatalog: () {},
              openActivity: () {},
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.textContaining('100'), findsNothing);
        expect(c.day, '2026-10-26');
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'localized overview and source previews contain isolated fixtures only',
    (t) async {
      if (!const bool.fromEnvironment('TF_RENDER_LOCALE_READ')) return;
      await t.runAsync(() async {
        await (FontLoader('Inter')
              ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
              ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf')))
            .load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
        await Directory('.local/localization').create(recursive: true);
      });
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      for (final locale in supportedAppLocales) {
        final repo = TodayData()
          ..data = {'entries': 1, 'complete': true, 'nutrients': []};
        final c = DailySummaryController(
          repository: repo,
          accountId: 'fixture',
          currentAccountId: () => 'fixture',
          now: () => DateTime(2026, 10, 26),
        );
        addTearDown(c.dispose);
        await c.load();
        for (final scene in ['today', 'food']) {
          final key = GlobalKey();
          final page = scene == 'today'
              ? TodayPage(
                  controller: c,
                  name: 'Fixture',
                  openNutrition: () {},
                  openCatalog: () {},
                  openActivity: () {},
                )
              : FoodDetailPage(
                  food: FoodReference.fromJson(fixtureFood('locale-fixture')),
                  repository: FixtureFoods(),
                );
          await t.pumpWidget(
            RepaintBoundary(key: key, child: localized(locale, page)),
          );
          await t.pumpAndSettle();
          final boundary =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = (await t.runAsync(
            () => boundary.toImage(pixelRatio: 1),
          ))!;
          final bytes = await t.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.png),
          );
          await t.runAsync(
            () => File(
              '.local/localization/read-$scene-${locale.toLanguageTag()}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List()),
          );
          image.dispose();
          expect(t.takeException(), isNull);
        }
      }
    },
  );
}
