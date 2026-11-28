import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/activity/domain/activity_repository.dart';
import 'package:trainforge/features/activity/presentation/evolution_source.dart';

import 'activity_repository_test.dart' show detailJson;
import 'activity_session_test.dart' show initial, partial;

ActivityDetail session(Map<String, dynamic> snapshot) =>
    ActivityDetail.fromJson(
      jsonDecode(jsonEncode(detailJson(snapshot: snapshot)))
          as Map<String, dynamic>,
    );

void main() {
  // Fixtures start on 16/11/2026 at 10:00 UTC; noon keeps the local day.
  final now = DateTime(2026, 11, 18, 12);

  test('nothing recorded keeps the preview and the real zeros', () {
    final data = buildEvolution(sessions: const [], now: now);
    expect(data.dayScores, isNull);
    expect(data.streakDays, 0);
    expect(data.minutes, 0);
    expect(data.sets, 0);
    expect(data.kcal, isNull);
    expect(data.waterMl, isNull);
  });

  test('a day fills a third per workout, meal and water', () {
    final data = buildEvolution(
      sessions: [session(partial())],
      now: now,
      diary: {
        16: const DiaryDay(ate: true, waterMl: 500),
        17: const DiaryDay(ate: true),
        18: const DiaryDay(waterMl: 300),
      },
      kcal: 1450,
    );
    final day16 = DateTime.parse('2026-11-16T10:00:00Z').toLocal().day;
    expect(data.dayScores![day16], 1);
    expect(data.dayScores![17], closeTo(1 / 3, 1e-9));
    expect(data.dayScores![18], closeTo(1 / 3, 1e-9));
    expect(data.dayScores![1], 0);
    // 16, 17 and 18 in a row with something recorded.
    expect(data.streakDays, 3);
    expect(data.minutes, 7);
    expect(data.waterMl, 300);
    expect(data.kcal, 1450);
  });

  test('a workout still open counts time and sets but not the day', () {
    final data = buildEvolution(sessions: [session(initial())], now: now);
    expect(data.minutes, 2);
    expect(data.sets, initial()['sets'].length);
    expect(data.dayScores, isNull);
  });

  test('an empty today does not break the streak until tomorrow', () {
    final data = buildEvolution(
      sessions: const [],
      now: now,
      diary: {
        16: const DiaryDay(ate: true),
        17: const DiaryDay(ate: true),
        18: const DiaryDay(),
      },
    );
    expect(data.streakDays, 2);
    expect(data.waterMl, 0);
  });
}
