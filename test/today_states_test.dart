import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/home/presentation/pages/today_page.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/presentation/daily_summary_controller.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'nutrition_test.dart' show FakeNutrition;

class TodayData extends FakeNutrition {
  Json data = {'entries': 0, 'complete': true, 'nutrients': []};
  Object? failure;
  int calls = 0;
  @override
  Future<Json> summary(String day, String zone) async {
    calls++;
    if (failure != null) throw failure!;
    return pending == null ? data : pending!.future;
  }
}

void main() {
  testWidgets(
    'Hoje distinguishes loading, failure, empty and partial without fabricated totals',
    (t) async {
      final repo = TodayData()..pending = Completer<Json>();
      final c = DailySummaryController(
        repository: repo,
        accountId: 'fixture',
        currentAccountId: () => 'fixture',
      );
      addTearDown(c.dispose);
      final task = c.load();
      await t.pumpWidget(
        MaterialApp(
          theme: TrainForgeTheme.light,
          home: Scaffold(
            body: TodayPage(
              controller: c,
              name: '',
              openNutrition: () {},
              openCatalog: () {},
              openActivity: () {},
            ),
          ),
        ),
      );
      await t.pump();
      expect(find.byType(AppMetricSkeleton), findsOneWidget);
      expect(find.text('Bora mexer!'), findsOneWidget);
      repo.pending!.complete({'entries': 0, 'complete': true, 'nutrients': []});
      await task;
      await t.pumpAndSettle();
      expect(find.text('Nenhum consumo confirmado neste dia'), findsOneWidget);
      repo.pending = null;
      repo.failure = StateError('private error');
      await c.load();
      await t.pumpAndSettle();
      expect(find.text('Não foi possível atualizar o dia.'), findsOneWidget);
      expect(find.textContaining('private error'), findsNothing);
      expect(find.text('Nenhum consumo confirmado neste dia'), findsNothing);
      repo.failure = null;
      repo.data = {'entries': 100, 'complete': false, 'nutrients': []};
      await c.load();
      await t.pumpAndSettle();
      expect(find.textContaining('limite do resumo'), findsOneWidget);
      expect(find.textContaining('100 consumos'), findsNothing);
    },
  );
  testWidgets(
    'week uses real dates across month boundaries and keeps48px targets',
    (t) async {
      final repo = TodayData();
      final c = DailySummaryController(
        repository: repo,
        accountId: 'fixture',
        currentAccountId: () => 'fixture',
        now: () => DateTime(2026, 11, 1),
      );
      addTearDown(c.dispose);
      await c.load();
      DateTime? opened;
      await t.pumpWidget(
        MaterialApp(
          theme: TrainForgeTheme.light,
          home: Scaffold(
            body: TodayPage(
              controller: c,
              name: 'Pessoa',
              openNutrition: () {},
              openCatalog: () {},
              openActivity: () {},
              openDay: (d) => opened = d,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final date = find.bySemanticsLabel('Consultar alimentação de 26/10/2026');
      expect(date, findsOneWidget);
      expect(t.getSize(date).width, greaterThanOrEqualTo(48));
      await t.tap(date);
      await t.pumpAndSettle();
      expect(opened, DateTime(2026, 10, 26));
      expect(find.text('✓'), findsNothing);
    },
  );
  testWidgets('foreground midnight refreshes once into the new local day', (
    t,
  ) async {
    var now = DateTime(2026, 10, 23, 23, 59, 59);
    final repo = TodayData();
    final c = DailySummaryController(
      repository: repo,
      accountId: 'fixture',
      currentAccountId: () => 'fixture',
      now: () => now,
    );
    addTearDown(c.dispose);
    await c.load();
    await t.pumpWidget(
      MaterialApp(
        theme: TrainForgeTheme.light,
        home: Scaffold(
          body: TodayPage(
            controller: c,
            name: 'Pessoa',
            openNutrition: () {},
            openCatalog: () {},
            openActivity: () {},
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    now = DateTime(2026, 10, 24);
    await t.pump(const Duration(seconds: 2));
    await t.pumpAndSettle();
    expect(repo.calls, 2);
    expect(c.day, '2026-10-24');
  });
}
