import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trainforge/features/food_reference/data/local_food_repository.dart';
import 'package:trainforge/features/nutrition/data/nutrition_local_store.dart';
import 'package:trainforge/features/nutrition/data/offline_nutrition_repository.dart';
import 'package:trainforge/features/nutrition/domain/exact_nutrition.dart';
import 'package:trainforge/features/nutrition/domain/meals.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/domain/portion_quantity.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_forms.dart';

import 'food_reference_test.dart' show fixtureFood;
import 'meals_client_test.dart' show FixtureMeals, draft;
import 'nutrition_test.dart' show FakeNutrition, chooseEvidence;

const _sourceAmount = '14.000000000000002';
const _consumed = '21.000000000000003';
final _sourceId = 'food:${'1' * 64}';

Json _portion() => {
  'id': 'off-serving',
  'label': 'Porção declarada no rótulo',
  'quantity': _sourceAmount,
  'unit': 'g',
  'condition': 'Produto conforme o rótulo',
  'sourceId': 'AL-OFF',
};

Json _food({String basisUnit = 'g'}) => {
  ...fixtureFood(_sourceId),
  'sourceId': 'AL-OFF',
  'basis': {'quantity': '100', 'unit': basisUnit},
  'portions': [_portion()],
  'canonicalNutrients': [
    {
      'nutrientId': 'protein_g',
      'unit': 'g',
      'value': '10',
      'state': 'numeric',
      'methodId': 'fixture-label',
      'primaryForTotals': true,
      'basisQuantity': '100',
      'basisUnit': basisUnit,
      'sourceColumnKey': 'label-protein',
    },
  ],
};

Json _input() => {
  'foodId': _sourceId,
  'foodVersion': 'a' * 64,
  'quantity': _consumed,
  'unit': 'g',
  'portion': {..._portion(), 'count': '1.5'},
  'occurredAt': '2026-11-18T12:00:00Z',
  'timezone': '-03:00',
  'preparation': '',
  'quantityEvidence': 'measured',
  'revision': 0,
};

class _ReferenceCatalog extends LocalFoodRepository {
  bool unavailable = false;
  _ReferenceCatalog()
    : super(() async => throw StateError('Fixture uses no public database'));

  @override
  Future<Json> foodJson(String id, String version) async {
    if (unavailable || id != _sourceId || version != 'a' * 64) {
      throw const FormatException('Fixture food unavailable');
    }
    return _food();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('documented decimal quantities serialize exactly with bounded output', () {
    final portion = asFood(_food()).portions.single;
    expect(derivedPortionQuantity(portion, '1'), _sourceAmount);
    expect(derivedPortionQuantity(portion, '1.5'), _consumed);
    expect(
      (ExactAmount.parse('1.000001') * ExactAmount.parse('1.000001'))
          .exactDecimal(),
      '1.000002000001',
    );
    expect(
      () => ExactAmount(BigInt.one, BigInt.from(3)).exactDecimal(),
      throwsFormatException,
    );
    expect(validSourceQuantity('1' * 81), isFalse);
    expect(derivedPortionQuantity(portion, '1.0000001'), isNull);
    expect(sameMealQuantity('021.0000000000000030', _consumed), isTrue);
    expect(sameMealQuantity('21', _consumed), isFalse);
  });

  test('extra precision requires the exact documented portion and count', () {
    final food = asFood(_food());
    expect(validFoodIntakeQuantity(food, _input()), isTrue);
    for (final field in [
      'id',
      'label',
      'quantity',
      'unit',
      'condition',
      'sourceId',
      'count',
    ]) {
      final bad = copyMealJson(_input());
      (bad['portion'] as Map)[field] = field == 'count' ? '1.0000001' : 'forged';
      expect(validFoodIntakeQuantity(food, bad), isFalse, reason: field);
    }
    final rounded = _input()..['quantity'] = '21';
    expect(validFoodIntakeQuantity(food, rounded), isFalse);
    final manual = _input()..remove('portion');
    expect(validFoodIntakeQuantity(food, manual), isFalse);
    manual['quantity'] = '21.000001';
    expect(validFoodIntakeQuantity(food, manual), isTrue);
    expect(validDecimal(_sourceAmount, positive: true), isFalse);
    expect(
      () => OfflineNutritionRepository.ownFood({
        'name': 'Manual declaration',
        'basis': {'quantity': '100', 'unit': 'g'},
        'nutrients': <Json>[],
        'portions': [_portion()],
      }, 'own:fixture'),
      throwsFormatException,
    );
    final personal = OfflineNutritionRepository.ownFood({
      'name': 'Measured personal portion',
      'basis': {'quantity': '100', 'unit': 'g'},
      'nutrients': <Json>[],
      'portions': [
        {..._portion(), 'quantity': '1.000001', 'sourceId': 'personal'},
      ],
    }, 'own:fixture');
    expect(validFoodIntakeQuantity(asFood(personal), {
      'foodId': personal['id'],
      'foodVersion': personal['versionId'],
      'quantity': '1.000002000001',
      'unit': 'g',
      'portion': {
        ...objects(personal['portions']).single,
        'count': '1.000001',
      },
    }), isTrue);
  });

  test('portion unit must match intake and incompatible basis stays unknown', () {
    final wrongUnit = _input()..['unit'] = 'ml';
    expect(validFoodIntakeQuantity(asFood(_food()), wrongUnit), isFalse);
    final volumeFood = _food(basisUnit: 'ml');
    expect(validFoodIntakeQuantity(asFood(volumeFood), _input()), isTrue);
    final scaled = scaleCanonical(volumeFood, _consumed, 'g').single;
    expect(scaled['exactFraction'], isNull);
    expect(scaled['value'], isNull);
    expect(scaled['reason'], 'food_basis_unresolved');
  });

  test('offline snapshot and outbox preserve source precision through an edit', () async {
    const account = '77777777-7777-4777-8777-777777777777';
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => NutritionLocalStore.createSchema(db),
      ),
    );
    final catalog = _ReferenceCatalog();
    final repository = OfflineNutritionRepository(
      store: NutritionLocalStore(
        accountId: account,
        currentAccountId: () => account,
        databaseOpener: () async => db,
      ),
      catalog: catalog,
      dio: Dio(BaseOptions(baseUrl: 'https://fixture.invalid')),
      autoSync: false,
    );
    addTearDown(() async {
      repository.dispose();
      await db.close();
    });
    final id = mutationKey();
    final saved = await repository.saveEntry(_input(), id);
    expect(saved['quantity'], _consumed);
    expect(
      objects(object(saved['calculation'])['nutrients']).single['exactFraction'],
      '21000000000000003/10000000000000000',
    );
    expect(object(object(saved['calculation'])['portion'])['quantity'], _sourceAmount);
    final wire = object(jsonDecode((await db.query('outbox')).single['body'] as String));
    expect(wire['quantity'], _consumed);
    expect(object(wire['portion'])['quantity'], _sourceAmount);
    expect(wire['calculationAlgorithm'], 'trainforge.canonical-nutrition/1');

    final forged = _input();
    (forged['portion'] as Map)['quantity'] = '14';
    await expectLater(repository.saveEntry(forged, mutationKey()), throwsFormatException);
    expect(await db.query('outbox'), hasLength(1));

    catalog.unavailable = true;
    final edit = _input()
      ..['quantity'] = '28.000000000000004'
      ..['revision'] = 1;
    (edit['portion'] as Map)['count'] = '2';
    final edited = await repository.saveEntry(edit, mutationKey(), id: id);
    expect(edited['quantity'], '28.000000000000004');
    expect(object(object(edited['calculation'])['portion'])['quantity'], _sourceAmount);
  });

  test('meal draft accepts a verified source portion and rejects manual bypass', () {
    final controller = draft(FixtureMeals(), () => 'a');
    addTearDown(controller.dispose);
    final food = asFood(_food());
    controller.add(food, _input());
    expect(controller.items.single.input['quantity'], _consumed);
    final manual = _input()..remove('portion');
    expect(() => controller.add(food, manual), throwsFormatException);
    final forged = _input();
    (forged['portion'] as Map)['label'] = 'Different portion';
    expect(() => controller.add(food, forged), throwsFormatException);
    expect(controller.items, hasLength(1));
  });

  testWidgets('portion form keeps all source decimals after changing the count', (tester) async {
    final repository = FakeNutrition();
    await tester.pumpWidget(
      MaterialApp(
        home: EntryFormPage(food: asFood(_food()), repository: repository),
      ),
    );
    tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const Key('entry-portion')),
    ).onChanged!('off-serving');
    await tester.pump();
    final count = find.byKey(const Key('entry-portion-count'));
    await tester.ensureVisible(count);
    await tester.enterText(count, '1.5');
    await tester.pump();
    final amount = tester.widget<TextFormField>(find.byKey(const Key('entry-quantity')));
    expect(amount.controller!.text, _consumed);
    await chooseEvidence(tester);
    await tester.scrollUntilVisible(
      find.text('Confirmar consumo'),
      200,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first,
    );
    await tester.tap(find.text('Confirmar consumo'));
    await tester.pumpAndSettle();
    expect(repository.entryWrites, 1);
    expect(repository.body!['quantity'], _consumed);
    expect(object(repository.body!['portion'])['quantity'], _sourceAmount);
  });
}
