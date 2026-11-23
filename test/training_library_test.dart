import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/training_library/data/training_library.dart';
import 'package:trainforge/features/training_library/presentation/training_library_page.dart';

void main() {
  final text = File(TrainingLibrary.asset).readAsStringSync();

  test(
    'bundled library has the 122 ready sessions, each with exercises and a source',
    () {
      final lib = TrainingLibrary.parse(text);
      expect(lib.sessions, hasLength(122));
      expect(lib.places.map((p) => p.id), [
        'casa',
        'praca',
        'academia',
        'pausa',
      ]);
      final cells = {for (final p in lib.places) ...p.cells.map((c) => c.id)};
      expect(cells, hasLength(12));
      for (final s in lib.sessions) {
        expect(s.exercises, isNotEmpty, reason: s.id);
        expect(s.source.name.trim(), isNotEmpty, reason: s.id);
        expect(s.cells.every(cells.contains), isTrue, reason: s.id);
      }
      // Every place and level offers sessions (research goal: 9 per cell).
      for (final c in cells) {
        expect(lib.forCell(c).length, greaterThanOrEqualTo(9), reason: c);
      }
    },
  );

  testWidgets(
    'choose place and level, then open a session with safety and source',
    (t) async {
      t.view.physicalSize = const Size(800, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(home: TrainingLibraryPage(read: () async => text)),
      );
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pumpAndSettle();
      expect(find.text('Where will you train?'), findsOneWidget);
      await t.tap(find.text('Academia'));
      await t.pumpAndSettle();
      await t.tap(find.text('Iniciante'));
      await t.pumpAndSettle();
      final lib = TrainingLibrary.parse(text);
      final first = lib.forCell('academia-iniciante').first;
      await t.tap(find.text(first.name));
      await t.pumpAndSettle();
      expect(find.byType(TrainingSessionPage), findsOneWidget);
      expect(find.textContaining('Stop if you feel pain'), findsOneWidget);
      expect(find.text(first.exercises.first.name), findsOneWidget);
      await t.scrollUntilVisible(find.text('Source'), 200);
      expect(find.textContaining(first.source.name), findsWidgets);
    },
  );

  test('an unknown library contract is refused', () {
    expect(
      () => TrainingLibrary.parse('{"contract":"other"}'),
      throwsFormatException,
    );
  });
}
