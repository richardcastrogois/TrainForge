import 'package:flutter/foundation.dart';
import '../domain/nutrition.dart';
import 'nutrition_messages.dart';

/// Refresh current read metadata without ever sending it in a mutation.
class EntryReadController extends ChangeNotifier {
  final NutritionRepository repository;
  Json entry;
  bool loading = false, _disposed = false;
  String? error, locale;
  int _generation = 0;
  EntryReadController({required this.repository, required this.entry});
  bool get localized => repository is LocalizedNutritionRepository;
  Future<void> load(String language) async {
    if (_disposed) return;
    locale = language;
    if (!localized) return;
    final generation = ++_generation;
    loading = true;
    error = null;
    notifyListeners();
    final id = entry['id'] as String,
        foodId = entry['foodId'],
        version = entry['foodVersion'];
    try {
      final value = await (repository as LocalizedNutritionRepository)
          .localizedEntry(id, locale: language);
      if (_disposed || generation != _generation) return;
      if (value['id'] != id ||
          value['foodId'] != foodId ||
          value['foodVersion'] != version) {
        throw const FormatException('Entry identity changed');
      }
      final display = EntryFoodDisplay.fromEntry(value);
      if (display?.catalog.locale != language) {
        throw const FormatException('Entry locale changed');
      }
      entry = value;
    } catch (e) {
      if (!_disposed && generation == _generation) error = nutritionError(e);
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> edited(Json value) async {
    if (_disposed) return;
    _generation++;
    entry = value;
    if (locale != null && localized) {
      await load(locale!);
    } else {
      notifyListeners();
    }
  }

  String name(String language) => entryDisplayName(
    loading || error != null
        ? (Map<String, dynamic>.from(entry)..remove('foodDisplay'))
        : entry,
    language,
  );
  EntryFoodDisplay? get display =>
      loading || error != null ? null : EntryFoodDisplay.fromEntry(entry);
  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
