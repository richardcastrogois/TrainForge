import 'dart:math';
import 'activity_session.dart';

final _identity = RegExp(
  r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$',
);
final _reference = RegExp(r'^[A-Za-z0-9][A-Za-z0-9:._/-]{0,199}$');
final _sha = RegExp(r'^[a-f0-9]{64}$');

Map<String, dynamic> activityObject(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid activity response');
  }
  return value;
}

String _string(Object? value, {RegExp? pattern, int maximum = 360}) {
  if (value is! String ||
      value.isEmpty ||
      value.runes.length > maximum ||
      RegExp(r'[\u0000-\u001f\u007f]').hasMatch(value) ||
      (pattern != null && !pattern.hasMatch(value))) {
    throw const FormatException('Invalid activity response field');
  }
  return value;
}

List<dynamic> _array(Object? value, int maximum) {
  if (value is! List || value.length > maximum) {
    throw const FormatException('Invalid activity response list');
  }
  return value;
}

bool _flag(Object? value) {
  if (value is! bool) {
    throw const FormatException('Invalid activity availability');
  }
  return value;
}

DateTime _time(Object? value) {
  final raw = _string(value, maximum: 40);
  if (!RegExp(r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d{1,6})?Z$').hasMatch(raw)) {
    throw const FormatException('Invalid scheduled activity time');
  }
  final date = DateTime.tryParse(raw);
  if (date == null ||
      date.year < 1900 ||
      date.year > 2100 ||
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}' !=
          raw.substring(0, 19)) {
    throw const FormatException('Invalid scheduled activity time');
  }
  return date;
}

class ActivityFailure implements Exception {
  final String code;
  final Map<String, String> fields;
  final bool uncertain;
  final int? status;
  const ActivityFailure(
    this.code, {
    this.fields = const {},
    this.uncertain = false,
    this.status,
  });
}

class ActivityOccurrence {
  final String id, timezone, programId, programVersion, sessionKey, title;
  final DateTime plannedFor;
  final bool practiceAvailable;
  const ActivityOccurrence({
    required this.id,
    required this.plannedFor,
    required this.timezone,
    required this.programId,
    required this.programVersion,
    required this.sessionKey,
    required this.title,
    required this.practiceAvailable,
  });
  factory ActivityOccurrence.fromJson(Map<String, dynamic> j) {
    final source = activityObject(j['source']);
    return ActivityOccurrence(
      id: _string(j['id'], pattern: _identity),
      plannedFor: _time(j['plannedFor']),
      timezone: _string(j['timezone'], maximum: 100),
      programId: _string(source['programId'], pattern: _reference),
      programVersion: _string(source['programVersion'], pattern: _sha),
      sessionKey: _string(source['sessionKey'], pattern: _reference),
      title: _string(j['title']),
      practiceAvailable: _flag(j['practiceAvailable']),
    );
  }
}

class ActivityMovementLabel {
  final String id, versionId, title;
  const ActivityMovementLabel({
    required this.id,
    required this.versionId,
    required this.title,
  });
  factory ActivityMovementLabel.fromJson(Map<String, dynamic> j) =>
      ActivityMovementLabel(
        id: _string(j['id'], pattern: _reference),
        versionId: _string(j['versionId'], pattern: _sha),
        title: _string(j['title']),
      );
}

class ActivityDetail {
  final ActivitySessionSnapshot snapshot;
  final String title;
  final List<ActivityMovementLabel> movementLabels;
  final bool practiceAvailable;
  ActivityDetail({
    required this.snapshot,
    required this.title,
    required List<ActivityMovementLabel> movementLabels,
    required this.practiceAvailable,
  }) : movementLabels = List.unmodifiable(movementLabels);
  factory ActivityDetail.fromJson(Map<String, dynamic> j) {
    final snapshot = ActivitySessionSnapshot.fromJson(
      activityObject(j['snapshot']),
    );
    final labels = _array(
      j['movementLabels'],
      100,
    ).map((v) => ActivityMovementLabel.fromJson(activityObject(v))).toList();
    final seen = <String>{};
    for (final label in labels) {
      if (!seen.add('${label.id}/${label.versionId}') ||
          !snapshot.items.any(
            (i) =>
                i.movementId == label.id &&
                i.movementVersion == label.versionId,
          )) {
        throw const FormatException('Unbound activity movement label');
      }
    }
    if (snapshot.items.any(
      (i) => !seen.contains('${i.movementId}/${i.movementVersion}'),
    )) {
      throw const FormatException('Missing activity movement label');
    }
    return ActivityDetail(
      snapshot: snapshot,
      title: _string(j['title']),
      movementLabels: labels,
      practiceAvailable: _flag(j['practiceAvailable']),
    );
  }
  String? titleFor(ActivityItem item) {
    for (final label in movementLabels) {
      if (label.id == item.movementId &&
          label.versionId == item.movementVersion) {
        return label.title;
      }
    }
    return null;
  }
}

class ActivityFeed {
  final List<ActivityOccurrence> upcoming;
  final List<ActivityDetail> sessions;
  final bool complete;
  ActivityFeed({
    required List<ActivityOccurrence> upcoming,
    required List<ActivityDetail> sessions,
    required this.complete,
  }) : upcoming = List.unmodifiable(upcoming),
       sessions = List.unmodifiable(sessions);
  factory ActivityFeed.fromJson(Map<String, dynamic> j) {
    final upcoming = _array(
      j['upcoming'],
      32,
    ).map((v) => ActivityOccurrence.fromJson(activityObject(v))).toList();
    final sessions = _array(
      j['sessions'],
      32,
    ).map((v) => ActivityDetail.fromJson(activityObject(v))).toList();
    if (upcoming.map((v) => v.id).toSet().length != upcoming.length ||
        sessions.map((v) => v.snapshot.id).toSet().length != sessions.length ||
        sessions.map((v) => v.snapshot.occurrenceId).toSet().length !=
            sessions.length ||
        upcoming.any(
          (o) => sessions.any((s) => s.snapshot.occurrenceId == o.id),
        )) {
      throw const FormatException('Duplicate activity feed identity');
    }
    return ActivityFeed(
      upcoming: upcoming,
      sessions: sessions,
      complete: _flag(j['complete']),
    );
  }
}

class ActivityMutation {
  final ActivityDetail detail;
  final int appliedRevision;
  final bool replayed;
  const ActivityMutation({
    required this.detail,
    required this.appliedRevision,
    required this.replayed,
  });
  factory ActivityMutation.fromJson(Map<String, dynamic> j) {
    final detail = ActivityDetail.fromJson(j);
    final applied = j['appliedRevision'];
    final replayed = _flag(j['replayed']);
    if (applied is! int ||
        applied < 1 ||
        applied > detail.snapshot.revision ||
        (!replayed && applied != detail.snapshot.revision)) {
      throw const FormatException('Invalid activity mutation revision');
    }
    return ActivityMutation(
      detail: detail,
      appliedRevision: applied,
      replayed: replayed,
    );
  }
}

abstract interface class ActivityRepository {
  Future<ActivityFeed> load();
  Future<ActivityDetail> detail(String id);
  Future<ActivityDetail> start(String occurrenceId, String key);
  Future<ActivityMutation> command(
    String sessionId, {
    required int expectedRevision,
    required String action,
    required bool confirmed,
    Map<String, dynamic>? set,
    required String key,
  });
}

String newActivityCommandKey() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final h = bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}
