import 'package:flutter/foundation.dart';
import '../domain/activity_repository.dart';
import '../domain/activity_session.dart';

enum ActivityFeedback {
  readFailed,
  writeRejected,
  uncertain,
  conflict,
  retryExpired,
  confirmed,
  invalidSet,
  practiceUnavailable,
}

/// Memory-only intentions. A missing response never becomes a successful record
/// or a second command, and the authenticated account owns every accepted value.
class ActivityController extends ChangeNotifier {
  final ActivityRepository repository;
  final String accountId;
  final String? Function() currentAccountId;
  final Duration retryWindow;
  final String Function() commandKey;
  ActivityController({
    required this.repository,
    required this.accountId,
    required this.currentAccountId,
    this.retryWindow = const Duration(hours: 24),
    String Function()? commandKey,
  }) : commandKey = commandKey ?? newActivityCommandKey;

  ActivityFeed? feed;
  ActivityDetail? selected;
  ActivityFeedback? feedback;
  bool loading = false, detailLoading = false, busy = false;
  bool needsReconciliation = false;
  bool _disposed = false, _invalidated = false;
  int _feedGeneration = 0, _detailGeneration = 0;
  final _projections = <String, ActivitySessionProjection>{};
  final _known = <String, ActivityDetail>{};
  _ActivityIntent? _pending;
  Stopwatch? _pendingAge;

  bool get active =>
      !_disposed && !_invalidated && currentAccountId() == accountId;
  bool get uncertain => _pending != null;
  bool get locked => busy || uncertain || needsReconciliation;
  bool get canRecord =>
      active &&
      !locked &&
      selected?.snapshot.state == ActivityState.started &&
      selected!.practiceAvailable;
  bool get canPause => active && !locked && selected?.snapshot.canPause == true;
  bool get canResume =>
      active &&
      !locked &&
      selected?.snapshot.canResume == true &&
      selected!.practiceAvailable;
  bool get canComplete =>
      active && !locked && selected?.snapshot.canComplete == true;
  bool get canEnd => active && !locked && selected?.snapshot.isOpen == true;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void accountChanged() {
    if (_disposed || _invalidated || currentAccountId() == accountId) return;
    _invalidated = true;
    _feedGeneration++;
    _detailGeneration++;
    feed = null;
    selected = null;
    _projections.clear();
    _known.clear();
    _clearPending();
    loading = detailLoading = busy = needsReconciliation = false;
    feedback = null;
    _changed();
  }

  ActivityDetail _project(ActivityDetail value) {
    final snapshot = value.snapshot;
    if (snapshot.ownerId != accountId) {
      throw const FormatException('Activity account mismatch');
    }
    final previous = _known[snapshot.id];
    final projection = _projections.putIfAbsent(
      snapshot.id,
      () =>
          ActivitySessionProjection(ownerId: accountId, sessionId: snapshot.id),
    );
    projection.accept(snapshot);
    if (previous != null && previous.snapshot.revision > snapshot.revision) {
      return previous;
    }
    _known[snapshot.id] = value;
    return value;
  }

  void _acceptFeed(ActivityFeed value) {
    final sessions = value.sessions.map(_project).toList();
    feed = ActivityFeed(
      upcoming: value.upcoming,
      sessions: sessions,
      complete: value.complete,
    );
  }

  Future<void> load({bool preserveFeedback = false}) async {
    if (!active || locked) return;
    final generation = ++_feedGeneration;
    loading = true;
    if (!preserveFeedback) feedback = null;
    _changed();
    try {
      final value = await repository.load();
      if (!active || generation != _feedGeneration) return;
      _acceptFeed(value);
    } catch (_) {
      if (active && generation == _feedGeneration) {
        feedback = ActivityFeedback.readFailed;
      }
    } finally {
      if (active && generation == _feedGeneration) {
        loading = false;
        _changed();
      }
    }
  }

  Future<void> open(String id) async {
    if (!active || locked) return;
    final generation = ++_detailGeneration;
    detailLoading = true;
    feedback = null;
    selected = null;
    _changed();
    try {
      final value = await repository.detail(id);
      if (!active || generation != _detailGeneration) return;
      if (value.snapshot.id != id) {
        throw const FormatException('Activity session mismatch');
      }
      selected = _project(value);
    } catch (_) {
      if (active && generation == _detailGeneration) {
        feedback = ActivityFeedback.readFailed;
      }
    } finally {
      if (active && generation == _detailGeneration) {
        detailLoading = false;
        _changed();
      }
    }
  }

  bool backToFeed() {
    if (!active || locked) return false;
    _detailGeneration++;
    selected = null;
    detailLoading = false;
    feedback = null;
    _changed();
    return true;
  }

  Future<void> start(ActivityOccurrence occurrence) async {
    if (!active || locked) return;
    if (!occurrence.practiceAvailable) {
      feedback = ActivityFeedback.practiceUnavailable;
      _changed();
      return;
    }
    _pending = _ActivityIntent.start(occurrence.id, commandKey());
    _pendingAge = Stopwatch()..start();
    await _send();
  }

  Future<void> command(String action) async {
    if (!active || locked || selected == null) return;
    final allowed = switch (action) {
      'pause' => canPause,
      'resume' => canResume,
      'partial' || 'cancel' => canEnd,
      'complete' => canComplete,
      _ => false,
    };
    if (!allowed) return;
    _prepare(action);
    await _send();
  }

  Future<void> recordSet({
    required int position,
    required int number,
    required String measurement,
    String loadKg = '',
  }) async {
    if (!canRecord) return;
    final items = selected!.snapshot.items.where((i) => i.position == position);
    if (items.length != 1 ||
        number < 1 ||
        number > items.single.targets.length ||
        selected!.snapshot.sets.any(
          (s) => s.position == position && s.number == number,
        )) {
      _invalidSet();
      return;
    }
    final item = items.single;
    final kg = _decimal(loadKg, maximumWholeDigits: 6);
    if (loadKg.trim().isNotEmpty && kg == null) {
      _invalidSet();
      return;
    }
    int? repetitions, duration;
    if (item.mode == 'repetitions') {
      if (RegExp(r'^\d{1,5}$').hasMatch(measurement.trim())) {
        repetitions = int.tryParse(measurement.trim());
      }
      if (repetitions == null || repetitions > 10000) {
        _invalidSet();
        return;
      }
    } else {
      final seconds = _decimal(measurement, maximumWholeDigits: 5);
      if (seconds != null) {
        final parts = seconds.split('.');
        duration =
            int.parse(parts[0]) * 1000 +
            (parts.length == 1 ? 0 : int.parse(parts[1].padRight(3, '0')));
      }
      if (duration == null || duration > 86400000) {
        _invalidSet();
        return;
      }
    }
    _prepare('record_set', {
      'position': position,
      'number': number,
      'repetitions': repetitions,
      'durationMilliseconds': duration,
      'loadKg': kg,
    });
    await _send();
  }

  static String? _decimal(String raw, {required int maximumWholeDigits}) {
    final value = raw.trim().replaceAll(',', '.');
    if (!RegExp(
      '^\\d{1,$maximumWholeDigits}(\\.\\d{1,3})?\$',
    ).hasMatch(value)) {
      return null;
    }
    final parts = value.split('.');
    return '${int.parse(parts[0])}${parts.length == 1 ? '' : '.${parts[1]}'}';
  }

  void _invalidSet() {
    feedback = ActivityFeedback.invalidSet;
    _changed();
  }

  void _prepare(String action, [Map<String, dynamic>? set]) {
    final snapshot = selected!.snapshot;
    _pending = _ActivityIntent.command(
      snapshot.id,
      snapshot.revision,
      action,
      set,
      commandKey(),
    );
    _pendingAge = Stopwatch()..start();
  }

  Future<void> retry() async {
    if (!active || busy || _pending == null || needsReconciliation) return;
    if ((_pendingAge?.elapsed ?? Duration.zero) >= retryWindow) {
      feedback = ActivityFeedback.retryExpired;
      needsReconciliation = true;
      _changed();
      return;
    }
    await _send();
  }

  Future<void> _send() async {
    final intent = _pending;
    if (!active || busy || intent == null) return;
    _feedGeneration++;
    _detailGeneration++;
    loading = detailLoading = false;
    busy = true;
    feedback = null;
    _changed();
    var ended = false;
    try {
      final ActivityDetail value;
      if (intent.occurrenceId != null) {
        value = await repository.start(intent.occurrenceId!, intent.key);
        if (!active) return;
        if (value.snapshot.occurrenceId != intent.occurrenceId) {
          throw const FormatException('Started activity occurrence mismatch');
        }
      } else {
        final result = await repository.command(
          intent.sessionId!,
          expectedRevision: intent.expectedRevision!,
          action: intent.action!,
          confirmed: const {
            'partial',
            'complete',
            'cancel',
          }.contains(intent.action),
          set: intent.set == null ? null : Map.of(intent.set!),
          key: intent.key,
        );
        if (!active) return;
        value = result.detail;
        if (value.snapshot.id != intent.sessionId ||
            result.appliedRevision != intent.expectedRevision! + 1) {
          throw const FormatException('Activity command confirmation mismatch');
        }
      }
      selected = _project(value);
      ended = !selected!.snapshot.isOpen;
      _clearPending();
      needsReconciliation = false;
      feedback = ActivityFeedback.confirmed;
      final previous = feed;
      if (previous != null) {
        feed = ActivityFeed(
          upcoming: previous.upcoming
              .where((o) => o.id != selected!.snapshot.occurrenceId)
              .toList(),
          sessions: [
            selected!,
            ...previous.sessions.where(
              (s) => s.snapshot.id != selected!.snapshot.id,
            ),
          ],
          complete: previous.complete,
        );
      }
    } catch (error) {
      if (!active) return;
      if (error is ActivityFailure && !error.uncertain) {
        if (error.code == 'activity_conflict' || error.status == 409) {
          needsReconciliation = true;
          feedback = ActivityFeedback.conflict;
        } else if (error.code == 'activity_practice_unavailable') {
          needsReconciliation = true;
          feedback = ActivityFeedback.practiceUnavailable;
        } else if (error.status == 401 ||
            error.code == 'invalid_credential' ||
            error.code == 'activity_account_changed') {
          needsReconciliation = true;
          feedback = ActivityFeedback.writeRejected;
        } else {
          _clearPending();
          feedback = ActivityFeedback.writeRejected;
        }
      } else {
        feedback = ActivityFeedback.uncertain;
      }
    } finally {
      if (active) {
        busy = false;
        _changed();
      }
    }
    if (active && ended && !uncertain) await load(preserveFeedback: true);
  }

  /// An explicit read before a new decision, not proof that an unknown command
  /// succeeded. No automatic resubmission is made from a reloaded snapshot.
  Future<void> checkSession() async {
    if (!active || busy || detailLoading) return;
    final intent = _pending;
    final id = intent?.sessionId ?? selected?.snapshot.id;
    final generation = ++_detailGeneration;
    detailLoading = true;
    _changed();
    try {
      if (id != null) {
        final value = await repository.detail(id);
        if (!active || generation != _detailGeneration) return;
        if (value.snapshot.id != id ||
            value.snapshot.revision < (_known[id]?.snapshot.revision ?? 0)) {
          throw const FormatException('Activity check mismatch');
        }
        selected = _project(value);
      } else {
        final value = await repository.load();
        if (!active || generation != _detailGeneration) return;
        _acceptFeed(value);
        final matches = value.sessions.where(
          (s) => s.snapshot.occurrenceId == intent?.occurrenceId,
        );
        if (matches.isNotEmpty) {
          final value = await repository.detail(matches.first.snapshot.id);
          if (!active || generation != _detailGeneration) return;
          if (value.snapshot.occurrenceId != intent!.occurrenceId) {
            throw const FormatException('Activity check occurrence mismatch');
          }
          selected = _project(value);
        } else if (!value.complete && intent != null) {
          feedback = ActivityFeedback.uncertain;
          return;
        }
      }
      _clearPending();
      needsReconciliation = false;
      feedback = null;
    } catch (_) {
      if (active && generation == _detailGeneration) {
        feedback = ActivityFeedback.readFailed;
      }
    } finally {
      if (active && generation == _detailGeneration) {
        detailLoading = false;
        _changed();
      }
    }
  }

  void _clearPending() {
    _pending = null;
    _pendingAge?.stop();
    _pendingAge = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _feedGeneration++;
    _detailGeneration++;
    _clearPending();
    _projections.clear();
    _known.clear();
    feed = null;
    selected = null;
    super.dispose();
  }
}

class _ActivityIntent {
  final String? occurrenceId, sessionId, action;
  final int? expectedRevision;
  final Map<String, dynamic>? set;
  final String key;
  const _ActivityIntent.start(String this.occurrenceId, this.key)
    : sessionId = null,
      expectedRevision = null,
      action = null,
      set = null;
  _ActivityIntent.command(
    String this.sessionId,
    int this.expectedRevision,
    String this.action,
    Map<String, dynamic>? set,
    this.key,
  ) : occurrenceId = null,
      set = set == null ? null : Map.unmodifiable(set);
}
