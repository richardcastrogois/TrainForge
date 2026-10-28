import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../domain/meals.dart';
import '../domain/nutrition.dart';
import 'nutrition_messages.dart';

/// Edits group metadata only. Item revisions, times and quantities are independent.
class MealMetadataController extends ChangeNotifier {
  final MealRepository repository;
  final MealMetadata original;
  final String accountId;
  final String? Function() currentAccountId;
  final Duration retryWindow;
  MealMetadataController({
    required this.repository,
    required this.original,
    required this.accountId,
    required this.currentAccountId,
    this.retryWindow = const Duration(hours: 24),
  }) : _title = original.title,
       _when = DateTime.parse(original.occurredAt).toLocal(),
       _timezone = original.timezone;
  String _title, _timezone;
  DateTime _when;
  bool _disposed = false, _invalidated = false;
  bool busy = false, reviewed = false, conflict = false;
  Json? _pending;
  String _key = mutationKey();
  Stopwatch? _age;
  String? error;
  ConfirmedMeal? confirmed;
  bool get active =>
      !_disposed && !_invalidated && currentAccountId() == accountId;
  bool get uncertain => _pending != null;
  bool get locked => busy || uncertain || confirmed != null;
  String get title => _title;
  DateTime get when => _when;
  String get timezone => _timezone;
  bool get dirty =>
      _title != original.title ||
      _timezone != original.timezone ||
      !_when.isAtSameMomentAs(DateTime.parse(original.occurredAt));
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void accountChanged() {
    if (_disposed || _invalidated || currentAccountId() == accountId) return;
    _invalidated = true;
    _title = '';
    _pending = null;
    _age?.stop();
    confirmed = null;
    error = null;
    busy = reviewed = conflict = false;
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
    _timezone = offsetZone(value);
    reviewed = false;
    error = null;
    _changed();
  }

  void setReviewed(bool value) {
    if (!active || locked) return;
    reviewed = value;
    _changed();
  }

  Future<void> submit() async {
    if (!active || busy || conflict || confirmed != null) return;
    if (_pending != null && (_age?.elapsed ?? Duration.zero) >= retryWindow) {
      conflict = true;
      error =
          'O registro ou a conta mudou. Atualize o histórico antes de corrigir.';
      _changed();
      return;
    }
    if (_pending == null) {
      if (!reviewed ||
          !dirty ||
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
        'timezone': _timezone,
        'revision': original.revision,
        'reviewed': true,
      };
      _age = Stopwatch()..start();
    }
    busy = true;
    error = null;
    _changed();
    try {
      final result = await repository.editMeal(
        original.id,
        copyMealJson(_pending!),
        _key,
      );
      if (!active) return;
      if (result.deletedAt != null ||
          result.meal.id != original.id ||
          result.meal.revision != original.revision + 1 ||
          result.meal.title != _pending!['title'] ||
          result.meal.timezone != _pending!['timezone'] ||
          !sameMealInstant(result.meal.occurredAt, _pending!['occurredAt'])) {
        throw const FormatException('Meal metadata confirmation mismatch');
      }
      confirmed = result;
      _pending = null;
      _age?.stop();
    } catch (e) {
      if (!active) return;
      error = nutritionError(e);
      if (e is DioException) {
        if (e.response?.statusCode == 409) {
          conflict = true;
        } else if ({400, 404, 413, 415, 429}.contains(e.response?.statusCode)) {
          _pending = null;
          _age?.stop();
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
    _title = '';
    _pending = null;
    _age?.stop();
    confirmed = null;
    super.dispose();
  }
}
