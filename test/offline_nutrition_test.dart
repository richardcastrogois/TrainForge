import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cryptography/cryptography.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trainforge/features/food_reference/data/local_food_repository.dart';
import 'package:trainforge/features/food_reference/data/catalog_installer.dart';
import 'package:trainforge/features/nutrition/data/calculation_parity.dart';
import 'package:trainforge/features/nutrition/data/nutrition_local_store.dart';
import 'package:trainforge/features/nutrition/data/offline_nutrition_repository.dart';
import 'package:trainforge/features/nutrition/domain/exact_nutrition.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/presentation/food_contribution_page.dart';
import 'package:trainforge/l10n/generated/app_localizations.dart';

class TestTransport implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) respond;
  TestTransport(this.respond);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody response(Json value) => ResponseBody.fromString(
  jsonEncode(value),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

class _ManifestCatalogInstaller extends CatalogInstaller {
  final Map<String, dynamic> fixture;
  _ManifestCatalogInstaller(this.fixture);

  @override
  Future<Map<String, dynamic>> manifest() async => fixture;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  const account = '11111111-1111-4111-8111-111111111111';
  const foodOperation = '22222222-2222-4222-8222-222222222222';
  const entryOperation = '33333333-3333-4333-8333-333333333333';
  final declaration = <String, dynamic>{
    'name': 'Arroz de teste',
    'preparation': 'cozido',
    'basis': {'quantity': '100', 'unit': 'g'},
    'nutrients': [
      {'name': 'Energia', 'unit': 'kcal', 'value': '100'},
      {'name': 'Proteína', 'unit': 'g', 'value': '2.5'},
      {'name': 'Fibra', 'unit': 'g', 'value': null},
    ],
  };

  test(
    'shared Go/Dart canonical fixtures preserve fractions, unknowns and units',
    () {
      final fixture = object(
        jsonDecode(
          File(
            'test/fixtures/canonical_nutrition_cases.json',
          ).readAsStringSync(),
        ),
      );
      for (final c in objects(fixture['cases'])) {
        final cells = scaleCanonical(
          {'basis': c['basis'], 'canonicalNutrients': c['cells']},
          c['quantity'] as String,
          c['unit'] as String,
        );
        final expected = objects(c['expected']);
        expect(cells.length, expected.length, reason: c['name'] as String);
        for (var i = 0; i < cells.length; i++) {
          expect(cells[i]['nutrientId'], expected[i]['id']);
          expect(cells[i]['value'], expected[i]['value']);
          expect(cells[i]['exactFraction'], expected[i]['fraction']);
        }
      }
    },
  );

  test('catalog GTIN check digits and compressed JSON are deterministic', () {
    expect(LocalFoodRepository.validBarcode('7891000315507'), isTrue);
    expect(LocalFoodRepository.validBarcode('7891000315508'), isFalse);
    expect(
      LocalFoodRepository.normalizedBarcode('7891000315507'),
      '07891000315507',
    );
    expect(LocalFoodRepository.normalize('Feijão  COZIDO'), 'feijao cozido');
    final encoded =
        'zlib:${base64Encode(zlib.encode(utf8.encode('[{"value":"1.25"}]')))}';
    expect(decodeCatalogJson(encoded), [
      {'value': '1.25'},
    ]);
  });
  test(
    'catalog facets use the grand total without adding source counts',
    () async {
      final catalog = LocalFoodRepository(
        () async => throw StateError('Manifest facets must not query SQLite'),
        installer: _ManifestCatalogInstaller({
          'counts': {'foods': 2, 'AL-TACO': 2},
          'sources': [
            {'sourceId': 'AL-TACO', 'name': 'TACO'},
          ],
        }),
      );
      final facets = await catalog.facets();
      expect(facets.total, 2);
      expect(facets.sources.single.count, 2);
    },
  );
  test(
    'private nutrient aliases cannot double count the same canonical nutrient',
    () {
      expect(
        () => OfflineNutritionRepository.ownFood({
          ...declaration,
          'nutrients': [
            {'name': 'Proteína', 'unit': 'g', 'value': '2'},
            {'name': 'Protein', 'unit': 'g', 'value': '3'},
          ],
        }, 'own:fixture'),
        throwsFormatException,
      );
    },
  );

  test(
    'exact totals join canonical IDs across sources and keep incomplete coverage',
    () {
      Json entry(String value) => {
        'calculation': {
          'quantityEvidence': 'measured',
          'nutrients': [
            {
              'nutrientId': 'protein_g',
              'sourceColumnKey': 'source-$value',
              'nameOriginal': 'Protein',
              'unit': 'g',
              'value': value,
              'exactFraction': ExactAmount.parse(value).fraction,
            },
          ],
        },
      };
      final totals = exactTotals([
        entry('1.25'),
        entry('2.5'),
        {
          'calculation': {
            'quantityEvidence': 'estimated',
            'nutrients': <Json>[],
          },
        },
      ]);
      final cell = objects(totals['nutrients']).single;
      expect(cell['value'], '3.75');
      expect(cell['includedEntries'], 2);
      expect(cell['unknownEntries'], 1);
      expect(totals['measuredEntries'], 2);
    },
  );

  late Database db;
  late NutritionLocalStore store;
  late OfflineNutritionRepository repository;
  String? currentAccount;
  setUp(() async {
    currentAccount = account;
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => NutritionLocalStore.createSchema(db),
      ),
    );
    store = NutritionLocalStore(
      accountId: account,
      currentAccountId: () => currentAccount,
      databaseOpener: () async => db,
    );
    repository = OfflineNutritionRepository(
      store: store,
      autoSync: false,
      catalog: LocalFoodRepository(
        () async => throw StateError('Public catalog not used in this fixture'),
      ),
      dio: Dio(BaseOptions(baseUrl: 'https://fixture.invalid'))
        ..httpClientAdapter = TestTransport(
          (o) async => throw DioException(
            requestOptions: o,
            type: DioExceptionType.connectionError,
          ),
        ),
    );
  });
  tearDown(() async {
    if (db.isOpen) await db.close();
    repository.dispose();
  });

  Future<Json> intake() async {
    final food = await repository.createFood(declaration, foodOperation);
    return repository.saveEntry({
      'foodId': food['id'],
      'foodVersion': food['versionId'],
      'quantity': '25.5',
      'unit': 'g',
      'preparation': 'cozido',
      'occurredAt': '2026-11-17T12:00:00Z',
      'timezone': '-03:00',
      'quantityEvidence': 'measured',
      'revision': 0,
    }, entryOperation);
  }

  test(
    'offline create is durable, preserves unknowns and rejects another account',
    () async {
      final entry = await intake();
      final page = await repository.entries('2026-11-17', '-03:00');
      expect(page.items.single['id'], entryOperation);
      final cells = objects(object(entry['calculation'])['nutrients']);
      expect(cells.first['value'], '25.5');
      expect(cells.last['value'], isNull);
      final second = NutritionLocalStore(
        accountId: account,
        currentAccountId: () => currentAccount,
        databaseOpener: () async => db,
      );
      expect((await second.resources('entry')).single['id'], entryOperation);
      currentAccount = 'other-account';
      await expectLater(second.resources('entry'), throwsStateError);
    },
  );

  test('delete before first transmission cancels a pending create', () async {
    await intake();
    await repository.deleteEntry(
      entryOperation,
      1,
      '44444444-4444-4444-8444-444444444444',
    );
    expect((await repository.entries('2026-11-17', '-03:00')).items, isEmpty);
    final operations = await db.query(
      'outbox',
      where: 'entity=?',
      whereArgs: ['entry'],
    );
    expect(operations.length, 1);
    expect(operations.single['state'], 'cancelled');
  });

  test(
    'lost response reuses the exact saved wire envelope after repository recreation',
    () async {
      await repository.createFood(declaration, foodOperation);
      Json? first;
      var calls = 0;
      final transport = TestTransport((options) async {
        if (options.path.endsWith('/sync')) {
          final operation = objects(object(options.data)['operations']).single;
          calls++;
          if (first == null) {
            first = operation;
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            );
          }
          expect(operation, first);
          return response({
            'contract': 'trainforge.nutrition-sync/1',
            'results': [
              {
                'operationId': foodOperation,
                'status': 'confirmed',
                'localId': foodOperation,
                'remoteId': 'own:99999999-9999-4999-8999-999999999999',
                'value': OfflineNutritionRepository.ownFood(
                  declaration,
                  'own:99999999-9999-4999-8999-999999999999',
                ),
              },
            ],
          });
        }
        return response({
          'items': <Json>[],
          'nextCursor': 'opaque-account-cursor',
          'hasMore': false,
        });
      });
      repository.synchronizer.dio.httpClientAdapter = transport;
      await repository.synchronize();
      expect(repository.syncFailure, 'network');
      final restored = OfflineNutritionRepository(
        store: store,
        catalog: repository.catalog,
        autoSync: false,
        dio: Dio(BaseOptions(baseUrl: 'https://fixture.invalid'))
          ..httpClientAdapter = transport,
      );
      await restored.synchronize();
      expect(calls, 2);
      expect((await db.query('outbox')).single['state'], 'confirmed');
      restored.dispose();
    },
  );

  test(
    'server calculation disagreement is detectable before replacing a snapshot',
    () async {
      final local = await intake();
      final remote = object(jsonDecode(jsonEncode(local)));
      final cells = objects(object(remote['calculation'])['nutrients']);
      cells.first['exactFraction'] = '999/1';
      object(remote['calculation']);
      (remote['calculation'] as Map)['nutrients'] = cells;
      expect(sameCalculationSnapshot(local, remote), isFalse);
      expect(
        sameCalculationSnapshot(local, object(jsonDecode(jsonEncode(local)))),
        isTrue,
      );
    },
  );

  test(
    'signed catalog accepts the bundled key and rejects tampered metadata',
    () async {
      final algorithm = Ed25519();
      final key = await algorithm.newKeyPair();
      final public = await key.extractPublicKey();
      final payload = base64Encode(
        utf8.encode(
          jsonEncode({
            'contract': 'trainforge.food-catalog/1',
            'schemaVersion': 1,
            'version': 'a' * 64,
            'file': 'catalog.sqlite.gz',
            'sha256': 'b' * 64,
            'bytes': 123,
            'databaseFile': 'catalog.sqlite',
            'databaseSha256': 'c' * 64,
            'databaseBytes': 456,
          }),
        ),
      );
      final signature = await algorithm.sign(
        base64Decode(payload),
        keyPair: key,
      );
      final trust = jsonEncode({
        'keys': [
          {
            'keyId': 'fixture',
            'algorithm': 'Ed25519',
            'publicKey': base64Encode(public.bytes),
          },
        ],
      });
      final installer = CatalogInstaller(readAsset: (_) async => trust);
      final envelope = {
        'keyId': 'fixture',
        'payload': payload,
        'signature': base64Encode(signature.bytes),
      };
      expect(
        (await installer.verifyEnvelope(jsonEncode(envelope)))['databaseBytes'],
        456,
      );
      await expectLater(
        installer.verifyEnvelope(
          jsonEncode({...envelope, 'keyId': 'untrusted'}),
        ),
        throwsFormatException,
      );
      await expectLater(
        installer.verifyEnvelope(
          jsonEncode({...envelope, 'payload': base64Encode(utf8.encode('{}'))}),
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'a closed file database can be reopened with the durable intake and outbox',
    () async {
      await db.close();
      final directory = await Directory.systemTemp.createTemp(
        'trainforge-offline-fixture-',
      );
      final filename = '${directory.path}/private.sqlite';
      db = await databaseFactoryFfi.openDatabase(
        filename,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) => NutritionLocalStore.createSchema(db),
        ),
      );
      store = NutritionLocalStore(
        accountId: account,
        currentAccountId: () => currentAccount,
        databaseOpener: () async => db,
      );
      repository = OfflineNutritionRepository(
        store: store,
        catalog: repository.catalog,
        autoSync: false,
      );
      await intake();
      await db.close();
      db = await databaseFactoryFfi.openDatabase(filename);
      final restored = NutritionLocalStore(
        accountId: account,
        currentAccountId: () => currentAccount,
        databaseOpener: () async => db,
      );
      expect((await restored.resources('entry')).single['id'], entryOperation);
      expect((await db.query('outbox')).length, 2);
      addTearDown(() async {
        if (db.isOpen) await db.close();
        if (!directory.path.startsWith(Directory.systemTemp.path)) {
          throw StateError('Unexpected fixture path');
        }
        await directory.delete(recursive: true);
      });
    },
  );

  test('account change rolls back the entire local transaction', () async {
    await expectLater(
      store.transaction((tx) async {
        await NutritionLocalStore.put(tx, 'entry', entryOperation, {
          'id': entryOperation,
        });
        currentAccount = 'another-account';
      }),
      throwsStateError,
    );
    expect(await db.query('resources'), isEmpty);
  });
  test(
    'contribution invitation preference persists without publishing any food',
    () async {
      expect(await repository.contributionInvitesEnabled(), isTrue);
      await repository.setContributionInvites(false);
      final reopened = OfflineNutritionRepository(
        store: store,
        catalog: repository.catalog,
        autoSync: false,
      );
      expect(await reopened.contributionInvitesEnabled(), isFalse);
      expect(await store.resources('contribution'), isEmpty);
      reopened.dispose();
    },
  );

  test(
    'uncertain contribution cannot be withdrawn only on the device',
    () async {
      final id = await repository.contribute(declaration);
      repository.synchronizer.dio.httpClientAdapter = TestTransport(
        (o) async => throw DioException(
          requestOptions: o,
          type: DioExceptionType.connectionError,
        ),
      );
      await repository.synchronize();
      expect((await db.query('outbox')).single['state'], 'sending');
      await expectLater(repository.cancelContribution(id), throwsStateError);
      expect(
        (await store.resources('contribution')).single['status'],
        'queued',
      );
    },
  );

  test(
    'confirmation cannot replace food identity, instant, limit, method or basis',
    () async {
      final local = await intake();
      Json copy() => object(jsonDecode(jsonEncode(local)));
      final wrongFood = copy()..['foodId'] = 'food:wrong';
      expect(sameCalculationSnapshot(local, wrongFood), isFalse);
      final wrongTime = copy()..['occurredAt'] = '2026-11-18T12:00:00Z';
      expect(sameCalculationSnapshot(local, wrongTime), isFalse);
      final wrongMethod = copy();
      ((wrongMethod['calculation'] as Map)['nutrients'] as List)
              .first['methodId'] =
          'other-method';
      expect(sameCalculationSnapshot(local, wrongMethod), isFalse);
      final wrongBasis = copy();
      ((wrongBasis['calculation'] as Map)['nutrients'] as List).first['basis'] =
          {'quantity': '100', 'unit': 'ml'};
      expect(sameCalculationSnapshot(local, wrongBasis), isFalse);
      final left = copy(), right = copy();
      for (final value in [left, right]) {
        final cell =
            ((value['calculation'] as Map)['nutrients'] as List).first as Map;
        cell['sourceState'] = 'less_than';
        cell['value'] = null;
        cell['exactFraction'] = null;
      }
      ((left['calculation'] as Map)['nutrients'] as List)
              .first['sourceUpperBound'] =
          '0.1';
      ((right['calculation'] as Map)['nutrients'] as List)
              .first['sourceUpperBound'] =
          '0.2';
      expect(sameCalculationSnapshot(left, right), isFalse);
    },
  );
  testWidgets(
    'contribution remains optional and requires explicit reuse consent',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FoodContributionPage(repository: repository, food: declaration),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.widgetWithText(FilledButton, 'Compartilhar alimento');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(
        await tester.runAsync(() => store.resources('contribution')),
        isEmpty,
      );
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    },
  );
}
