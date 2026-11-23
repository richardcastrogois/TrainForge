import 'dart:convert';

import 'package:flutter/services.dart';

/// Native side: the bundled int8 model run by the LiteRT runtime from Google Play services.
abstract interface class FoodPhotoEngine {
  /// "ready", or a reason such as "runtime_unavailable" when Play services lacks LiteRT.
  Future<String> status();

  /// One probability per class, in the order of `assets/models/food_photo_classes.json`.
  Future<List<double>> classify(String imagePath);
}

class NativeFoodPhotoEngine implements FoodPhotoEngine {
  static const channel = MethodChannel('trainforge/food_photo');

  @override
  Future<String> status() async =>
      await channel.invokeMethod<String>('status') ?? 'unavailable';

  @override
  Future<List<double>> classify(String imagePath) async {
    final scores = await channel.invokeListMethod<double>('classify', {
      'path': imagePath,
    });
    return scores ?? const [];
  }
}

/// A catalog food the photo model can recognize.
class FoodPhotoClass {
  final String slug, name, foodId, versionId;
  const FoodPhotoClass({
    required this.slug,
    required this.name,
    required this.foodId,
    required this.versionId,
  });
}

class FoodPhotoSuggestion {
  final FoodPhotoClass food;
  final double score;
  const FoodPhotoSuggestion(this.food, this.score);
}

/// Suggests catalog foods for a meal photo. The model only chooses among known foods;
/// the person confirms each suggestion. Any failure means "photo unavailable", never a crash.
class FoodPhotoClassifier {
  static const classesAsset = 'assets/models/food_photo_classes.json';
  final FoodPhotoEngine engine;
  final Future<String> Function() _loadClasses;
  List<FoodPhotoClass>? _classes;

  FoodPhotoClassifier({
    FoodPhotoEngine? engine,
    Future<String> Function()? loadClasses,
  }) : engine = engine ?? NativeFoodPhotoEngine(),
       _loadClasses =
           loadClasses ?? (() => rootBundle.loadString(classesAsset));

  Future<bool> available() async {
    try {
      return await engine.status() == 'ready';
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false; // iOS and tests have no native classifier yet.
    }
  }

  Future<List<FoodPhotoClass>> classes() async {
    if (_classes case final cached?) return cached;
    final decoded = jsonDecode(await _loadClasses()) as Map<String, dynamic>;
    return _classes = [
      for (final item in decoded['classes'] as List)
        FoodPhotoClass(
          slug: item['slug'] as String,
          name: item['name'] as String,
          foodId: item['foodId'] as String,
          versionId: item['versionId'] as String,
        ),
    ];
  }

  /// Top suggestions above [minScore], best first. Empty when the photo cannot be classified.
  Future<List<FoodPhotoSuggestion>> suggest(
    String imagePath, {
    int limit = 5,
    double minScore = 0.1,
  }) async {
    final List<double> scores;
    try {
      scores = await engine.classify(imagePath);
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
    final known = await classes();
    if (scores.length != known.length) return const [];
    final ranked = [
      for (var i = 0; i < scores.length; i++)
        if (scores[i] >= minScore) FoodPhotoSuggestion(known[i], scores[i]),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return ranked.take(limit).toList();
  }
}
