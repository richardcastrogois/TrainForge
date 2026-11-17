import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/activity/domain/activity_repository.dart';
import 'package:trainforge/features/activity/domain/activity_session.dart';
import 'package:trainforge/features/activity/presentation/activity_controller.dart';

// Synthetic contract data, never imported into production composition or a DB.
String activityId(int n) =>
    '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';
String activitySha(String c) => List.filled(64, c).join();
const activityTitle = 'Synthetic permitted session';
const activityMovementTitle = 'Synthetic movement';
ActivityDetail activityFixture({
  String state = 'started',
  int revision = 1,
  int recorded = 0,
  int minute = 0,
  String mode = 'repetitions',
  bool available = true,
  String? owner,
  int actual = 7,
  String? loadKg,
}) {
  final start = DateTime.utc(2026, 11, 16, 10);
  final last = start.add(Duration(minutes: minute));
  final closed = !{'started', 'paused'}.contains(state);
  final snapshot = ActivitySessionSnapshot.fromJson({
    'contract': activitySessionContract,
    'id': activityId(1),
    'ownerId': owner ?? activityId(2),
    'occurrenceId': activityId(3),
    'source': {
      'programId': 'test:program:only',
      'programVersion': activitySha('a'),
      'sessionKey': 'test:session',
    },
    'state': state,
    'revision': revision,
    'startedAt': start.toIso8601String(),
    'lastEventAt': last.toIso8601String(),
    'endedAt': closed ? last.toIso8601String() : null,
    'activeMilliseconds': minute * 60000,
    'items': [
      {
        'position': 0,
        'movementId': 'test:movement:only',
        'movementVersion': activitySha('b'),
        'mode': mode,
        'targets': [
          for (var i = 0; i < 2; i++)
            {
              'repetitions': mode == 'repetitions' ? 10 : null,
              'durationMilliseconds': mode == 'duration' ? 30000 : null,
            },
        ],
      },
    ],
    'sets': [
      for (var i = 0; i < recorded; i++)
        {
          'commandId': activityId(10 + i),
          'recordedAt': start.toIso8601String(),
          'set': {
            'position': 0,
            'number': i + 1,
            'repetitions': mode == 'repetitions' ? actual : null,
            'durationMilliseconds': mode == 'duration' ? actual : null,
            'loadKg': loadKg,
          },
        },
    ],
    'pauses': [
      if (state == 'paused')
        {'startedAt': last.toIso8601String(), 'endedAt': null},
    ],
  });
  return ActivityDetail(
    snapshot: snapshot,
    title: activityTitle,
    movementLabels: [
      ActivityMovementLabel(
        id: 'test:movement:only',
        versionId: activitySha('b'),
        title: activityMovementTitle,
      ),
    ],
    practiceAvailable: available,
  );
}

ActivityOccurrence activityOccurrence({bool available = true}) =>
    ActivityOccurrence(
      id: activityId(3),
      plannedFor: DateTime.utc(2026, 11, 16, 10),
      timezone: 'America/Sao_Paulo',
      programId: 'test:program:only',
      programVersion: activitySha('a'),
      sessionKey: 'test:session',
      title: activityTitle,
      practiceAvailable: available,
    );

class ActivityFake implements ActivityRepository {
  ActivityDetail value = activityFixture();
  ActivityFeed feed = ActivityFeed(upcoming: [], sessions: [], complete: true);
  Future<ActivityFeed> Function()? onLoad;
  Future<ActivityDetail> Function(String id)? onDetail;
  Future<ActivityDetail> Function(String occurrenceId, String key)? onStart;
  Future<ActivityMutation> Function(Map<String, dynamic> call)? onCommand;
  int loads = 0, reads = 0;
  final starts = <List<String>>[];
  final commands = <Map<String, dynamic>>[];
  @override
  Future<ActivityFeed> load() async {
    loads++;
    return onLoad == null ? feed : onLoad!();
  }

  @override
  Future<ActivityDetail> detail(String id) async {
    reads++;
    return onDetail == null ? value : onDetail!(id);
  }

  @override
  Future<ActivityDetail> start(String occurrenceId, String key) async {
    starts.add([occurrenceId, key]);
    return onStart == null ? value : onStart!(occurrenceId, key);
  }

  @override
  Future<ActivityMutation> command(
    String sessionId, {
    required int expectedRevision,
    required String action,
    required bool confirmed,
    Map<String, dynamic>? set,
    required String key,
  }) async {
    final call = <String, dynamic>{
      'id': sessionId,
      'revision': expectedRevision,
      'action': action,
      'confirmed': confirmed,
      'set': set == null ? null : Map<String, dynamic>.of(set),
      'key': key,
    };
    commands.add(call);
    return onCommand == null
        ? ActivityMutation(
            detail: value,
            appliedRevision: expectedRevision + 1,
            replayed: false,
          )
        : onCommand!(call);
  }
}

void main() {
  late ActivityFake api;
  late ActivityController controller;
  late String? owner;
  var keys = 0;
  setUp(() {
    owner = activityId(2);
    keys = 0;
    api = ActivityFake();
    controller = ActivityController(
      repository: api,
      accountId: owner!,
      currentAccountId: () => owner,
      commandKey: () => activityId(100 + keys++),
    );
  });
  tearDown(() => controller.dispose());

  test('empty read does not create an occurrence or a session', () async {
    await controller.load();
    expect(controller.feed!.upcoming, isEmpty);
    expect(controller.feed!.sessions, isEmpty);
    expect(api.starts, isEmpty);
    expect(api.commands, isEmpty);
  });

  test('late feed and detail never enter a changed account', () async {
    final pending = Completer<ActivityFeed>();
    api.onLoad = () => pending.future;
    final request = controller.load();
    owner = activityId(200);
    controller.accountChanged();
    pending.complete(
      ActivityFeed(upcoming: [], sessions: [activityFixture()], complete: true),
    );
    await request;
    expect(controller.active, isFalse);
    expect(controller.feed, isNull);
    expect(controller.selected, isNull);
    owner = activityId(2);
    await controller.open(activityId(1));
    expect(
      api.reads,
      0,
    ); // returning to the old id cannot revive this controller
  });

  test('a read of another owner is rejected without exposing it', () async {
    api.value = activityFixture(owner: activityId(55));
    await controller.open(activityId(1));
    expect(controller.selected, isNull);
    expect(controller.feedback, ActivityFeedback.readFailed);
  });

  test('back invalidates an outstanding detail response', () async {
    final pending = Completer<ActivityDetail>();
    api.onDetail = (_) => pending.future;
    final request = controller.open(activityId(1));
    expect(controller.backToFeed(), isTrue);
    pending.complete(activityFixture());
    await request;
    expect(controller.selected, isNull);
    expect(controller.detailLoading, isFalse);
  });

  test(
    'record response is not optimistic; retry keeps key and decimal body',
    () async {
      await controller.open(activityId(1));
      api.onCommand = (_) async =>
          throw const ActivityFailure('activity_unavailable', uncertain: true);
      await controller.recordSet(
        position: 0,
        number: 1,
        measurement: '7',
        loadKg: '12,375',
      );
      expect(controller.selected!.snapshot.sets, isEmpty);
      expect(controller.uncertain, isTrue);
      expect(controller.canRecord, isFalse);
      expect(controller.backToFeed(), isFalse);
      await controller.command('cancel');
      expect(api.commands, hasLength(1));
      api.onCommand = (_) async => ActivityMutation(
        detail: activityFixture(revision: 2, recorded: 1, loadKg: '12.375'),
        appliedRevision: 2,
        replayed: true,
      );
      await controller.retry();
      expect(api.commands, hasLength(2));
      expect(api.commands[0], api.commands[1]);
      expect(api.commands.singleOrNull, isNull);
      expect(api.commands.first['set'], {
        'position': 0,
        'number': 1,
        'repetitions': 7,
        'durationMilliseconds': null,
        'loadKg': '12.375',
      });
      expect(api.commands.first['confirmed'], isFalse);
      expect(controller.selected!.snapshot.sets.single.actual.repetitions, 7);
      expect(controller.uncertain, isFalse);
      expect(controller.feedback, ActivityFeedback.confirmed);
    },
  );

  test(
    'seconds are converted exactly to milliseconds without a float',
    () async {
      api.value = activityFixture(mode: 'duration');
      await controller.open(activityId(1));
      api.onCommand = (_) async => ActivityMutation(
        detail: activityFixture(
          mode: 'duration',
          revision: 2,
          recorded: 1,
          actual: 12345,
        ),
        appliedRevision: 2,
        replayed: false,
      );
      await controller.recordSet(position: 0, number: 1, measurement: '12,345');
      expect(
        (api.commands.single['set'] as Map)['durationMilliseconds'],
        12345,
      );
      expect((api.commands.single['set'] as Map)['repetitions'], isNull);
    },
  );

  test('invalid values and a recorded slot never create commands', () async {
    api.value = activityFixture(revision: 2, recorded: 1);
    await controller.open(activityId(1));
    for (final input in ['10.5', '-1', '10001', '', '1e3']) {
      await controller.recordSet(position: 0, number: 2, measurement: input);
      expect(controller.feedback, ActivityFeedback.invalidSet);
    }
    await controller.recordSet(position: 0, number: 1, measurement: '10');
    await controller.recordSet(
      position: 0,
      number: 2,
      measurement: '10',
      loadKg: '1.0001',
    );
    expect(api.commands, isEmpty);
  });

  test(
    'a conflict cannot be retried until the latest state is checked',
    () async {
      await controller.open(activityId(1));
      api.onCommand = (_) async =>
          throw const ActivityFailure('activity_conflict', status: 409);
      await controller.command('pause');
      expect(controller.needsReconciliation, isTrue);
      await controller.retry();
      expect(api.commands, hasLength(1));
      api.value = activityFixture(state: 'paused', revision: 2, minute: 1);
      await controller.checkSession();
      expect(api.commands, hasLength(1));
      expect(controller.selected!.snapshot.state, ActivityState.paused);
      expect(controller.uncertain, isFalse);
      expect(controller.canResume, isTrue);
    },
  );

  test(
    'unknown exceptions freeze the intention rather than allow a new key',
    () async {
      await controller.open(activityId(1));
      api.onCommand = (_) async =>
          throw const FormatException('unreadable response');
      await controller.command('pause');
      expect(controller.feedback, ActivityFeedback.uncertain);
      expect(controller.uncertain, isTrue);
      await controller.command('pause');
      expect(api.commands, hasLength(1));
    },
  );

  test(
    'known rejection permits a revised value with a fresh intention',
    () async {
      await controller.open(activityId(1));
      api.onCommand = (_) async =>
          throw const ActivityFailure('invalid_activity_request', status: 400);
      await controller.recordSet(position: 0, number: 1, measurement: '3');
      expect(controller.uncertain, isFalse);
      await controller.recordSet(position: 0, number: 1, measurement: '4');
      expect(api.commands, hasLength(2));
      expect(api.commands[0]['key'], isNot(api.commands[1]['key']));
    },
  );

  test('the retry window expires without submitting a new command', () async {
    controller.dispose();
    controller = ActivityController(
      repository: api,
      accountId: owner!,
      currentAccountId: () => owner,
      retryWindow: Duration.zero,
    );
    await controller.open(activityId(1));
    api.onCommand = (_) async =>
        throw const ActivityFailure('network', uncertain: true);
    await controller.command('pause');
    expect(api.commands.single['confirmed'], isFalse);
    await controller.retry();
    expect(api.commands, hasLength(1));
    expect(controller.feedback, ActivityFeedback.retryExpired);
    expect(controller.needsReconciliation, isTrue);
  });

  test(
    'unknown start is not cleared when a partial feed does not contain it',
    () async {
      api.onStart = (_, _) async =>
          throw const ActivityFailure('network', uncertain: true);
      await controller.start(activityOccurrence());
      api.feed = ActivityFeed(upcoming: [], sessions: [], complete: false);
      await controller.checkSession();
      expect(controller.uncertain, isTrue);
      expect(api.starts, hasLength(1));
      api.feed = ActivityFeed(
        upcoming: [],
        sessions: [activityFixture()],
        complete: true,
      );
      await controller.checkSession();
      expect(controller.selected!.snapshot.id, activityId(1));
      expect(controller.uncertain, isFalse);
      expect(api.starts, hasLength(1));
    },
  );

  test('a stale detail cannot unlock an uncertain command', () async {
    api.value = activityFixture(revision: 3, recorded: 1);
    await controller.open(activityId(1));
    api.onCommand = (_) async =>
        throw const ActivityFailure('network', uncertain: true);
    await controller.recordSet(position: 0, number: 2, measurement: '7');
    api.value = activityFixture(revision: 1);
    await controller.checkSession();
    expect(controller.selected!.snapshot.revision, 3);
    expect(controller.uncertain, isTrue);
    expect(controller.feedback, ActivityFeedback.readFailed);
    expect(api.commands, hasLength(1));
  });

  test(
    'a replay accepts the current descendant while preserving the applied revision',
    () async {
      await controller.open(activityId(1));
      api.onCommand = (_) async => ActivityMutation(
        detail: activityFixture(state: 'completed', recorded: 2, revision: 4),
        appliedRevision: 2,
        replayed: true,
      );
      await controller.recordSet(position: 0, number: 1, measurement: '7');
      expect(controller.selected!.snapshot.revision, 4);
      expect(controller.selected!.snapshot.state, ActivityState.completed);
      expect(controller.feedback, ActivityFeedback.confirmed);
      expect(controller.canRecord, isFalse);
    },
  );

  test(
    'withdrawn practice can be paused or closed but not resumed or recorded',
    () async {
      api.value = activityFixture(available: false);
      await controller.open(activityId(1));
      expect(controller.canPause, isTrue);
      expect(controller.canEnd, isTrue);
      expect(controller.canRecord, isFalse);
      await controller.recordSet(position: 0, number: 1, measurement: '7');
      expect(api.commands, isEmpty);
      await controller.start(activityOccurrence(available: false));
      expect(api.starts, isEmpty);
    },
  );

  test(
    'all confirmed sets may be completed after practice becomes unavailable',
    () async {
      api.value = activityFixture(available: false, recorded: 2, revision: 3);
      await controller.open(activityId(1));
      expect(controller.canComplete, isTrue);
      api.onCommand = (_) async => ActivityMutation(
        detail: activityFixture(
          available: false,
          recorded: 2,
          state: 'completed',
          revision: 4,
        ),
        appliedRevision: 4,
        replayed: false,
      );
      await controller.command('complete');
      expect(api.commands.single['confirmed'], isTrue);
      expect(controller.selected!.snapshot.state, ActivityState.completed);
      expect(
        api.loads,
        1,
      ); // closing refreshes the real feed, no invented occurrence
    },
  );

  test(
    'a late write after account change cannot restore private data',
    () async {
      await controller.open(activityId(1));
      final pending = Completer<ActivityMutation>();
      api.onCommand = (_) => pending.future;
      final request = controller.command('pause');
      owner = activityId(88);
      controller.accountChanged();
      pending.complete(
        ActivityMutation(
          detail: activityFixture(state: 'paused', revision: 2),
          appliedRevision: 2,
          replayed: false,
        ),
      );
      await request;
      expect(controller.selected, isNull);
      expect(controller.feed, isNull);
      expect(controller.uncertain, isFalse);
    },
  );
}
