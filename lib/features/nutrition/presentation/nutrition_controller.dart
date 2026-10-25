import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/nutrition.dart';
import 'nutrition_messages.dart';

/// Read state for a single signed-in account. The view owns navigation and input.
class NutritionController extends ChangeNotifier {
  final NutritionRepository repository;
  final String accountId;
  final String? Function() currentAccountId;
  final Duration searchDelay;
  NutritionController({
    required this.repository,
    required this.accountId,
    required this.currentAccountId,
    DateTime? initialDate,
    this.searchDelay = const Duration(milliseconds: 400),
  }) : _date = initialDate ?? DateTime.now();

  bool _disposed = false, _invalidated = false;
  int _generation = 0, _ownGeneration = 0;
  Timer? _debounce;
  DateTime _date;
  bool _loading = true,
      _moreBusy = false,
      _ownMoreBusy = false,
      _ownLoading = true;
  String? _error, _ownError, _cursor, _ownCursor;
  List<Json> _entries = const [], _foods = const [];
  Json? _summary;
  String _queryInput = '', _ownQuery = '';

  bool get active =>
      !_disposed && !_invalidated && currentAccountId() == accountId;
  DateTime get date => _date;
  bool get loading => _loading;
  bool get moreBusy => _moreBusy;
  bool get ownMoreBusy => _ownMoreBusy;
  bool get ownLoading => _ownLoading;
  String? get error => _error;
  String? get ownError => _ownError;
  String? get cursor => _cursor;
  String? get ownCursor => _ownCursor;
  List<Json> get entries => _entries;
  List<Json> get foods => _foods;
  Json? get summary => _summary;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  /// Once the identity changes, this controller cannot be reused for another login.
  void accountChanged() {
    if (_disposed || _invalidated || currentAccountId() == accountId) return;
    _invalidated = true;
    _generation++;
    _ownGeneration++;
    _debounce?.cancel();
    _entries = const [];
    _foods = const [];
    _summary = null;
    _cursor = _ownCursor = null;
    _error = _ownError = null;
    _loading = _ownLoading = _moreBusy = _ownMoreBusy = false;
    _queryInput = _ownQuery = '';
    _changed();
  }

  Future<void> selectDate(DateTime value) async {
    if (!active) return;
    _date = value;
    await load();
  }

  void queryChanged(String value) {
    if (!active) return;
    _queryInput = value;
    _debounce?.cancel();
    _debounce = Timer(searchDelay, searchOwn);
  }

  Future<void> submitQuery(String value) async {
    if (!active) return;
    _queryInput = value;
    return searchOwn();
  }

  Future<void> load() async {
    if (!active) return;
    final g = ++_generation;
    _loading = true;
    _moreBusy = false;
    _error = null;
    _entries = const [];
    _summary = null;
    _cursor = null;
    _changed();
    try {
      final values = await Future.wait<Object>([
        repository.entries(localDay(_date), offsetZone(_date)),
        repository.summary(localDay(_date), offsetZone(_date)),
      ]);
      if (!active || g != _generation) return;
      final records = values[0] as NutritionPageData;
      _entries = List.unmodifiable(records.items);
      _cursor = records.cursor;
      _summary = values[1] as Json;
    } catch (e) {
      if (active && g == _generation) _error = nutritionError(e);
    } finally {
      if (active && g == _generation) {
        _loading = false;
        _changed();
      }
    }
  }

  Future<void> searchOwn() async {
    _debounce?.cancel();
    if (!active) return;
    final g = ++_ownGeneration;
    final query = _queryInput.trim();
    _ownQuery = query;
    _ownLoading = true;
    _ownMoreBusy = false;
    _ownError = null;
    _foods = const [];
    _ownCursor = null;
    _changed();
    try {
      final page = await repository.foods(q: query);
      if (active && g == _ownGeneration) {
        _foods = List.unmodifiable(page.items);
        _ownCursor = page.cursor;
      }
    } catch (e) {
      if (active && g == _ownGeneration) _ownError = nutritionError(e);
    } finally {
      if (active && g == _ownGeneration) {
        _ownLoading = false;
        _changed();
      }
    }
  }

  Future<void> more(bool own) async {
    if (!active ||
        (own ? _ownLoading || _ownMoreBusy : _loading || _moreBusy)) {
      return;
    }
    final token = own ? _ownCursor : _cursor;
    if (token == null) return;
    final g = own ? _ownGeneration : _generation;
    bool current() => active && g == (own ? _ownGeneration : _generation);
    if (own) {
      _ownMoreBusy = true;
      _ownError = null;
    } else {
      _moreBusy = true;
      _error = null;
    }
    _changed();
    try {
      final result = own
          ? await repository.foods(q: _ownQuery, cursor: token)
          : await repository.entries(
              localDay(_date),
              offsetZone(_date),
              cursor: token,
            );
      if (current()) {
        if (own) {
          _foods = List.unmodifiable([..._foods, ...result.items]);
          _ownCursor = result.cursor;
        } else {
          _entries = List.unmodifiable([..._entries, ...result.items]);
          _cursor = result.cursor;
        }
      }
    } catch (e) {
      if (current()) {
        if (own) {
          _ownError = nutritionError(e);
        } else {
          _error = nutritionError(e);
        }
      }
    } finally {
      if (current()) {
        if (own) {
          _ownMoreBusy = false;
        } else {
          _moreBusy = false;
        }
        _changed();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _ownGeneration++;
    _debounce?.cancel();
    _entries = const [];
    _foods = const [];
    _summary = null;
    _cursor = _ownCursor = null;
    _error = _ownError = null;
    _queryInput = _ownQuery = '';
    super.dispose();
  }
}
