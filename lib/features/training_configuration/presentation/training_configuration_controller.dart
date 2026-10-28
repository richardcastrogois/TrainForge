import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart'
    show mutationKey;
import '../domain/training_configuration.dart';

class TrainingConfigurationController extends ChangeNotifier {
  final TrainingConfigurationRepository repository;
  final String accountId;
  final String? Function() currentAccountId;
  late TrainingDraft draft;
  TrainingSnapshot? snapshot;
  final Map<String, TrainingResourceOption> labels = {};
  Set<String> unavailable = {};
  int dataEpoch = 0;
  bool ready = false;
  bool loading = true,
      saving = false,
      uncertain = false,
      optionsLoading = false,
      moreBusy = false,
      _disposed = false,
      _invalidated = false;
  TrainingFailure? error;
  String? optionsError, cursor;
  Map<String, String> issues = {};
  String _baseline = '', _query = '';
  Map<String, dynamic>? _pending;
  String? _key;
  int _generation = 0, _optionsGeneration = 0;
  Timer? _search;
  TrainingConfigurationController({
    required this.repository,
    required this.accountId,
    required this.currentAccountId,
    required String timezone,
  }) {
    draft = TrainingDraft(timezone: timezone);
    _baseline = draft.fingerprint;
  }
  bool get active =>
      !_disposed && !_invalidated && currentAccountId() == accountId;
  bool get editable => active && ready && !loading && !saving && !uncertain;
  bool get dirty => draft.fingerprint != _baseline;
  List<TrainingResourceOption> options = [];
  void changed() {
    if (!_disposed) notifyListeners();
  }

  void update(void Function(TrainingDraft) change) {
    if (!editable) return;
    change(draft);
    issues = {};
    error = null;
    changed();
  }

  void accountChanged() {
    if (_disposed || _invalidated || currentAccountId() == accountId) return;
    _invalidated = true;
    _generation++;
    _optionsGeneration++;
    _search?.cancel();
    _pending = null;
    _key = null;
    labels.clear();
    options = [];
    unavailable = {};
    snapshot = null;
    ready = false;
    draft = TrainingDraft(timezone: 'UTC');
    _baseline = draft.fingerprint;
    issues = {};
    error = null;
    loading = saving = uncertain = optionsLoading = moreBusy = false;
    changed();
  }

  Future<void> load() async {
    if (!active || saving || uncertain) return;
    final g = ++_generation;
    loading = true;
    error = null;
    changed();
    try {
      final value = await repository.load();
      if (!active || g != _generation) return;
      _apply(value);
    } catch (e) {
      if (active && g == _generation) {
        error = e is TrainingFailure
            ? e
            : const TrainingFailure('training_configuration_unavailable');
      }
    } finally {
      if (active && g == _generation) {
        loading = false;
        changed();
      }
    }
  }

  void _apply(TrainingCurrent result) {
    ready = true;
    dataEpoch++;
    snapshot = result.snapshot;
    draft = snapshot?.draft() ?? TrainingDraft(timezone: draft.timezone);
    labels.addAll({for (final v in result.labels) v.reference.key: v});
    unavailable = result.unavailable.map((v) => v.key).toSet();
    _baseline = draft.fingerprint;
    issues = {};
  }

  Future<bool> save() async {
    if (!active || !ready || loading || saving) return false;
    if (_pending == null) {
      issues = draft.validate();
      if (issues.isNotEmpty) {
        changed();
        return false;
      }
      _pending =
          jsonDecode(
                jsonEncode({
                  'revision': snapshot?.revision ?? 0,
                  'reviewed': true,
                  'configuration': draft.toJson(),
                }),
              )
              as Map<String, dynamic>;
      _key = mutationKey();
    }
    final g = ++_generation;
    saving = true;
    error = null;
    changed();
    try {
      final result = await repository.save(
        configObject(jsonDecode(jsonEncode(_pending))),
        _key!,
      );
      if (!active || g != _generation) return false;
      _apply(result);
      _pending = null;
      _key = null;
      uncertain = false;
      return true;
    } catch (e) {
      if (active && g == _generation) {
        error = e is TrainingFailure
            ? e
            : const TrainingFailure(
                'training_configuration_unavailable',
                uncertain: true,
              );
        uncertain = error!.uncertain;
        issues = error!.fields;
        if (!uncertain) {
          _pending = null;
          _key = null;
        }
      }
      return false;
    } finally {
      if (active && g == _generation) {
        saving = false;
        changed();
      }
    }
  }

  void search(String text) {
    if (!active) return;
    _search?.cancel();
    _search = Timer(
      const Duration(milliseconds: 350),
      () => loadOptions(q: text),
    );
  }

  Future<void> loadOptions({String? q, bool more = false}) async {
    if (!active || (more && (cursor == null || optionsLoading || moreBusy))) {
      return;
    }
    _search?.cancel();
    if (!more) {
      _query = q ?? _query;
      _optionsGeneration++;
      options = [];
      cursor = null;
      optionsLoading = true;
      moreBusy = false;
    } else {
      moreBusy = true;
    }
    final g = _optionsGeneration;
    optionsError = null;
    final prior = cursor;
    changed();
    try {
      final result = await repository.resources(
        q: _query,
        cursor: more ? prior : null,
      );
      if (!active || g != _optionsGeneration) return;
      options = List.unmodifiable(
        more ? [...options, ...result.items] : result.items,
      );
      cursor = result.cursor;
      labels.addAll({for (final v in result.items) v.reference.key: v});
    } catch (_) {
      if (active && g == _optionsGeneration) {
        optionsError = 'training_configuration_unavailable';
      }
    } finally {
      if (active && g == _optionsGeneration) {
        optionsLoading = moreBusy = false;
        changed();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _optionsGeneration++;
    _search?.cancel();
    _pending = null;
    _key = null;
    labels.clear();
    options = [];
    unavailable = {};
    super.dispose();
  }
}
