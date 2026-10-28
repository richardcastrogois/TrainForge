import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/food_reference/domain/food_reference.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/domain/meals.dart';
import 'package:trainforge/features/nutrition/data/nutrition_repository.dart';
import 'package:trainforge/features/nutrition/presentation/meal_controllers.dart';
import 'food_reference_test.dart' show fixtureFood;

const mealId = '99999999-9999-4999-8999-999999999999';
const entryId = '11111111-1111-4111-8111-111111111111';
final sourceId = 'food:${'a' * 64}';
Json itemInput() => {
  'foodId': sourceId,
  'foodVersion': 'a' * 64,
  'quantity': '01.00',
  'unit': 'g',
  'occurredAt': '2026-10-28T12:00:00Z',
  'timezone': 'UTC',
  'quantityEvidence': 'estimated',
  'preparation': '',
  'revision': 0,
};
Json mealBody() => {
  'title': '',
  'occurredAt': '2026-10-28T12:00:00Z',
  'timezone': 'UTC',
  'reviewed': true,
  'items': [itemInput()],
};
Json entryFixture() => {
  'id': entryId,
  'foodId': sourceId,
  'foodVersion': 'a' * 64,
  'quantity': '1.00',
  'unit': 'g',
  'occurredAt': '2026-10-28T12:00:00Z',
  'timezone': 'UTC',
  'deletedAt': null,
  'calculation': {
    'food': fixtureFood(sourceId),
    'algorithm': 'source-rational-v1',
    'quantityEvidence': 'estimated',
    'preparation': '',
    'revision': 1,
    'changes': [],
    'nutrients': [],
  },
};
Json metadataFixture() => {
  'id': mealId,
  'title': '',
  'occurredAt': '2026-10-28T12:00:00Z',
  'timezone': 'UTC',
  'revision': 1,
  'totalActiveItems': 1,
};
Json confirmedFixture() => {
  'meal': metadataFixture(),
  'entries': [entryFixture()],
  'deletedAt': null,
};
Json dayFixture({
  String day = '2026-10-28',
  String zone = 'UTC',
  String locale = 'pt-BR',
}) => {
  'date': day,
  'timezone': zone,
  'nameCatalog': {'locale': locale, 'version': '0'},
  'diary': {
    'entries': [entryFixture()],
    'meals': [
      {
        'meal': metadataFixture(),
        'entryIds': [entryId],
        'otherActiveItems': 0,
        'totals': {'entries': 1},
      },
    ],
    'ungroupedEntryIds': [],
    'complete': true,
    'totals': {
      'entries': 1,
      'complete': true,
      'measuredEntries': 0,
      'estimatedEntries': 1,
      'nutrients': [],
    },
  },
};

class FixtureMeals implements MealRepository {
  final List<Json> writes = [];
  final List<String> keys = [];
  final List<Completer<MealDay>> reads = [];
  Object? failure;
  Completer<ConfirmedMeal>? pending;
  @override
  Future<ConfirmedMeal> createMeal(Json body, String key) async {
    writes.add(copyMealJson(body));
    keys.add(key);
    if (failure != null) throw failure!;
    if (pending != null) return pending!.future;
    final out = confirmedFixture();
    final m = object(out['meal']);
    m['title'] = body['title'];
    m['occurredAt'] = body['occurredAt'];
    m['timezone'] = body['timezone'];
    out['meal'] = m;
    return ConfirmedMeal.fromJson(out);
  }

  @override
  Future<MealDay> mealDay(
    String day,
    String timezone, {
    required String locale,
  }) {
    final pending = Completer<MealDay>();
    reads.add(pending);
    return pending.future;
  }

  @override
  Future<ConfirmedMeal> meal(String id, {required String locale}) async =>
      ConfirmedMeal.fromJson(confirmedFixture());
  @override
  Future<ConfirmedMeal> editMeal(String id, Json body, String key) async =>
      throw UnimplementedError();
  @override
  Future<ConfirmedMeal> deleteMeal(String id, int revision, String key) async =>
      throw UnimplementedError();
}

DioException requestError(int status) => DioException(
  requestOptions: RequestOptions(path: '/fixture'),
  response: Response(
    requestOptions: RequestOptions(path: '/fixture'),
    statusCode: status,
  ),
);
MealDraftController draft(
  FixtureMeals repo,
  String? Function() account, {
  Duration retryWindow = const Duration(hours: 24),
}) => MealDraftController(
  repository: repo,
  accountId: 'a',
  currentAccountId: account,
  occurredAt: DateTime.utc(2026, 10, 28, 12),
  retryWindow: retryWindow,
);
void prepare(MealDraftController c) {
  c.add(FoodReference.fromJson(fixtureFood(sourceId)), itemInput());
  c.setReviewed(true);
}

void main() {
  test('both meal views must cover each intake exactly once', () {
    final raw = dayFixture();
    final d = MealDay.fromJson(raw);
    expect(d.entries.length, 1);
    expect(d.meals.single.entryIds, [entryId]);
    for (final field in [
      'missingEntries',
      'duplicateMembership',
      'missingMembership',
    ]) {
      final bad = copyMealJson(raw);
      final section = bad['diary'] as Map<String, dynamic>;
      if (field == 'missingEntries') section['entries'] = [];
      if (field == 'duplicateMembership') {
        section['ungroupedEntryIds'] = [entryId];
      }
      if (field == 'missingMembership') section['meals'] = [];
      expect(() => MealDay.fromJson(bad), throwsFormatException);
    }
    final legacy = copyMealJson(raw);
    final section = object(legacy['diary']);
    section['meals'] = [];
    section['ungroupedEntryIds'] = [entryId];
    legacy['diary'] = section;
    expect(MealDay.fromJson(legacy).ungroupedEntryIds, [entryId]);
  });
  test(
    'decimal comparison never uses float and preserves exact input meaning',
    () {
      expect(sameMealQuantity('01.00', '1'), true);
      expect(sameMealQuantity('9999999.999999', '9999999.999998'), false);
      expect(sameMealQuantity('1e2', '100'), false);
      expect(sameMealQuantity('0', '0.0'), false);
    },
  );
  test(
    'explicit review required, edits reset review and no automatic consumption',
    () async {
      final repo = FixtureMeals();
      final c = draft(repo, () => 'a');
      addTearDown(c.dispose);
      c.add(FoodReference.fromJson(fixtureFood(sourceId)), itemInput());
      await c.submit();
      expect(repo.writes, isEmpty);
      c.setReviewed(true);
      c.setTitle('A title');
      expect(c.reviewed, false);
      await c.submit();
      expect(repo.writes, isEmpty);
      c.setReviewed(true);
      await c.submit();
      expect(repo.writes.length, 1);
      expect(c.confirmed, isNotNull);
      expect(
        repo.writes.single.keys,
        containsAll(['title', 'occurredAt', 'timezone', 'reviewed', 'items']),
      );
      expect(repo.writes.single.containsKey('userId'), false);
    },
  );
  test(
    'uncertain response freezes exact body/key and keeps user quantities',
    () async {
      final repo = FixtureMeals()..failure = requestError(503);
      final c = draft(repo, () => 'a');
      addTearDown(c.dispose);
      prepare(c);
      await c.submit();
      expect(c.uncertain, true);
      expect(c.locked, true);
      final before = copyMealJson(repo.writes.single);
      c.setTitle('Changed');
      c.remove(0);
      c.setWhen(DateTime.utc(2026, 11));
      final exposed = c.items.single.input;
      exposed['quantity'] = '999';
      repo.failure = null;
      await c.submit();
      expect(repo.writes.last, before);
      expect(repo.keys.last, repo.keys.first);
      expect(c.confirmed, isNotNull);
    },
  );
  test(
    'a conflict or expired retry window never creates a fresh intention',
    () async {
      for (final conflict in [true, false]) {
        final repo = FixtureMeals()
          ..failure = requestError(conflict ? 409 : 503);
        final c = draft(
          repo,
          () => 'a',
          retryWindow: conflict ? const Duration(hours: 24) : Duration.zero,
        );
        prepare(c);
        await c.submit();
        repo.failure = null;
        await c.submit();
        expect(repo.writes.length, 1);
        expect(c.conflict, true);
        expect(c.uncertain, true);
        c.dispose();
      }
    },
  );
  test(
    'known rejected input unlocks editing and requires fresh review',
    () async {
      final repo = FixtureMeals()..failure = requestError(400);
      final c = draft(repo, () => 'a');
      addTearDown(c.dispose);
      prepare(c);
      await c.submit();
      expect(c.locked, false);
      expect(c.reviewed, false);
      repo.failure = null;
      await c.submit();
      expect(repo.writes.length, 1);
      c.setReviewed(true);
      await c.submit();
      expect(repo.keys.first, isNot(repo.keys.last));
    },
  );
  test(
    'account switch clears drafts and drops a late saved response',
    () async {
      String? account = 'a';
      final repo = FixtureMeals()..pending = Completer();
      final c = draft(repo, () => account);
      addTearDown(c.dispose);
      prepare(c);
      final pending = c.submit();
      expect(c.busy, true);
      account = 'b';
      c.accountChanged();
      repo.pending!.complete(ConfirmedMeal.fromJson(confirmedFixture()));
      await pending;
      expect(c.active, false);
      expect(c.items, isEmpty);
      expect(c.confirmed, isNull);
      expect(c.uncertain, false);
      expect(c.busy, false);
    },
  );
  test(
    'new date/locale and account changes discard older diary reads',
    () async {
      String? account = 'a';
      final repo = FixtureMeals();
      final c = MealDiaryController(
        repository: repo,
        accountId: 'a',
        currentAccountId: () => account,
        date: DateTime.utc(2026, 10, 28),
        locale: 'pt-BR',
      );
      addTearDown(c.dispose);
      final first = c.load();
      final second = c.load(selectedLocale: 'es');
      repo.reads[1].complete(
        MealDay.fromJson(dayFixture(zone: '+00:00', locale: 'es')),
      );
      await second;
      repo.reads[0].complete(MealDay.fromJson(dayFixture(zone: '+00:00')));
      await first;
      expect(c.day?.nameCatalog?.locale, 'es');
      final third = c.load();
      account = 'b';
      c.accountChanged();
      repo.reads[2].complete(
        MealDay.fromJson(dayFixture(zone: '+00:00', locale: 'es')),
      );
      await third;
      expect(c.day, isNull);
      expect(c.active, false);
    },
  );
  test(
    'repository binds account/locale and checks confirmed quantities',
    () async {
      String? account = 'a';
      final dio = Dio();
      final seen = <RequestOptions>[];
      Json response = confirmedFixture();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            seen.add(request);
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 201,
                data: copyMealJson(response),
              ),
            );
          },
        ),
      );
      final repo = GoNutritionRepository(
        accountId: 'a',
        currentAccountId: () => account,
        dio: dio,
      );
      final result = await repo.createMeal(mealBody(), mealId);
      expect(result.meal.id, mealId);
      expect(seen.single.headers['X-TrainForge-Account'], 'a');
      expect(seen.single.headers['Idempotency-Key'], mealId);
      response = confirmedFixture();
      (response['entries'] as List).first['quantity'] = '9';
      await expectLater(
        repo.createMeal(mealBody(), mealId),
        throwsFormatException,
      );
      final edit = mealBody()..remove('items');
      edit['revision'] = 1;
      edit['title'] = 'Corrected fixture';
      response = confirmedFixture();
      response['meal'] = {
        ...metadataFixture(),
        'revision': 2,
        'title': edit['title'],
      };
      await repo.editMeal(mealId, edit, mealId);
      expect(seen.last.method, 'PATCH');
      expect(seen.last.path, '/api/v1/me/meals/$mealId');
      expect(seen.last.data, edit);
      response['meal'] = {
        ...metadataFixture(),
        'revision': 2,
        'title': 'Unexpected',
      };
      await expectLater(
        repo.editMeal(mealId, edit, mealId),
        throwsFormatException,
      );
      account = 'b';
      await expectLater(repo.createMeal(mealBody(), mealId), throwsStateError);
      await expectLater(repo.editMeal(mealId, edit, mealId), throwsStateError);
      expect(seen.length, 4);
    },
  );
}
