import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/activity/domain/activity_session.dart';

// Disposable contract fixtures. Never composed into the production app.
String id(int n) => '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';
String sha(String c) => List.filled(64, c).join();
Map<String, dynamic> initial() => {
  'contract': activitySessionContract,
  'id': id(1),
  'ownerId': id(2),
  'occurrenceId': id(3),
  'source': {
    'programId': 'test:program:fixture',
    'programVersion': sha('a'),
    'sessionKey': 'fixture-session',
  },
  'state': 'started',
  'revision': 2,
  'startedAt': '2026-11-16T10:00:00Z',
  'lastEventAt': '2026-11-16T10:02:00Z',
  'endedAt': null,
  'activeMilliseconds': 120000,
  'items': [
    {
      'position': 0,
      'movementId': 'test:movement:fixture',
      'movementVersion': sha('b'),
      'mode': 'repetitions',
      'targets': [
        {'repetitions': 10, 'durationMilliseconds': null},
        {'repetitions': 10, 'durationMilliseconds': null},
      ],
    },
  ],
  'sets': [
    {
      'commandId': id(10),
      'recordedAt': '2026-11-16T10:02:00Z',
      'set': <String, dynamic>{
        'position': 0,
        'number': 1,
        'repetitions': 7,
        'durationMilliseconds': null,
        'loadKg': null,
      },
    },
  ],
  'pauses': <dynamic>[],
};
Map<String, dynamic> paused() => initial()
  ..['state'] = 'paused'
  ..['revision'] = 3
  ..['lastEventAt'] = '2026-11-16T10:03:00Z'
  ..['activeMilliseconds'] = 180000
  ..['pauses'] = [
    {'startedAt': '2026-11-16T10:03:00Z', 'endedAt': null},
  ];
Map<String, dynamic> partial() => paused()
  ..['state'] = 'partial'
  ..['revision'] = 5
  ..['lastEventAt'] = '2026-11-16T10:10:00Z'
  ..['endedAt'] = '2026-11-16T10:10:00Z'
  ..['activeMilliseconds'] = 420000
  ..['pauses'] = [
    <String, dynamic>{
      'startedAt': '2026-11-16T10:03:00Z',
      'endedAt': '2026-11-16T10:06:00Z',
    },
  ];
ActivitySessionSnapshot read(Map<String, dynamic> value) =>
    ActivitySessionSnapshot.fromJson(
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>,
    );

void main() {
  test('prescription and actual result stay separate and immutable', () {
    final input = initial();
    final s = ActivitySessionSnapshot.fromJson(input);
    expect(s.items.single.targets.first.repetitions, 10);
    expect(s.sets.single.actual.repetitions, 7);
    expect(s.sets.single.loadKg, isNull);
    expect(s.canComplete, isFalse);
    expect(s.canPause, isTrue);
    input['items'][0]['targets'][0]['repetitions'] = 99;
    expect(s.items.single.targets.first.repetitions, 10);
    expect(() => s.sets.clear(), throwsUnsupportedError);
    expect(() => s.items.single.targets.clear(), throwsUnsupportedError);
  });

  test(
    'paused duration and closed partial timeline preserve original start',
    () {
      final p = read(paused()), ended = read(partial());
      expect(p.canResume, isTrue);
      expect(
        p.elapsedAt(DateTime.utc(2026, 11, 17)),
        const Duration(minutes: 3),
      );
      expect(ended.startedAt, DateTime.utc(2026, 11, 16, 10));
      expect(
        ended.elapsedAt(DateTime.utc(2026, 11, 17)),
        const Duration(minutes: 7),
      );
      expect(ended.isOpen, isFalse);
      expect(ended.canComplete, isFalse);
      final s = read(initial());
      expect(
        s.elapsedAt(DateTime.utc(2026, 11, 16, 10, 4)),
        const Duration(minutes: 4),
      );
      expect(
        s.elapsedAt(DateTime.utc(2026, 11, 16, 9)),
        const Duration(minutes: 2),
      );
      expect(s.state, ActivityState.started); // Time never ends a session.
    },
  );

  test('an explicit failed attempt is zero while unknown remains invalid', () {
    final j = initial();
    j['sets'][0]['set']['repetitions'] = 0;
    expect(read(j).sets.single.actual.repetitions, 0);
    j['sets'][0]['set']['repetitions'] = null;
    expect(() => read(j), throwsFormatException);
  });

  final invalid = <String, void Function(Map<String, dynamic>)>{
    'unknown contract': (j) => j['contract'] = 'another-contract',
    'unknown state': (j) => j['state'] = 'finished-automatically',
    'missing owner': (j) => j['ownerId'] = null,
    'unversioned program': (j) => j['source']['programVersion'] = '',
    'no prescription': (j) => j['items'] = [],
    'unknown target': (j) => j['items'][0]['targets'][0]['repetitions'] = null,
    'zero target': (j) => j['items'][0]['targets'][0]['repetitions'] = 0,
    'unsupported mode': (j) => j['items'][0]['mode'] = 'distance',
    'duplicate slot': (j) => j['items'].add(j['items'][0]),
    'duplicate set': (j) => j['sets'].add(j['sets'][0]),
    'foreign slot': (j) => j['sets'][0]['set']['position'] = 50,
    'mixed actual units': (j) =>
        j['sets'][0]['set']['durationMilliseconds'] = 100,
    'load with exponent': (j) => j['sets'][0]['set']['loadKg'] = '1e3',
    'unrecorded complete': (j) {
      j['state'] = 'completed';
      j['endedAt'] = j['lastEventAt'];
    },
    'wrong active duration': (j) => j['activeMilliseconds'] = 1,
    'normalized impossible date': (j) =>
        j['startedAt'] = '2026-02-30T10:00:00Z',
    'time without offset': (j) => j['startedAt'] = '2026-11-16T10:00:00',
    'unclosed terminal pause': (j) {
      j.addAll(partial());
      j['pauses'][0]['endedAt'] = null;
    },
  };
  for (final entry in invalid.entries) {
    test('rejects ${entry.key}', () {
      final value = initial();
      entry.value(value);
      expect(() => read(value), throwsFormatException);
    });
  }

  test(
    'result distinguishes applied revision from current snapshot on retry',
    () {
      final result = ActivityCommandResult.fromJson({
        'snapshot': partial(),
        'appliedRevision': 2,
        'replayed': true,
      });
      expect(result.snapshot.revision, 5);
      expect(result.appliedRevision, 2);
      expect(result.replayed, isTrue);
      expect(
        () => ActivityCommandResult.fromJson({
          'snapshot': partial(),
          'appliedRevision': 2,
          'replayed': false,
        }),
        throwsFormatException,
      );
    },
  );

  test('late responses and duplicate retries never regress a projection', () {
    final p = ActivitySessionProjection(ownerId: id(2), sessionId: id(1));
    expect(p.accept(read(initial())), isTrue);
    expect(p.accept(read(paused())), isTrue);
    expect(p.accept(read(partial())), isTrue);
    expect(p.accept(read(initial())), isFalse);
    expect(p.accept(read(partial())), isFalse);
    expect(p.snapshot!.state, ActivityState.partial);
    final rewritten = partial()..['revision'] = 6;
    expect(() => p.accept(read(rewritten)), throwsFormatException);
  });

  test(
    'different account, changed prescription and replaced facts are rejected',
    () {
      final p = ActivitySessionProjection(ownerId: id(2), sessionId: id(1));
      p.accept(read(initial()));
      final other = paused()..['ownerId'] = id(99);
      expect(() => p.accept(read(other)), throwsFormatException);
      final prescription = paused();
      prescription['items'][0]['targets'][0]['repetitions'] = 8;
      expect(() => p.accept(read(prescription)), throwsFormatException);
      final rewritten = paused();
      rewritten['sets'][0]['set']['repetitions'] = 8;
      expect(() => p.accept(read(rewritten)), throwsFormatException);
      p.invalidate();
      expect(p.snapshot, isNull);
      expect(() => p.accept(read(paused())), throwsStateError);
    },
  );

  test(
    'rest uses its deadline after backgrounding, without starting a new timer',
    () {
      final end = DateTime.utc(2026, 11, 16, 10, 5);
      final rest = ActivityRestDeadline(end);
      expect(
        rest.remainingAt(end.subtract(const Duration(seconds: 20))),
        const Duration(seconds: 20),
      );
      expect(rest.remainingAt(end), Duration.zero);
      expect(
        rest.remainingAt(end.add(const Duration(hours: 1))),
        Duration.zero,
      );
    },
  );
}
