import 'dart:convert';

/// Contract for the original session engine. Not a practice/content permission,
/// a persistence implementation, or an enabled application route.
const activitySessionContract = 'trainforge.activity-session/1';

final _uuid = RegExp(
  r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$',
);
final _asset = RegExp(r'^[A-Za-z0-9][A-Za-z0-9:._/-]{0,199}$');
final _version = RegExp(r'^[a-f0-9]{64}$');

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid activity object');
  }
  return value;
}

String _text(Object? value, RegExp pattern) {
  if (value is! String || !pattern.hasMatch(value)) {
    throw const FormatException('Invalid activity identity');
  }
  return value;
}

int _integer(Object? value, int minimum, int maximum) {
  if (value is! int || value < minimum || value > maximum) {
    throw const FormatException('Invalid activity number');
  }
  return value;
}

List<dynamic> _list(Object? value, int maximum) {
  if (value is! List || value.length > maximum) {
    throw const FormatException('Invalid activity list');
  }
  return value;
}

DateTime _instant(Object? value) {
  if (value is! String) throw const FormatException('Missing activity time');
  final parts = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d{1,6})?Z$',
  ).firstMatch(value);
  if (parts == null) throw const FormatException('Invalid activity time');
  final year = int.parse(parts[1]!);
  final month = int.parse(parts[2]!);
  final day = int.parse(parts[3]!);
  if (year < 1900 ||
      year > 2100 ||
      month < 1 ||
      month > 12 ||
      day < 1 ||
      day > DateTime.utc(year, month + 1, 0).day ||
      int.parse(parts[4]!) > 23 ||
      int.parse(parts[5]!) > 59 ||
      int.parse(parts[6]!) > 59) {
    throw const FormatException('Invalid activity time');
  }
  return DateTime.parse(value);
}

enum ActivityState { started, paused, partial, completed, cancelled }

class ActivityTarget {
  final int? repetitions, durationMilliseconds;
  ActivityTarget._(this.repetitions, this.durationMilliseconds);
  factory ActivityTarget._parse(
    Map<String, dynamic> j,
    String mode, {
    bool actual = false,
  }) {
    final reps = j['repetitions'];
    final duration = j['durationMilliseconds'];
    if (mode == 'repetitions' && duration == null) {
      return ActivityTarget._(_integer(reps, actual ? 0 : 1, 10000), null);
    }
    if (mode == 'duration' && reps == null) {
      return ActivityTarget._(
        null,
        _integer(duration, actual ? 0 : 1, 86400000),
      );
    }
    throw const FormatException('Invalid activity measurement');
  }
}

class ActivityItem {
  final int position;
  final String movementId, movementVersion, mode;
  final List<ActivityTarget> targets;
  ActivityItem._(
    this.position,
    this.movementId,
    this.movementVersion,
    this.mode,
    this.targets,
  );
  factory ActivityItem._parse(Map<String, dynamic> j) {
    final mode = j['mode'];
    if (mode != 'repetitions' && mode != 'duration') {
      throw const FormatException('Unknown activity measurement mode');
    }
    final targets = _list(j['targets'], 1000);
    if (targets.isEmpty) {
      throw const FormatException('Missing activity targets');
    }
    return ActivityItem._(
      _integer(j['position'], 0, 10000),
      _text(j['movementId'], _asset),
      _text(j['movementVersion'], _version),
      mode as String,
      List.unmodifiable(
        targets.map((t) => ActivityTarget._parse(_object(t), mode)),
      ),
    );
  }
}

class ActivityRecordedSet {
  final String commandId;
  final DateTime recordedAt;
  final int position, number;
  final ActivityTarget actual;
  final String? loadKg;
  ActivityRecordedSet._(
    this.commandId,
    this.recordedAt,
    this.position,
    this.number,
    this.actual,
    this.loadKg,
  );
}

class ActivityPause {
  final DateTime startedAt;
  final DateTime? endedAt;
  ActivityPause._(this.startedAt, this.endedAt);
}

class ActivitySessionSnapshot {
  final String id, ownerId, occurrenceId, programId, programVersion, sessionKey;
  final ActivityState state;
  final int revision, activeMilliseconds;
  final DateTime startedAt, lastEventAt;
  final DateTime? endedAt;
  final List<ActivityItem> items;
  final List<ActivityRecordedSet> sets;
  final List<ActivityPause> pauses;

  ActivitySessionSnapshot._({
    required this.id,
    required this.ownerId,
    required this.occurrenceId,
    required this.programId,
    required this.programVersion,
    required this.sessionKey,
    required this.state,
    required this.revision,
    required this.activeMilliseconds,
    required this.startedAt,
    required this.lastEventAt,
    required this.endedAt,
    required this.items,
    required this.sets,
    required this.pauses,
  });

  bool get isOpen =>
      state == ActivityState.started || state == ActivityState.paused;
  bool get canPause => state == ActivityState.started;
  bool get canResume => state == ActivityState.paused;
  int get plannedSets => items.fold(0, (n, item) => n + item.targets.length);
  bool get canComplete => isOpen && sets.length == plannedSets;

  factory ActivitySessionSnapshot.fromJson(Map<String, dynamic> j) {
    if (j['contract'] != activitySessionContract) {
      throw const FormatException('Unknown activity session contract');
    }
    final state = ActivityState.values
        .where((s) => s.name == j['state'])
        .firstOrNull;
    if (state == null) throw const FormatException('Unknown activity state');
    final source = _object(j['source']);
    final start = _instant(j['startedAt']), last = _instant(j['lastEventAt']);
    final end = j['endedAt'] == null ? null : _instant(j['endedAt']);
    final terminal =
        state != ActivityState.started && state != ActivityState.paused;
    if (last.isBefore(start) ||
        terminal != (end != null) ||
        (end != null && end != last)) {
      throw const FormatException('Invalid activity timeline');
    }
    final items = _list(
      j['items'],
      100,
    ).map((i) => ActivityItem._parse(_object(i))).toList();
    final positions = {for (final item in items) item.position: item};
    final total = items.fold(0, (n, item) => n + item.targets.length);
    if (items.isEmpty || positions.length != items.length || total > 1000) {
      throw const FormatException('Invalid activity prescription');
    }
    final pauses = <ActivityPause>[];
    DateTime previousEnd = start;
    var pausedMicros = 0;
    for (final raw in _list(j['pauses'], 4096)) {
      final p = _object(raw);
      final from = _instant(p['startedAt']);
      final to = p['endedAt'] == null ? null : _instant(p['endedAt']);
      if (from.isBefore(previousEnd) ||
          from.isAfter(last) ||
          (pauses.isNotEmpty && pauses.last.endedAt == null) ||
          (to != null && (to.isBefore(from) || to.isAfter(last)))) {
        throw const FormatException('Invalid activity pause');
      }
      pauses.add(ActivityPause._(from, to));
      previousEnd = to ?? last;
      pausedMicros += (to ?? last).difference(from).inMicroseconds;
    }
    final openPause = pauses.isNotEmpty && pauses.last.endedAt == null;
    if ((state == ActivityState.paused) != openPause ||
        (openPause && pauses.last.startedAt != last)) {
      throw const FormatException('Invalid paused activity state');
    }
    final active = _integer(j['activeMilliseconds'], 0, 6400000000000);
    final expectedActive =
        (last.difference(start).inMicroseconds - pausedMicros) ~/ 1000;
    if (active != expectedActive) {
      throw const FormatException(
        'Activity duration does not match its timeline',
      );
    }
    final sets = <ActivityRecordedSet>[];
    final setKeys = <String>{}, commandIds = <String>{};
    DateTime previousSet = start;
    for (final raw in _list(j['sets'], 1000)) {
      final row = _object(raw), set = _object(row['set']);
      final pos = _integer(set['position'], 0, 10000);
      final item = positions[pos];
      if (item == null) throw const FormatException('Unknown activity slot');
      final number = _integer(set['number'], 1, item.targets.length);
      final commandId = _text(row['commandId'], _uuid);
      final at = _instant(row['recordedAt']);
      final kg = set['loadKg'];
      if (!setKeys.add('$pos/$number') ||
          !commandIds.add(commandId) ||
          at.isBefore(previousSet) ||
          at.isAfter(last) ||
          (kg != null &&
              (kg is! String ||
                  !RegExp(
                    r'^(0|[1-9][0-9]{0,5})(\.[0-9]{1,3})?$',
                  ).hasMatch(kg))) ||
          pauses.any(
            (p) =>
                at.isAfter(p.startedAt) &&
                (p.endedAt == null || at.isBefore(p.endedAt!)),
          )) {
        throw const FormatException('Invalid recorded activity set');
      }
      previousSet = at;
      sets.add(
        ActivityRecordedSet._(
          commandId,
          at,
          pos,
          number,
          ActivityTarget._parse(set, item.mode, actual: true),
          kg as String?,
        ),
      );
    }
    if (state == ActivityState.completed && sets.length != total) {
      throw const FormatException('Completed session has unrecorded sets');
    }
    return ActivitySessionSnapshot._(
      id: _text(j['id'], _uuid),
      ownerId: _text(j['ownerId'], _uuid),
      occurrenceId: _text(j['occurrenceId'], _uuid),
      programId: _text(source['programId'], _asset),
      programVersion: _text(source['programVersion'], _version),
      sessionKey: _text(source['sessionKey'], _asset),
      state: state,
      revision: _integer(j['revision'], 1, 4098),
      activeMilliseconds: active,
      startedAt: start,
      lastEventAt: last,
      endedAt: end,
      items: List.unmodifiable(items),
      sets: List.unmodifiable(sets),
      pauses: List.unmodifiable(pauses),
    );
  }

  /// Display estimate only. Wall-clock changes never mutate recorded facts.
  Duration elapsedAt(DateTime now) {
    if (state != ActivityState.started || now.isBefore(lastEventAt)) {
      return Duration(milliseconds: activeMilliseconds);
    }
    final paused = pauses.fold<int>(
      0,
      (n, p) => n + p.endedAt!.difference(p.startedAt).inMicroseconds,
    );
    return Duration(
      microseconds: now.difference(startedAt).inMicroseconds - paused,
    );
  }

  String get _prescription => jsonEncode([
    id,
    ownerId,
    occurrenceId,
    programId,
    programVersion,
    sessionKey,
    startedAt.toIso8601String(),
    for (final item in items)
      [
        item.position,
        item.movementId,
        item.movementVersion,
        item.mode,
        for (final target in item.targets)
          [target.repetitions, target.durationMilliseconds],
      ],
  ]);

  static String _record(ActivityRecordedSet s) => jsonEncode([
    s.commandId,
    s.recordedAt.toIso8601String(),
    s.position,
    s.number,
    s.actual.repetitions,
    s.actual.durationMilliseconds,
    s.loadKg,
  ]);

  String get _facts => jsonEncode([
    _prescription,
    state.name,
    revision,
    activeMilliseconds,
    lastEventAt.toIso8601String(),
    endedAt?.toIso8601String(),
    for (final s in sets) _record(s),
    for (final p in pauses)
      [p.startedAt.toIso8601String(), p.endedAt?.toIso8601String()],
  ]);
}

/// In-memory response projection only. No local save, network or success claim.
/// A future route must invalidate it when its authenticated account changes.
class ActivitySessionProjection {
  final String ownerId, sessionId;
  ActivitySessionSnapshot? _snapshot;
  bool _invalidated = false;
  ActivitySessionProjection({required this.ownerId, required this.sessionId}) {
    _text(ownerId, _uuid);
    _text(sessionId, _uuid);
  }
  ActivitySessionSnapshot? get snapshot => _snapshot;
  void invalidate() {
    _snapshot = null;
    _invalidated = true;
  }

  bool accept(ActivitySessionSnapshot next) {
    if (_invalidated) {
      throw StateError('Activity account context is no longer active');
    }
    if (next.ownerId != ownerId || next.id != sessionId) {
      throw const FormatException('Activity account or session mismatch');
    }
    final old = _snapshot;
    if (old != null) {
      if (next.revision < old.revision) return false;
      if (next._prescription != old._prescription ||
          next.activeMilliseconds < old.activeMilliseconds ||
          next.lastEventAt.isBefore(old.lastEventAt)) {
        throw const FormatException(
          'Activity response changed immutable facts',
        );
      }
      if (next.revision == old.revision) {
        if (next._facts != old._facts) {
          throw const FormatException('Conflicting activity revision');
        }
        return false;
      }
      if (!old.isOpen ||
          next.sets.length < old.sets.length ||
          next.pauses.length < old.pauses.length) {
        throw const FormatException(
          'Activity response changed confirmed history',
        );
      }
      for (var i = 0; i < old.sets.length; i++) {
        if (ActivitySessionSnapshot._record(old.sets[i]) !=
            ActivitySessionSnapshot._record(next.sets[i])) {
          throw const FormatException(
            'Activity response replaced a confirmed set',
          );
        }
      }
      for (var i = 0; i < old.pauses.length; i++) {
        final a = old.pauses[i], b = next.pauses[i];
        if (a.startedAt != b.startedAt ||
            (a.endedAt != null && a.endedAt != b.endedAt)) {
          throw const FormatException(
            'Activity response replaced a confirmed pause',
          );
        }
      }
    }
    _snapshot = next;
    return true;
  }
}

class ActivityCommandResult {
  final ActivitySessionSnapshot snapshot;
  final int appliedRevision;
  final bool replayed;
  ActivityCommandResult._(this.snapshot, this.appliedRevision, this.replayed);
  factory ActivityCommandResult.fromJson(Map<String, dynamic> j) {
    final snapshot = ActivitySessionSnapshot.fromJson(_object(j['snapshot']));
    final applied = _integer(j['appliedRevision'], 2, snapshot.revision);
    if (j['replayed'] is! bool ||
        (j['replayed'] == false && applied != snapshot.revision)) {
      throw const FormatException('Invalid activity command result');
    }
    return ActivityCommandResult._(snapshot, applied, j['replayed'] as bool);
  }
}

/// A rest deadline supplied by an explicit choice, never a generated prescription.
class ActivityRestDeadline {
  final DateTime endsAt;
  const ActivityRestDeadline(this.endsAt);
  Duration remainingAt(DateTime now) {
    final remaining = endsAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
