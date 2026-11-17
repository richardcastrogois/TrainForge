import 'package:dio/dio.dart';
import 'package:trainforge/core/http/app_dio.dart';
import '../domain/activity_repository.dart';

class GoActivityRepository implements ActivityRepository {
  final String accountId;
  final String? Function() currentAccountId;
  final Dio dio;
  GoActivityRepository({
    required this.accountId,
    required this.currentAccountId,
    Dio? dio,
  }) : dio = dio ?? AppDio.instance;

  void _check() {
    if (currentAccountId() != accountId) {
      throw const ActivityFailure('activity_account_changed');
    }
  }

  Future<T> _request<T>(
    String method,
    String path,
    T Function(Map<String, dynamic>) decode, {
    Map<String, dynamic>? body,
    String? key,
  }) async {
    _check();
    final mutation = method == 'POST';
    try {
      final response = await dio.request<dynamic>(
        path,
        data: body,
        options: Options(
          method: method,
          headers: {'X-TrainForge-Account': accountId, 'Idempotency-Key': ?key},
        ),
      );
      _check();
      return decode(activityObject(response.data));
    } on DioException catch (e) {
      _check();
      final data = e.response?.data;
      final j = data is Map ? data : const {};
      final code = j['code'];
      final status = e.response?.statusCode;
      throw ActivityFailure(
        code is String ? code : 'activity_unavailable',
        status: status,
        uncertain:
            mutation && (status == null || status >= 500 || status == 408),
      );
    } on ActivityFailure {
      rethrow;
    } catch (_) {
      _check();
      throw ActivityFailure('activity_unavailable', uncertain: mutation);
    }
  }

  ActivityDetail _owned(ActivityDetail detail) {
    if (detail.snapshot.ownerId != accountId) {
      throw const FormatException('Activity owner mismatch');
    }
    return detail;
  }

  @override
  Future<ActivityFeed> load() => _request('GET', '/api/v1/me/activity', (j) {
    final feed = ActivityFeed.fromJson(j);
    for (final detail in feed.sessions) {
      _owned(detail);
    }
    return feed;
  });

  @override
  Future<ActivityDetail> detail(String id) => _request(
    'GET',
    '/api/v1/me/activity-sessions/${Uri.encodeComponent(id)}',
    (j) {
      final result = _owned(ActivityDetail.fromJson(j));
      if (result.snapshot.id != id) {
        throw const FormatException('Activity identity mismatch');
      }
      return result;
    },
  );

  @override
  Future<ActivityDetail> start(String occurrenceId, String key) => _request(
    'POST',
    '/api/v1/me/activity-sessions',
    (j) {
      final result = ActivityMutation.fromJson(j);
      final detail = _owned(result.detail);
      if (detail.snapshot.occurrenceId != occurrenceId ||
          result.appliedRevision != 1) {
        throw const FormatException('Activity start acknowledgement mismatch');
      }
      return detail;
    },
    body: {'occurrenceId': occurrenceId},
    key: key,
  );

  @override
  Future<ActivityMutation> command(
    String sessionId, {
    required int expectedRevision,
    required String action,
    required bool confirmed,
    Map<String, dynamic>? set,
    required String key,
  }) => _request(
    'POST',
    '/api/v1/me/activity-sessions/${Uri.encodeComponent(sessionId)}/commands',
    (j) {
      final result = ActivityMutation.fromJson(j);
      _owned(result.detail);
      final snapshot = result.detail.snapshot;
      final recorded = snapshot.sets.where((s) => s.commandId == key);
      final expectedState = switch (action) {
        'pause' => 'paused',
        'resume' => 'started',
        'partial' => 'partial',
        'complete' => 'completed',
        'cancel' => 'cancelled',
        _ => 'started',
      };
      if (result.detail.snapshot.id != sessionId ||
          result.appliedRevision != expectedRevision + 1 ||
          (!result.replayed && snapshot.state.name != expectedState) ||
          (action == 'record_set' &&
              (recorded.length != 1 ||
                  set == null ||
                  recorded.single.position != set['position'] ||
                  recorded.single.number != set['number'] ||
                  recorded.single.actual.repetitions != set['repetitions'] ||
                  recorded.single.actual.durationMilliseconds !=
                      set['durationMilliseconds'] ||
                  recorded.single.loadKg != set['loadKg']))) {
        throw const FormatException(
          'Activity command acknowledgement mismatch',
        );
      }
      return result;
    },
    body: {
      'expectedRevision': expectedRevision,
      'action': action,
      'confirmed': confirmed,
      'set': set,
    },
    key: key,
  );
}
