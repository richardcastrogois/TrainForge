import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/food_reference/data/food_photo_classifier.dart';

class _Engine implements FoodPhotoEngine {
  String state = 'ready';
  List<double> scores = const [];
  Object? error;
  @override
  Future<String> status() async {
    if (error case final e?) throw e;
    return state;
  }

  @override
  Future<List<double>> classify(String imagePath) async {
    if (error case final e?) throw e;
    return scores;
  }
}

String _classes(int n) => jsonEncode({
  'classes': [
    for (var i = 0; i < n; i++)
      {
        'slug': 's$i',
        'name': 'Alimento $i',
        'foodId': 'food:$i',
        'versionId': 'v$i',
      },
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled class list matches the model output and points to catalog foods',
    () {
      final data =
          jsonDecode(
                File(
                  'assets/models/food_photo_classes.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final classes = data['classes'] as List;
      expect(data['input'], [1, 224, 224, 3]);
      expect(classes, hasLength(370));
      expect(classes.map((c) => c['slug']).toSet(), hasLength(370));
      for (final c in classes) {
        expect(c['foodId'], startsWith('food:'));
        expect((c['versionId'] as String).length, 64);
        expect((c['name'] as String).trim(), isNotEmpty);
      }
      expect(
        File('assets/models/${data['model']}').lengthSync(),
        lessThan(6 * 1024 * 1024),
      );
    },
  );

  test('suggests foods above the threshold, best first and limited', () async {
    final engine = _Engine()..scores = [0.05, 0.9, 0.3, 0.6];
    final classifier = FoodPhotoClassifier(
      engine: engine,
      loadClasses: () async => _classes(4),
    );
    final got = await classifier.suggest('/photo.jpg', limit: 2, minScore: 0.1);
    expect(got.map((s) => s.food.slug), ['s1', 's3']);
    expect(got.first.food.foodId, 'food:1');
  });

  test('a score list of the wrong size yields no suggestion', () async {
    final engine = _Engine()..scores = [0.9];
    final classifier = FoodPhotoClassifier(
      engine: engine,
      loadClasses: () async => _classes(4),
    );
    expect(await classifier.suggest('/photo.jpg'), isEmpty);
  });

  test(
    'missing runtime or native side means unavailable, never a crash',
    () async {
      final engine = _Engine()..state = 'runtime_unavailable';
      final classifier = FoodPhotoClassifier(
        engine: engine,
        loadClasses: () async => _classes(1),
      );
      expect(await classifier.available(), isFalse);
      engine.error = PlatformException(code: 'unavailable');
      expect(await classifier.available(), isFalse);
      expect(await classifier.suggest('/photo.jpg'), isEmpty);
      engine.error = MissingPluginException();
      expect(await classifier.available(), isFalse);
      expect(await classifier.suggest('/photo.jpg'), isEmpty);
    },
  );

  test(
    'native engine reports unavailable when the channel is not registered',
    () async {
      expect(
        await FoodPhotoClassifier(
          loadClasses: () async => _classes(1),
        ).available(),
        isFalse,
      );
    },
  );
}
