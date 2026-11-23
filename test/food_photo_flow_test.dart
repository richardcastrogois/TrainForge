import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trainforge/features/food_reference/data/food_photo_classifier.dart';
import 'package:trainforge/features/food_reference/data/local_food_repository.dart';
import 'package:trainforge/features/food_reference/domain/food_reference.dart';
import 'package:trainforge/features/nutrition/data/nutrition_local_store.dart';
import 'package:trainforge/features/nutrition/data/offline_nutrition_repository.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_forms.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_page.dart';

import 'food_reference_test.dart' show fixtureFood;

const _account = '88888888-8888-4888-8888-888888888888';

class _Catalog extends LocalFoodRepository {
  final asked = <String>[];
  _Catalog() : super(() async => throw StateError('no public database'));

  @override
  Future<FoodReference?> photoFood(String id, String version) async {
    asked.add(id);
    return id == 'food:missing'
        ? null
        : FoodReference.fromJson(fixtureFood(id));
  }
}

class _Engine implements FoodPhotoEngine {
  final String state;
  final List<double> scores;
  _Engine(this.state, this.scores);
  @override
  Future<String> status() async => state;
  @override
  Future<List<double>> classify(String imagePath) async => scores;
}

const _classes = '''{"classes":[
 {"slug":"arroz","name":"Arroz","foodId":"rice","versionId":"v"},
 {"slug":"feijao","name":"Feijão","foodId":"beans","versionId":"v"},
 {"slug":"x","name":"X","foodId":"food:missing","versionId":"v"},
 {"slug":"bolo","name":"Bolo","foodId":"cake","versionId":"v"}]}''';

/// Real I/O (sqflite ffi) runs outside fake time; spinners never settle while loading.
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await t.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  sqfliteFfiInit();
  late Database db;
  late OfflineNutritionRepository repository;
  late _Catalog catalog;
  late File photo;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => NutritionLocalStore.createSchema(db),
      ),
    );
    catalog = _Catalog();
    repository = OfflineNutritionRepository(
      store: NutritionLocalStore(
        accountId: _account,
        currentAccountId: () => _account,
        databaseOpener: () async => db,
      ),
      catalog: catalog,
      dio: Dio(BaseOptions(baseUrl: 'https://fixture.invalid')),
      autoSync: false,
    );
    photo = File(
      '${Directory.systemTemp.createTempSync('tf-photo').path}/meal.jpg',
    )..writeAsBytesSync([1, 2, 3]);
  });

  tearDown(() async {
    repository.dispose();
    await db.close();
  });

  Future<void> open(WidgetTester t, _Engine engine) async {
    t.view.physicalSize = const Size(800, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        home: NutritionPage(
          accountId: _account,
          currentAccountId: () => _account,
          sessionChanges: ValueNotifier(0),
          repository: repository,
          photoClassifier: FoodPhotoClassifier(
            engine: engine,
            loadClasses: () async => _classes,
          ),
          pickPhoto: (_) async => photo.path,
        ),
      ),
    );
    await _settle(t);
  }

  testWidgets(
    'photo suggests catalog foods, deletes the photo and opens the entry form',
    (t) async {
      await open(t, _Engine('ready', [0.9, 0.05, 0.8, 0.4]));
      final button = find.text('Recognize from photo');
      await t.scrollUntilVisible(
        button,
        120,
        scrollable: find.byType(Scrollable).at(1),
      );
      await t.tap(button);
      await _settle(t);
      await t.tap(find.text('Take a photo'));
      await _settle(t);

      expect(find.text('Which of these is in the photo?'), findsOneWidget);
      // Above 0.1 and best first; a food missing from the catalog is skipped.
      expect(catalog.asked, ['rice', 'food:missing', 'cake']);
      expect(find.text('Isolated food rice'), findsOneWidget);
      expect(find.text('Isolated food cake'), findsOneWidget);
      expect(find.text('Isolated food beans'), findsNothing);
      expect(photo.existsSync(), isFalse);

      await t.tap(find.text('Isolated food rice'));
      await _settle(t);
      expect(find.byType(EntryFormPage), findsOneWidget);
    },
  );

  testWidgets('no confident food offers search by name', (t) async {
    await open(t, _Engine('ready', [0.01, 0.02, 0.03, 0.04]));
    final button = find.text('Recognize from photo');
    await t.scrollUntilVisible(
      button,
      120,
      scrollable: find.byType(Scrollable).at(1),
    );
    await t.tap(button);
    await _settle(t);
    await t.tap(find.text('Choose from gallery'));
    await _settle(t);
    expect(find.textContaining('No food was recognized'), findsOneWidget);
    expect(find.text('Search another food'), findsOneWidget);
    expect(photo.existsSync(), isFalse);
  });

  testWidgets('without the Play services runtime the photo button is hidden', (
    t,
  ) async {
    await open(t, _Engine('runtime_unavailable', const []));
    await t.scrollUntilVisible(
      find.text('Scan barcode'),
      120,
      scrollable: find.byType(Scrollable).at(1),
    );
    expect(find.text('Scan barcode'), findsOneWidget);
    expect(find.text('Recognize from photo'), findsNothing);
  });
}
