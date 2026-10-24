import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/catalog/presentation/catalog_page.dart';
import 'package:trainforge/features/catalog/presentation/catalog_detail_page.dart';
import 'package:trainforge/features/catalog/presentation/catalog_controller.dart';
import 'package:trainforge/features/food_reference/presentation/food_detail_page.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_forms.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_page.dart';
import 'package:trainforge/features/nutrition/presentation/entry_detail_page.dart';
import 'package:trainforge/features/privacy/presentation/privacy_page.dart';
import 'package:trainforge/features/privacy/presentation/privacy_controller.dart';
import 'package:trainforge/shared/widgets/evaluation_guide_page.dart';
import 'catalog_test.dart' show FixtureCatalog, entry;
import 'food_reference_test.dart' show fixtureFood, FixtureFoods;
import 'nutrition_test.dart' show FakeNutrition, chooseEvidence;
import 'privacy_test.dart' show FixturePrivacy;

Json confirmedFixture() => {
  'id': 'isolated-consumption',
  'foodVersion': 'a' * 64,
  'quantity': '1',
  'unit': 'g',
  'occurredAt': '2026-10-23T15:15:00Z',
  'timezone': '+00:00',
  'calculation': {
    'food': fixtureFood('isolated-detail'),
    'quantityEvidence': 'estimated',
    'preparation': '',
    'revision': 0,
    'origin': 'editorial',
    'algorithm': 'isolated-fixture-only',
    'changes': <Json>[],
    'nutrients': <Json>[
      {
        'nameOriginal': 'Fixture nutrient',
        'value': null,
        'unit': 'g',
        'reason': 'Base desconhecida',
        'sourceState': 'missing',
        'rawText': '-',
        'sourceUpperBound': null,
        'basis': {'quantity': null, 'unit': null},
        'factor': null,
        'exactFraction': null,
      },
    ],
  },
};

class DeleteNutrition extends FakeNutrition {
  int deletions = 0;
  @override
  Future<void> deleteEntry(String id, int revision, String key) async {
    deletions++;
  }
}

class SearchNutrition extends FakeNutrition {
  int entryReads = 0, summaryReads = 0;
  final queries = <String>[];
  final requests = <String, Completer<NutritionPageData>>{};
  final ownErrors = <String, Object>{};
  @override
  Future<NutritionPageData> entries(
    String day,
    String zone, {
    String? cursor,
  }) async {
    entryReads++;
    return NutritionPageData.fromJson({
      'items': [confirmedFixture()],
      'nextCursor': null,
    });
  }

  @override
  Future<Json> summary(String day, String zone) async {
    summaryReads++;
    return {
      'entries': 1,
      'complete': true,
      'nutrients': <Json>[],
      'notice': 'Isolated summary',
      'measuredEntries': 0,
      'estimatedEntries': 1,
    };
  }

  @override
  Future<NutritionPageData> foods({String q = '', String? cursor}) async {
    queries.add(q);
    if (ownErrors[q] != null) throw ownErrors[q]!;
    if (requests[q] != null) return requests[q]!.future;
    return NutritionPageData.fromJson({
      'items': [fixtureFood(q.isEmpty ? 'own-default' : q)],
      'nextCursor': null,
    });
  }
}

class PagedSearchNutrition extends SearchNutrition {
  final pageQueries = <String>[];
  @override
  Future<NutritionPageData> foods({String q = '', String? cursor}) async {
    if (cursor != null) {
      pageQueries.add(q);
      return NutritionPageData.fromJson({
        'items': <Json>[],
        'nextCursor': null,
      });
    }
    return NutritionPageData.fromJson({
      'items': [fixtureFood('page')],
      'nextCursor': 'isolated-cursor',
    });
  }
}

Future<void> openForm(
  WidgetTester t,
  Widget form,
  GlobalKey<NavigatorState> key,
) async {
  await t.pumpWidget(
    MaterialApp(
      navigatorKey: key,
      theme: TrainForgeTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => form),
            ),
            child: const Text('Abrir formulário'),
          ),
        ),
      ),
    ),
  );
  await t.tap(find.text('Abrir formulário'));
  await t.pumpAndSettle();
}

void main() {
  for (final own in [false, true]) {
    testWidgets(
      'back asks before discarding and cancellation preserves draft own=$own',
      (t) async {
        final r = FakeNutrition(), nav = GlobalKey<NavigatorState>();
        await openForm(
          t,
          own
              ? OwnFoodFormPage(repository: r)
              : EntryFormPage(
                  food: asFood(fixtureFood('draft')),
                  repository: r,
                ),
          nav,
        );
        final field = find.byKey(Key(own ? 'own-food-name' : 'entry-quantity'));
        await t.ensureVisible(field);
        await t.enterText(field, own ? 'Isolated draft' : '12,5');
        await t.pump();
        await nav.currentState!.maybePop();
        await t.pumpAndSettle();
        expect(find.text('Sair sem salvar?'), findsOneWidget);
        await t.tap(find.text('Continuar preenchendo'));
        await t.pumpAndSettle();
        expect(
          t.widget<TextFormField>(field).controller!.text,
          own ? 'Isolated draft' : '12,5',
        );
        await nav.currentState!.maybePop();
        await t.pumpAndSettle();
        await t.tap(find.text('Descartar rascunho'));
        await t.pumpAndSettle();
        expect(find.text('Abrir formulário'), findsOneWidget);
        expect(r.entryWrites + r.foodWrites, 0);
      },
    );
  }
  testWidgets(
    'back during send is blocked and ambiguous exit explains server uncertainty',
    (t) async {
      final r = FakeNutrition()..pending = Completer<Json>(),
          nav = GlobalKey<NavigatorState>();
      await openForm(
        t,
        EntryFormPage(food: asFood(fixtureFood('pending')), repository: r),
        nav,
      );
      await t.enterText(find.byKey(const Key('entry-quantity')), '1');
      await chooseEvidence(t);
      await t.ensureVisible(find.text('Confirmar consumo'));
      await t.tap(find.text('Confirmar consumo'));
      await t.pump();
      await nav.currentState!.maybePop();
      await t.pump();
      expect(find.text('Sair sem salvar?'), findsNothing);
      expect(find.text('Confirmando…'), findsOneWidget);
      r.pending!.completeError(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );
      await t.pumpAndSettle();
      await nav.currentState!.maybePop();
      await t.pumpAndSettle();
      expect(find.text('Conferir antes de sair'), findsOneWidget);
      expect(
        find.textContaining('Sair não cancela a solicitação'),
        findsOneWidget,
      );
      await t.tap(find.text('Continuar preenchendo'));
      await t.pumpAndSettle();
      expect(r.entryWrites, 1);
    },
  );
  testWidgets(
    'own food validates nutrient fields scrolled away with keyboard and large text',
    (t) async {
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final r = FakeNutrition();
      await t.pumpWidget(
        MaterialApp(
          theme: TrainForgeTheme.dark,
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c).copyWith(
              textScaler: TextScaler.linear(2),
              viewInsets: const EdgeInsets.only(bottom: 180),
            ),
            child: child!,
          ),
          home: OwnFoodFormPage(repository: r),
        ),
      );
      await t.ensureVisible(find.byKey(const Key('own-food-name')));
      await t.enterText(
        find.byKey(const Key('own-food-name')),
        'Isolated draft',
      );
      await t.ensureVisible(
        find.text('Adicionar nutriente conhecido ou desconhecido'),
      );
      await t.tap(find.text('Adicionar nutriente conhecido ou desconhecido'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Salvar somente o alimento'));
      await t.tap(find.text('Salvar somente o alimento'));
      await t.pumpAndSettle();
      expect(r.foodWrites, 0);
      expect(find.text('Informe o nome do nutriente.'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'private-food search is debounced, ignores old replies and does not refetch history',
    (t) async {
      final r = SearchNutrition(), session = ValueNotifier(0);
      addTearDown(session.dispose);
      r.requests['old'] = Completer<NutritionPageData>();
      await t.pumpWidget(
        MaterialApp(
          theme: TrainForgeTheme.dark,
          home: NutritionPage(
            accountId: 'isolated',
            currentAccountId: () => 'isolated',
            sessionChanges: session,
            repository: r,
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Meus alimentos'));
      await t.pumpAndSettle();
      final field = find.byType(TextField);
      await t.ensureVisible(field);
      await t.enterText(field, 'old');
      await t.pump(const Duration(milliseconds: 401));
      await t.enterText(field, 'new');
      await t.pump(const Duration(milliseconds: 401));
      await t.pumpAndSettle();
      r.requests['old']!.complete(
        NutritionPageData.fromJson({
          'items': [fixtureFood('old')],
          'nextCursor': null,
        }),
      );
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('Isolated food new'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Isolated food old'), findsNothing);
      expect(find.text('Isolated food new'), findsOneWidget);
      expect(r.entryReads, 1);
      expect(r.summaryReads, 1);
      expect(r.queries, ['', 'old', 'new']);
    },
  );
  testWidgets(
    'pagination keeps the applied query while new typing is debounced',
    (t) async {
      final r = PagedSearchNutrition(), session = ValueNotifier(0);
      addTearDown(session.dispose);
      await t.pumpWidget(
        MaterialApp(
          theme: TrainForgeTheme.dark,
          home: NutritionPage(
            accountId: 'isolated',
            currentAccountId: () => 'isolated',
            sessionChanges: session,
            repository: r,
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Meus alimentos'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.byType(TextField));
      await t.enterText(find.byType(TextField), 'not-applied-yet');
      await t.scrollUntilVisible(
        find.text('Carregar mais alimentos próprios'),
        120,
        scrollable: find.byType(Scrollable).last,
        duration: Duration.zero,
      );
      await t.tap(find.text('Carregar mais alimentos próprios'));
      await t.pump();
      expect(r.pageQueries, ['']);
      await t.pump(const Duration(milliseconds: 401));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'a private-food lookup failure does not hide confirmed diary entries',
    (t) async {
      final r = SearchNutrition(), session = ValueNotifier(0);
      addTearDown(session.dispose);
      r.ownErrors['failed'] = StateError('private-error-must-not-leak');
      await t.pumpWidget(
        MaterialApp(
          theme: TrainForgeTheme.light,
          home: NutritionPage(
            accountId: 'isolated',
            currentAccountId: () => 'isolated',
            sessionChanges: session,
            repository: r,
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Meus alimentos'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.byType(TextField));
      await t.enterText(find.byType(TextField), 'failed');
      await t.pump(const Duration(milliseconds: 401));
      await t.pumpAndSettle();
      expect(find.textContaining('private-error'), findsNothing);
      await t.tap(find.text('Consumo'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('Isolated food isolated-detail'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Isolated food isolated-detail'), findsOneWidget);
      expect(r.entryReads, 1);
      expect(r.summaryReads, 1);
    },
  );
  testWidgets('canceling consumption deletion leaves the fixture untouched', (
    t,
  ) async {
    final r = DeleteNutrition();
    await t.pumpWidget(
      MaterialApp(
        theme: TrainForgeTheme.dark,
        home: EntryDetailPage(entry: confirmedFixture(), repository: r),
      ),
    );
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
      find.text('Excluir este consumo'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.text('Excluir este consumo'));
    await t.pumpAndSettle();
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(find.byType(EntryDetailPage), findsOneWidget);
    expect(r.deletions, 0);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'all available families scroll in both themes at320 with text2x',
    (t) async {
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final session = ValueNotifier(0);
      addTearDown(session.dispose);
      for (final theme in [TrainForgeTheme.light, TrainForgeTheme.dark]) {
        final privacy = PrivacyController(FixturePrivacy());
        final catalog = CatalogController(FixtureCatalog());
        for (final page in <Widget>[
          CatalogPage(controller: catalog),
          CatalogDetailPage(entry: entry('test'), repository: FixtureCatalog()),
          FoodDetailPage(
            food: asFood(fixtureFood('test')),
            repository: FixtureFoods(),
          ),
          NutritionPage(
            accountId: 'isolated',
            currentAccountId: () => 'isolated',
            sessionChanges: session,
            repository: SearchNutrition(),
          ),
          OwnFoodFormPage(repository: FakeNutrition()),
          EntryDetailPage(
            entry: confirmedFixture(),
            repository: FakeNutrition(),
          ),
          PrivacyPage(authenticated: true, controller: privacy),
          for (final topic in EvaluationTopic.values)
            EvaluationGuidePage(topic: topic),
        ]) {
          await t.pumpWidget(
            MaterialApp(
              key: UniqueKey(),
              theme: theme,
              builder: (c, child) => MediaQuery(
                data: MediaQuery.of(c).copyWith(
                  textScaler: TextScaler.linear(2),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: page,
            ),
          );
          await t.pumpAndSettle();
          expect(
            t.takeException(),
            isNull,
            reason: page.runtimeType.toString(),
          );
          final scroll = find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          );
          if (scroll.evaluate().isNotEmpty) {
            await t.drag(scroll.first, const Offset(0, -900));
            await t.pumpAndSettle();
          }
          expect(
            t.takeException(),
            isNull,
            reason: page.runtimeType.toString(),
          );
        }
        await t.pumpWidget(const SizedBox.shrink());
        privacy.dispose();
        catalog.dispose();
      }
    },
  );
  testWidgets('read-only flows expose labeled48px Android targets', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final semantics = t.ensureSemantics();
    for (final dark in [false, true]) {
      final catalog = CatalogController(FixtureCatalog());
      for (final page in <Widget>[
        CatalogPage(controller: catalog),
        const EvaluationGuidePage(),
      ]) {
        await t.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            theme: dark ? TrainForgeTheme.dark : TrainForgeTheme.light,
            home: page,
          ),
        );
        await t.pumpAndSettle();
        await expectLater(t, meetsGuideline(androidTapTargetGuideline));
        await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      }
      await t.pumpWidget(const SizedBox.shrink());
      catalog.dispose();
    }
    semantics.dispose();
  });
  testWidgets('stage07to12 visual artifacts contain isolated fixtures only', (
    t,
  ) async {
    if (!const bool.fromEnvironment('TF_RENDER_REMAINING')) return;
    await t.runAsync(() async {
      final font = FontLoader('Inter')
        ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
      await font.load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final session = ValueNotifier(0);
    addTearDown(session.dispose);
    for (final dark in [false, true]) {
      final theme = dark ? TrainForgeTheme.dark : TrainForgeTheme.light;
      final privacy = PrivacyController(FixturePrivacy()),
          catalog = CatalogController(FixtureCatalog());
      final pages = <String, Widget>{
        'library': CatalogPage(controller: catalog),
        'reference': CatalogDetailPage(
          entry: entry('test'),
          repository: FixtureCatalog(),
        ),
        'composition': FoodDetailPage(
          food: asFood(fixtureFood('test')),
          repository: FixtureFoods(),
        ),
        'history': NutritionPage(
          accountId: 'isolated',
          currentAccountId: () => 'isolated',
          sessionChanges: session,
          repository: SearchNutrition(),
        ),
        'own-food': OwnFoodFormPage(repository: FakeNutrition()),
        'confirmation': EntryDetailPage(
          entry: confirmedFixture(),
          repository: FakeNutrition(),
        ),
        'privacy': PrivacyPage(authenticated: true, controller: privacy),
        'configuration': const EvaluationGuidePage(
          topic: EvaluationTopic.firstAccess,
        ),
        'activity': const EvaluationGuidePage(topic: EvaluationTopic.activity),
        'help': const EvaluationGuidePage(),
      };
      for (final row in pages.entries) {
        final boundary = GlobalKey();
        await t.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              key: UniqueKey(),
              debugShowCheckedModeBanner: false,
              theme: theme,
              home: row.value,
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        final render =
            boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final image = (await t.runAsync(() => render.toImage(pixelRatio: 1)))!;
        final png = await t.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.png),
        );
        await t.runAsync(() async {
          await File(
            '.local/android-evaluation/remaining-${row.key}-${dark ? 'dark' : 'light'}.png',
          ).writeAsBytes(png!.buffer.asUint8List());
        });
        image.dispose();
      }
      await t.pumpWidget(const SizedBox.shrink());
      privacy.dispose();
      catalog.dispose();
    }
  });
}
