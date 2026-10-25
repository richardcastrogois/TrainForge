import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_controller.dart';
import 'nutrition_test.dart' show FakeNutrition;

class DeferredNutrition extends FakeNutrition {
  final entryReads = <Completer<NutritionPageData>>[];
  final summaryReads = <Completer<Json>>[];
  final ownReads = <Completer<NutritionPageData>>[];
  @override
  Future<NutritionPageData> entries(String day, String zone, {String? cursor}) {
    final pending = Completer<NutritionPageData>();
    entryReads.add(pending);
    return pending.future;
  }

  @override
  Future<Json> summary(String day, String zone) {
    final pending = Completer<Json>();
    summaryReads.add(pending);
    return pending.future;
  }

  @override
  Future<NutritionPageData> foods({String q = '', String? cursor}) {
    final pending = Completer<NutritionPageData>();
    ownReads.add(pending);
    return pending.future;
  }
}

NutritionPageData page(String id) => NutritionPageData.fromJson({
  'items': [
    {'id': id},
  ],
  'nextCursor': null,
});

void main() {
  test(
    'late replies from another day cannot replace the selected day',
    () async {
      final repo = DeferredNutrition();
      final c = NutritionController(
        repository: repo,
        accountId: 'isolated-account',
        currentAccountId: () => 'isolated-account',
        initialDate: DateTime(2026, 10, 24),
      );
      addTearDown(c.dispose);
      final old = c.load();
      final latest = c.selectDate(DateTime(2026, 10, 25));
      repo.entryReads.last.complete(page('new-day'));
      repo.summaryReads.last.complete({'notice': 'new-day'});
      await latest;
      expect(c.entries.single['id'], 'new-day');
      expect(c.summary!['notice'], 'new-day');
      expect(c.loading, false);
      repo.entryReads.first.complete(page('old-day'));
      repo.summaryReads.first.complete({'notice': 'old-day'});
      await old;
      expect(c.entries.single['id'], 'new-day');
      expect(c.summary!['notice'], 'new-day');
      expect(c.date, DateTime(2026, 10, 25));
    },
  );

  test(
    'identity invalidation ignores replies and cannot revive an old controller',
    () async {
      var account = 'isolated-account';
      final repo = DeferredNutrition();
      final c = NutritionController(
        repository: repo,
        accountId: account,
        currentAccountId: () => account,
      );
      addTearDown(c.dispose);
      final history = c.load();
      final own = c.searchOwn();
      c.queryChanged('private pending query');
      account = 'different-account';
      c.accountChanged();
      repo.entryReads.single.complete(page('old-account'));
      repo.summaryReads.single.complete({'notice': 'old-account'});
      repo.ownReads.single.complete(page('old-account-food'));
      await Future.wait([history, own]);
      expect(c.active, false);
      expect(c.entries, isEmpty);
      expect(c.foods, isEmpty);
      expect(c.summary, isNull);
      expect(c.loading, false);
      account = 'isolated-account';
      await c.load();
      await c.searchOwn();
      expect(c.active, false);
      expect(repo.entryReads, hasLength(1));
      expect(repo.ownReads, hasLength(1));
    },
  );

  test(
    'leaving during a pending read ignores completion without notifying',
    () async {
      final repo = DeferredNutrition();
      final c = NutritionController(
        repository: repo,
        accountId: 'isolated-account',
        currentAccountId: () => 'isolated-account',
      );
      var notifications = 0;
      c.addListener(() => notifications++);
      final pending = c.load();
      final beforeDispose = notifications;
      c.dispose();
      repo.entryReads.single.complete(page('disposed'));
      repo.summaryReads.single.complete({'notice': 'disposed'});
      await pending;
      expect(notifications, beforeDispose);
      expect(c.entries, isEmpty);
      expect(c.summary, isNull);
    },
  );
}
