import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/food_reference/domain/food_reference.dart';
import 'package:trainforge/features/food_reference/presentation/food_controller.dart';
import 'package:trainforge/features/food_reference/presentation/food_page.dart';
import 'package:trainforge/features/food_reference/presentation/food_detail_page.dart';

Map<String, dynamic> fixtureFood(String id) => {
  'id': id,
  'versionId': 'a' * 64,
  'sourceId': 'fixture',
  'sourceFoodId': id,
  'sourcePublishedVersion': 'fixture-1',
  'nameOriginal': 'Isolated food $id',
  'nameLocale': 'en',
  'basis': {'quantity': null, 'unit': null},
  'source': {
    'name': 'Isolated source',
    'publisher': 'Fixture',
    'sourceUrl': 'https://example.invalid/source',
    'licenseLabel': 'Fixture license',
    'licenseUrl': 'https://example.invalid/license',
    'attribution': 'Fixture author and publication date',
    'publishedAt': '2025-01-01',
    'changes': 'Fixture changes',
    'warrantyNotice': 'Fixture warranty',
    'conditions': ['Fixture condition'],
  },
};
Map<String, dynamic> fixtureCell(
  String state, {
  String? value,
  String? bound,
}) => {
  'sourceColumnKey': 'fixture:10',
  'nameOriginal': 'Fixture nutrient',
  'state': state,
  'rawText': 'fixture raw',
  'value': value,
  'upperBound': bound,
  'unit': 'g',
  'basisQuantity': null,
  'basisUnit': null,
  'declaredColumnBasis': null,
};
FoodPageData fixturePage(String id, {String? cursor}) => FoodPageData.fromJson({
  'items': [fixtureFood(id)],
  'nextCursor': cursor,
});

class FixtureFoods implements FoodRepository {
  final Map<String, Completer<FoodPageData>> pending = {};
  Object? listError, detailError;
  bool empty = false;
  @override
  Future<FoodPageData> list({
    String q = '',
    String sourceId = '',
    String? cursor,
  }) async {
    if (listError != null) throw listError!;
    if (pending[q] != null) return pending[q]!.future;
    if (empty) return FoodPageData.fromJson({'items': [], 'nextCursor': null});
    return fixturePage(
      cursor == null ? (q.isEmpty ? 'first' : q) : 'second',
      cursor: cursor == null ? 'next' : null,
    );
  }

  @override
  Future<FoodFacets> facets() async => FoodFacets.fromJson({
    'sources': [
      {'id': 'fixture', 'name': 'Isolated source', 'count': 2},
    ],
    'total': 2,
    'unknownBasisCount': 2,
  });
  @override
  Future<FoodDetailData> detail(FoodReference food) async {
    if (detailError != null) throw detailError!;
    return FoodDetailData.fromJson({
      ...fixtureFood(food.id),
      'notice': 'Fixture reference without a diet',
      'nutrients': [
        fixtureCell('numeric', value: '0'),
        fixtureCell('trace'),
        fixtureCell('missing'),
        fixtureCell('less_than', bound: '0.01'),
      ],
    });
  }
}

void main() {
  test('source values retain zero, unknown, traces and strict bounds', () {
    final rawFood = fixtureFood('line')..['nameOriginal'] = 'Original\nname';
    final f = FoodReference.fromJson(rawFood);
    expect(f.name, 'Original\nname');
    expect(f.displayName, 'Original name');
    final cases = {
      'numeric': '0 g',
      'trace': 'Traço (sem quantidade exata)',
      'missing': 'Não informado',
      'present_quantity_unknown': 'Presente; quantidade desconhecida',
      'less_than': '< 0.01 g (limite; sem valor exato)',
      'unparsed': 'Valor original não interpretado: fixture raw',
    };
    for (final entry in cases.entries) {
      final cell = FoodNutrient.fromJson(
        fixtureCell(
          entry.key,
          value: entry.key == 'numeric' ? '0' : null,
          bound: entry.key == 'less_than' ? '0.01' : null,
        ),
      );
      expect(cell.displayValue, entry.value);
      expect(cell.basisLabel, contains('Base não confirmada'));
    }
    expect(
      FoodReference.fromJson(fixtureFood('basis')).basisLabel,
      'Base de composição desconhecida',
    );
  });
  test('long accented searches have an actionable local error', () async {
    final c = FoodController(FixtureFoods());
    await c.load(q: 'é' * 51);
    expect(c.error, contains('Use uma parte'));
    expect(c.items, isEmpty);
    expect(c.busy, isFalse);
    c.dispose();
  });
  test('older searches cannot replace newer results', () async {
    final repo = FixtureFoods();
    repo.pending['old'] = Completer<FoodPageData>();
    final c = FoodController(repo);
    final old = c.load(q: 'old');
    await c.load(q: 'new');
    repo.pending['old']!.complete(fixturePage('old'));
    await old;
    expect(c.items.single.id, 'new');
    c.dispose();
  });
  test(
    'pagination errors preserve page; failed reload removes stale references',
    () async {
      final repo = FixtureFoods();
      final c = FoodController(repo);
      await c.load();
      repo.listError = StateError('secret payload');
      await c.more();
      expect(c.items.single.id, 'first');
      expect(c.moreError, isNot(contains('secret')));
      repo.listError = null;
      await c.more();
      expect(c.items.map((f) => f.id), ['first', 'second']);
      repo.listError = StateError('secret payload');
      await c.load();
      expect(c.items, isEmpty);
      expect(c.error, isNot(contains('secret')));
      c.dispose();
    },
  );
  testWidgets('small screen and doubled text remain scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = FoodController(FixtureFoods());
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: FoodPage(controller: c),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('detail presents attribution and never turns trace into zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FoodDetailPage(
          food: FoodReference.fromJson(fixtureFood('first')),
          repository: FixtureFoods(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fixture author and publication date'), findsOneWidget);
    expect(
      find.text('Base de composição desconhecida'),
      findsNothing,
    ); // included with language in the header
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('Traço (sem quantidade exata)'), findsOneWidget);
    expect(find.text('Não informado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('withdrawn or unavailable detail does not retain source values', (
    tester,
  ) async {
    final repo = FixtureFoods()..detailError = StateError('secret body');
    await tester.pumpWidget(
      MaterialApp(
        home: FoodDetailPage(
          food: FoodReference.fromJson(fixtureFood('first')),
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('indisponível'), findsOneWidget);
    expect(find.text('0 g'), findsNothing);
    expect(find.textContaining('secret'), findsNothing);
  });
  testWidgets('empty search has a clear reset action', (tester) async {
    final c = FoodController(FixtureFoods()..empty = true);
    await tester.pumpWidget(MaterialApp(home: FoodPage(controller: c)));
    await tester.pumpAndSettle();
    expect(find.text('Limpar busca e fonte'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
