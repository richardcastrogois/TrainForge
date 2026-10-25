import 'package:trainforge/features/catalog/presentation/catalog_controller.dart';
import 'package:trainforge/shared/widgets/plans_overview.dart';
import 'package:trainforge/shared/widgets/account_page.dart';
import 'catalog_test.dart' show FixtureCatalog;
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/auth/domain/auth_profile.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/presentation/daily_summary_controller.dart';
import 'package:trainforge/shared/widgets/auth_gate.dart';
import 'package:trainforge/shared/widgets/figma_bottom_nav.dart';
import 'package:trainforge/shared/widgets/product_shell.dart';
import 'package:trainforge/shared/widgets/product_overviews.dart';
import 'auth_controller_test.dart' show SessionFixture, fixtureProfile, outage;
import 'nutrition_test.dart' show FakeNutrition;

class SummaryFixture extends FakeNutrition {
  final requests = <Completer<Json>>[];
  final days = <String>[];
  @override
  Future<Json> summary(String day, String zone) {
    days.add(day);
    final pending = Completer<Json>();
    requests.add(pending);
    return pending.future;
  }
}

Json snapshot(int count) => {
  'entries': count,
  'complete': true,
  'nutrients': [],
};
Json kcal(String value) => {
  'unit': 'kcal',
  'value': value,
  'includedEntries': 1,
  'unknownEntries': 0,
};

class DraftTab extends StatefulWidget {
  const DraftTab({super.key});
  @override
  State<DraftTab> createState() => _DraftTabState();
}

class _DraftTabState extends State<DraftTab> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(controller: controller);
}

void main() {
  test(
    'energy never combines methods, hides unknowns and retains integer zeroes',
    () {
      Json summary(List<Json> cells, {bool complete = true}) => {
        'entries': 1,
        'complete': complete,
        'nutrients': cells,
      };
      expect(dailyEnergy(summary([kcal('100.000000')])), '100');
      expect(dailyEnergy(summary([kcal('100')])), '100');
      expect(dailyEnergy(summary([kcal('0.000000')])), '0');
      expect(dailyEnergy(summary([kcal('0.123456')])), '0,123456');
      expect(dailyEnergy(summary([kcal('12'), kcal('13')])), isNull);
      expect(
        dailyEnergy(
          summary([
            {...kcal('12'), 'unknownEntries': 1},
          ]),
        ),
        isNull,
      );
      expect(dailyEnergy(summary([kcal('12')], complete: false)), isNull);
      expect(dailyEnergy(snapshot(0)), isNull);
    },
  );
  test(
    'summary ignores stale requests, account changes and late disposal',
    () async {
      final repo = SummaryFixture();
      String? owner = fixtureProfile.id;
      final controller = DailySummaryController(
        repository: repo,
        accountId: owner,
        currentAccountId: () => owner,
      );
      final a = controller.load(), b = controller.load();
      repo.requests[1].complete(snapshot(2));
      await b;
      repo.requests[0].complete(snapshot(1));
      await a;
      expect(controller.summary!['entries'], 2);
      final c = controller.load();
      controller.dispose();
      repo.requests[2].complete(snapshot(3));
      await c;
      final other = DailySummaryController(
        repository: repo,
        accountId: owner,
        currentAccountId: () => owner,
      );
      final d = other.load();
      owner = 'different-account';
      repo.requests[3].complete(snapshot(4));
      await d;
      expect(other.summary, isNull);
      other.dispose();
    },
  );
  test(
    'new day clears old snapshot and failed refresh never displays a false zero',
    () async {
      final repo = SummaryFixture();
      var now = DateTime(2026, 10, 23);
      final controller = DailySummaryController(
        repository: repo,
        accountId: 'fixture',
        currentAccountId: () => 'fixture',
        now: () => now,
      );
      var load = controller.load();
      repo.requests.last.complete(snapshot(1));
      await load;
      now = DateTime(2026, 10, 24);
      load = controller.load();
      expect(controller.summary, isNull);
      repo.requests.last.completeError(StateError('offline'));
      await load;
      expect(controller.failed, true);
      expect(controller.summary, isNull);
      expect(repo.days.last, '2026-10-24');
      controller.dispose();
    },
  );
  testWidgets(
    'tabs build lazily, keep draft state, and Android back returns to Hoje',
    (t) async {
      final auth = AuthController(SessionFixture())..profile = fixtureProfile;
      addTearDown(auth.dispose);
      final built = <TrainForgeDestination>{};
      await t.pumpWidget(
        MaterialApp(
          theme: TrainForgeTheme.light,
          home: ProductShell(
            controller: auth,
            nutritionRepository: FakeNutrition(),
            pageBuilder: (destination) {
              built.add(destination);
              return destination == TrainForgeDestination.plans
                  ? const DraftTab()
                  : Text(destination.label);
            },
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(built, {TrainForgeDestination.today});
      await t.tap(find.byTooltip('Planos'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'rascunho preservado');
      await t.tap(find.byTooltip('Diário'));
      await t.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      await t.tap(find.byTooltip('Planos'));
      await t.pumpAndSettle();
      expect(find.text('rascunho preservado'), findsOneWidget);
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.text('Hoje'), findsOneWidget);
      expect(find.text('rascunho preservado'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'profile survives offline refresh and account erasure removes private routes',
    (t) async {
      final repo = SessionFixture()..profile = fixtureProfile;
      final auth = AuthController(repo);
      addTearDown(auth.dispose);
      await t.pumpWidget(
        MaterialApp(
          theme: TrainForgeTheme.light,
          home: AuthGate(
            controller: auth,
            nutritionRepository: FakeNutrition(),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Diário'));
      await t.pumpAndSettle();
      repo.restoreError = outage();
      await auth.restore();
      await t.pumpAndSettle();
      expect(find.byType(ProductShell), findsOneWidget);
      final nav = t.widget<FigmaBottomNav>(find.byType(FigmaBottomNav));
      expect(nav.selected, TrainForgeDestination.food);
      await t.tap(find.byTooltip('Abrir perfil'));
      await t.pumpAndSettle();
      expect(find.text(fixtureProfile.email), findsOneWidget);
      auth.accountErased(fixtureProfile.id);
      await t.pumpAndSettle();
      expect(find.text(fixtureProfile.email), findsNothing);
      expect(find.text('Entrar com Google'), findsOneWidget);
      expect(find.byType(ProductShell), findsNothing);
    },
  );
  testWidgets(
    'overview families fit 320px and enlarged text without demo metrics',
    (t) async {
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final daily = DailySummaryController(
        repository: FakeNutrition(),
        accountId: 'fixture',
        currentAccountId: () => 'fixture',
      );
      addTearDown(daily.dispose);
      await daily.load();
      final plans = CatalogController(FixtureCatalog());
      final auth = AuthController(SessionFixture())..profile = fixtureProfile;
      addTearDown(plans.dispose);
      addTearDown(auth.dispose);
      for (final page in <Widget>[
        PlansOverview(controller: plans),
        AccountPage(controller: auth),
        DailyOverview(
          controller: daily,
          name: 'Pessoa de avaliação',
          food: false,
          openNutrition: () {},
          openCatalog: () {},
          openActivity: () {},
        ),
        DailyOverview(
          controller: daily,
          name: 'Pessoa',
          food: true,
          openNutrition: () {},
          openCatalog: () {},
          openActivity: () {},
        ),
        const ActivityOverview(),
        EvolutionOverview(openNutrition: () {}),
      ]) {
        await t.pumpWidget(
          MaterialApp(
            theme: TrainForgeTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(body: page),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text('1480'), findsNothing);
        expect(find.text('135'), findsNothing);
        expect(find.text('3,20'), findsNothing);
        expect(t.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'today visual artifact uses bundled Inter and public isolated fixture only',
    (t) async {
      if (!const bool.fromEnvironment('TF_RENDER_SHELL')) return;
      await t.runAsync(() async {
        final font = FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
        await font.load();
      });
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final auth = AuthController(SessionFixture())
        ..profile = const AuthProfile(
          id: 'preview.invalid',
          name: 'Avaliação',
          email: 'preview@example.invalid',
        );
      addTearDown(auth.dispose);
      final plans = CatalogController(FixtureCatalog());
      addTearDown(plans.dispose);
      final key = GlobalKey();
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: TrainForgeTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(
                padding: EdgeInsets.only(top: 24, bottom: 24),
              ),
              child: ProductShell(
                controller: auth,
                nutritionRepository: FakeNutrition(),
                plansController: plans,
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      Future<void> capture(String name) async {
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
            '.local/android-evaluation/$name-shell-preview.png',
          ).writeAsBytes(bytes!.buffer.asUint8List()),
        );
        image.dispose();
      }

      await capture('today');
      for (final destination in TrainForgeDestination.values.skip(1)) {
        await t.tap(find.byTooltip(destination.label));
        await t.pumpAndSettle();
        await capture(destination.name);
      }
      await t.tap(find.byTooltip('Abrir perfil'));
      await t.pumpAndSettle();
      await capture('profile');
      expect(t.takeException(), isNull);
    },
  );
}
