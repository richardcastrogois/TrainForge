import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../domain/meals.dart';
import '../domain/nutrition.dart';
import '../../food_reference/domain/food_reference.dart';
import 'nutrition_messages.dart';

class MealDiaryController extends ChangeNotifier {
  final MealRepository repository;
  final String accountId;
  final String? Function() currentAccountId;
  DateTime date;
  String locale;
  MealDiaryController({
    required this.repository,
    required this.accountId,
    required this.currentAccountId,
    required this.date,
    required this.locale,
  });
  bool _disposed = false, _invalidated = false;
  int _generation = 0;
  bool loading = false;
  String? error;
  MealDay? day;
  bool get active =>
      !_disposed && !_invalidated && currentAccountId() == accountId;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void accountChanged() {
    if (_disposed || _invalidated || currentAccountId() == accountId) return;
    _invalidated = true;
    _generation++;
    day = null;
    error = null;
    loading = false;
    _changed();
  }

  Future<void> load({DateTime? selectedDate, String? selectedLocale}) async {
    if (!active) return;
    if (selectedLocale != null && !foodNameLocales.contains(selectedLocale)) {
      throw const FormatException('Invalid meal locale');
    }
    date = selectedDate ?? date;
    locale = selectedLocale ?? locale;
    final g = ++_generation;
    loading = true;
    error = null;
    day = null;
    _changed();
    try {
      final value = await repository.mealDay(
        localDay(date),
        offsetZone(date),
        locale: locale,
      );
      if (!active || g != _generation) return;
      if (value.date != localDay(date) ||
          value.timezone != offsetZone(date) ||
          value.nameCatalog?.locale != locale) {
        throw const FormatException('Meal diary response scope changed');
      }
      day = value;
    } catch (e) {
      if (active && g == _generation) error = nutritionError(e);
    } finally {
      if (active && g == _generation) {
        loading = false;
        _changed();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    day = null;
    super.dispose();
  }
}

class MealDraftItem {
  final FoodReference food;
  final Json _input;
  MealDraftItem(this.food, Json input) : _input = copyMealJson(input);
  Json get input => copyMealJson(_input);
}

/// Memory-only draft. Unknown responses freeze the intention; this is not offline storage.
class MealDraftController extends ChangeNotifier {
  final MealRepository repository;
  final String accountId;
  final String? Function() currentAccountId;
  final Duration retryWindow;
  MealDraftController({
    required this.repository,
    required this.accountId,
    required this.currentAccountId,
    required DateTime occurredAt,
    this.retryWindow = const Duration(hours: 24),
  }) : _when = occurredAt,
       _initialWhen = occurredAt;
  bool _disposed = false, _invalidated = false;
  String _title = '';
  DateTime _when;
  final DateTime _initialWhen;
  final List<MealDraftItem> _items = [];
  Json? _pending;
  Stopwatch? _pendingAge;
  String _key = mutationKey();
  bool busy = false, reviewed = false, conflict = false;
  String? error;
  ConfirmedMeal? confirmed;
  bool get active =>
      !_disposed && !_invalidated && currentAccountId() == accountId;
  bool get uncertain => _pending != null;
  bool get locked => busy || uncertain || confirmed != null;
  bool get dirty =>
      _title.isNotEmpty ||
      _items.isNotEmpty ||
      !_when.isAtSameMomentAs(_initialWhen);
  String get title => _title;
  DateTime get when => _when;
  List<MealDraftItem> get items => List.unmodifiable(_items);
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void accountChanged() {
    if (_disposed || _invalidated || currentAccountId() == accountId) return;
    _invalidated = true;
    _items.clear();
    _pending = null;
    _pendingAge?.stop();
    _pendingAge = null;
    _title = '';
    error = null;
    confirmed = null;
    reviewed = false;
    busy = false;
    conflict = false;
    _changed();
  }

  void setTitle(String value) {
    if (!active || locked) return;
    _title = value;
    reviewed = false;
    error = null;
    _changed();
  }

  void setWhen(DateTime value) {
    if (!active || locked) return;
    _when = value;
    reviewed = false;
    error = null;
    _changed();
  }

  void setReviewed(bool value) {
    if (!active || locked) return;
    reviewed = value;
    _changed();
  }

  void add(FoodReference food, Json input) {
    if (!active || locked) return;
    final when = DateTime.tryParse(
      input['occurredAt'] is String ? input['occurredAt'] as String : '',
    );
    if (_items.length >= 32 ||
        input['foodId'] != food.id ||
        input['foodVersion'] != food.versionId ||
        input['revision'] != 0 ||
        input['quantity'] is! String ||
        !validDecimal(input['quantity'] as String, positive: true) ||
        !{'g', 'ml'}.contains(input['unit']) ||
        !{'measured', 'estimated'}.contains(input['quantityEvidence']) ||
        input['preparation'] is! String ||
        when == null ||
        input['timezone'] is! String) {
      throw const FormatException('Invalid prepared meal item');
    }
    _items.add(MealDraftItem(food, input));
    reviewed = false;
    error = null;
    _changed();
  }

  void remove(int index) {
    if (!active || locked) return;
    _items.removeAt(index);
    reviewed = false;
    error = null;
    _changed();
  }

  Future<void> submit() async {
    if (!active || busy || confirmed != null || conflict) return;
    if (_pending != null &&
        (_pendingAge?.elapsed ?? Duration.zero) >= retryWindow) {
      conflict = true;
      error =
          'O registro ou a conta mudou. Atualize o histórico antes de corrigir.';
      _changed();
      return;
    }
    if (_pending == null) {
      if (!reviewed ||
          _items.isEmpty ||
          _items.length > 32 ||
          _title.trim() != _title ||
          _title.runes.length > 80 ||
          RegExp(r'[\x00-\x1f\x7f]').hasMatch(_title)) {
        error =
            'Confira quantidade, unidade, data, preparo e campos informados.';
        _changed();
        return;
      }
      _pending = {
        'title': _title,
        'occurredAt': _when.toUtc().toIso8601String(),
        'timezone': offsetZone(_when),
        'reviewed': true,
        'items': _items.map((item) => item.input).toList(),
      };
      _pendingAge = Stopwatch()..start();
    }
    busy = true;
    error = null;
    _changed();
    try {
      final result = await repository.createMeal(copyMealJson(_pending!), _key);
      if (!active) return;
      if (result.deletedAt != null ||
          result.meal.revision != 1 ||
          result.entries.length != _items.length) {
        throw const FormatException('Meal confirmation mismatch');
      }
      confirmed = result;
      _pending = null;
      _pendingAge?.stop();
      _pendingAge = null;
    } catch (e) {
      if (!active) return;
      error = nutritionError(e);
      if (e is DioException) {
        final status = e.response?.statusCode;
        if (status == 409) {
          conflict = true;
        } else if ({400, 404, 413, 415, 429}.contains(status)) {
          _pending = null;
          _pendingAge?.stop();
          _pendingAge = null;
          _key = mutationKey();
          reviewed = false;
        }
      }
    } finally {
      if (active) {
        busy = false;
        _changed();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _items.clear();
    _pending = null;
    _pendingAge?.stop();
    _pendingAge = null;
    confirmed = null;
    super.dispose();
  }
}
