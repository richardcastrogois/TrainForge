import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/activity/data/activity_repository.dart';
import 'package:trainforge/features/activity/domain/activity_repository.dart';
import 'activity_session_test.dart' show initial, paused, id, sha;

class ActivityAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) respond;
  ActivityAdapter(this.respond);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody response(Object? json, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(json),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
Map<String, dynamic> detailJson({Map<String, dynamic>? snapshot}) => {
  'snapshot': snapshot ?? initial(),
  'title': 'Test fixture',
  'movementLabels': [
    {
      'id': 'test:movement:fixture',
      'versionId': sha('b'),
      'title': 'Disposable movement',
    },
  ],
  'practiceAvailable': true,
};
Map<String, dynamic> mutationJson({
  Map<String, dynamic>? snapshot,
  int applied = 2,
  bool replayed = false,
}) => {
  ...detailJson(snapshot: snapshot),
  'appliedRevision': applied,
  'replayed': replayed,
};
Map<String, dynamic> actual() => {
  'position': 0,
  'number': 1,
  'repetitions': 7,
  'durationMilliseconds': null,
  'loadKg': null,
};
GoActivityRepository repository(
  Future<ResponseBody> Function(RequestOptions) respond, {
  String? Function()? owner,
}) => GoActivityRepository(
  accountId: id(2),
  currentAccountId: owner ?? () => id(2),
  dio: Dio(BaseOptions(baseUrl: 'http://fixture.invalid'))
    ..httpClientAdapter = ActivityAdapter(respond),
);
Future<ActivityMutation> record(GoActivityRepository repo) => repo.command(
  id(1),
  expectedRevision: 1,
  action: 'record_set',
  confirmed: false,
  set: actual(),
  key: id(10),
);

void main() {
  test('empty real feed remains empty, with explicit completeness', () async {
    final feed = await repository((request) async {
      expect(request.method, 'GET');
      expect(request.path, '/api/v1/me/activity');
      expect(request.headers['X-TrainForge-Account'], id(2));
      return response({'upcoming': [], 'sessions': [], 'complete': true});
    }).load();
    expect(feed.upcoming, isEmpty);
    expect(feed.sessions, isEmpty);
    expect(feed.complete, true);
    expect(() => feed.sessions.clear(), throwsUnsupportedError);
  });

  test('mutations transmit exact intent, revision and stable UUID', () async {
    final requests = <RequestOptions>[];
    final repo = repository((request) async {
      requests.add(request);
      return response(mutationJson(replayed: requests.length == 2));
    });
    expect((await record(repo)).replayed, false);
    expect((await record(repo)).replayed, true);
    for (final request in requests) {
      expect(request.method, 'POST');
      expect(request.headers['Idempotency-Key'], id(10));
      expect(request.headers['X-TrainForge-Account'], id(2));
      expect(request.data, {
        'expectedRevision': 1,
        'action': 'record_set',
        'confirmed': false,
        'set': actual(),
      });
      expect(request.path, '/api/v1/me/activity-sessions/${id(1)}/commands');
    }
  });

  test(
    'start replay accepts current state and original applied revision',
    () async {
      final repo = repository((request) async {
        expect(request.data, {'occurrenceId': id(3)});
        return response(
          mutationJson(snapshot: paused(), applied: 1, replayed: true),
        );
      });
      final result = await repo.start(id(3), id(90));
      expect(result.snapshot.revision, 3);
      expect(result.snapshot.canResume, true);
    },
  );

  test('record replay may return a later current state', () async {
    final result = await record(
      repository(
        (_) async => response(mutationJson(snapshot: paused(), replayed: true)),
      ),
    );
    expect(result.appliedRevision, 2);
    expect(result.detail.snapshot.revision, 3);
  });

  for (final field in [
    'position',
    'number',
    'repetitions',
    'durationMilliseconds',
    'loadKg',
  ]) {
    test('different acknowledged $field leaves mutation uncertain', () async {
      final body = actual();
      body[field] = switch (field) {
        'loadKg' => '0',
        'durationMilliseconds' => 1,
        _ => (body[field] as int) + 1,
      };
      final repo = repository((_) async => response(mutationJson()));
      await expectLater(
        repo.command(
          id(1),
          expectedRevision: 1,
          action: 'record_set',
          confirmed: false,
          set: body,
          key: id(10),
        ),
        throwsA(
          isA<ActivityFailure>().having((e) => e.uncertain, 'uncertain', true),
        ),
      );
    });
  }

  test('different account response cannot be accepted', () async {
    final other = initial()..['ownerId'] = id(99);
    final repo = repository((_) async => response(detailJson(snapshot: other)));
    await expectLater(repo.detail(id(1)), throwsA(isA<ActivityFailure>()));
  });

  test(
    'account switch rejects late response and next network request',
    () async {
      var account = id(2), calls = 0;
      final pending = Completer<ResponseBody>();
      final repo = repository((_) {
        calls++;
        return pending.future;
      }, owner: () => account);
      final future = repo.detail(id(1));
      await Future<void>.delayed(Duration.zero);
      account = id(99);
      pending.complete(response(detailJson()));
      await expectLater(
        future,
        throwsA(
          isA<ActivityFailure>().having(
            (e) => e.code,
            'code',
            'activity_account_changed',
          ),
        ),
      );
      await expectLater(repo.detail(id(1)), throwsA(isA<ActivityFailure>()));
      expect(calls, 1);
    },
  );

  for (final status in [401, 403, 409, 422, 500, 503]) {
    test(
      'HTTP $status preserves rejection versus uncertain mutation',
      () async {
        final repo = repository(
          (_) async => response({'code': 'fixture_error'}, status: status),
        );
        await expectLater(
          record(repo),
          throwsA(
            isA<ActivityFailure>()
                .having((e) => e.code, 'code', 'fixture_error')
                .having((e) => e.status, 'status', status)
                .having((e) => e.uncertain, 'uncertain', status >= 500),
          ),
        );
      },
    );
  }

  test('transport failure after a POST is uncertain', () async {
    final repo = repository(
      (request) async => throw DioException(
        requestOptions: request,
        type: DioExceptionType.receiveTimeout,
      ),
    );
    await expectLater(
      record(repo),
      throwsA(
        isA<ActivityFailure>().having((e) => e.uncertain, 'uncertain', true),
      ),
    );
  });

  test('labels must cover exactly the prescribed movement versions', () {
    expect(
      () => ActivityDetail.fromJson(detailJson()..['movementLabels'] = []),
      throwsFormatException,
    );
    final bad = detailJson();
    bad['movementLabels'][0]['versionId'] = sha('c');
    expect(() => ActivityDetail.fromJson(bad), throwsFormatException);
  });

  test('malformed 2xx mutation cannot silently acknowledge a write', () async {
    final repo = repository((_) async => response({'replayed': false}));
    await expectLater(
      record(repo),
      throwsA(
        isA<ActivityFailure>().having((e) => e.uncertain, 'uncertain', true),
      ),
    );
  });

  test(
    'feed completeness is mandatory and occurrence cannot be duplicated',
    () {
      expect(
        () => ActivityFeed.fromJson({'upcoming': [], 'sessions': []}),
        throwsFormatException,
      );
      final repeated = initial()..['id'] = id(12);
      expect(
        () => ActivityFeed.fromJson({
          'upcoming': [],
          'sessions': [detailJson(), detailJson(snapshot: repeated)],
          'complete': true,
        }),
        throwsFormatException,
      );
    },
  );
}
