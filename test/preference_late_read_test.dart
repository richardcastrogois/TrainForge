import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/l10n/locale_controller.dart';
import 'package:trainforge/core/theme/appearance_controller.dart';

class DelayedLocale implements LocaleStore {
  final reads = <Completer<String?>>[];
  final writes = <String>[];
  @override
  Future<String?> read() {
    final r = Completer<String?>();
    reads.add(r);
    return r.future;
  }

  @override
  Future<void> write(String tag) async {
    writes.add(tag);
  }
}

class DelayedAppearance implements AppearanceStore {
  final reads = <Completer<String?>>[];
  final writes = <String>[];
  @override
  Future<String?> read() {
    final r = Completer<String?>();
    reads.add(r);
    return r.future;
  }

  @override
  Future<void> write(String mode) async {
    writes.add(mode);
  }
}

void main() {
  test(
    'late locale read repairs cold-start fallback without writing',
    () async {
      final store = DelayedLocale(),
          c = LocaleController(
            store: store,
            timeout: const Duration(milliseconds: 1),
          );
      addTearDown(c.dispose);
      await c.restore();
      expect(c.loaded, true);
      expect(c.readFailed, true);
      expect(c.choice, LanguageChoice.system);
      store.reads.single.complete('pt-BR');
      await Future<void>.delayed(Duration.zero);
      expect(c.choice, LanguageChoice.portugueseBrazil);
      expect(c.issue, isNull);
      expect(c.loaded, true);
      expect(store.writes, isEmpty);
    },
  );
  test('late locale read cannot undo a manual choice after fallback', () async {
    final store = DelayedLocale(),
        c = LocaleController(
          store: store,
          timeout: const Duration(milliseconds: 1),
        );
    addTearDown(c.dispose);
    await c.restore();
    await c.select(LanguageChoice.spanish);
    store.reads.single.complete('pt-BR');
    await Future<void>.delayed(Duration.zero);
    expect(c.choice, LanguageChoice.spanish);
    expect(store.writes, ['es']);
  });
  test(
    'old locale read cannot undo a newer retry or revive disposed state',
    () async {
      final store = DelayedLocale(),
          c = LocaleController(
            store: store,
            timeout: const Duration(milliseconds: 1),
          );
      await c.restore();
      final retry = c.retry();
      store.reads.last.complete('en');
      await retry;
      store.reads.first.complete('es');
      await Future<void>.delayed(Duration.zero);
      expect(c.choice, LanguageChoice.english);
      c.dispose();
      expect(store.writes, isEmpty);
      final otherStore = DelayedLocale(),
          disposed = LocaleController(
            store: otherStore,
            timeout: const Duration(milliseconds: 1),
          );
      await disposed.restore();
      var notices = 0;
      disposed.addListener(() => notices++);
      disposed.dispose();
      otherStore.reads.single.complete('pt-PT');
      await Future<void>.delayed(Duration.zero);
      expect(notices, 0);
    },
  );
  test(
    'late appearance read repairs fallback without saving a default',
    () async {
      final store = DelayedAppearance(),
          c = AppearanceController(
            store: store,
            restoreTimeout: const Duration(milliseconds: 1),
          );
      addTearDown(c.dispose);
      await c.restore();
      expect(c.readFailed, true);
      store.reads.single.complete('dark');
      await Future<void>.delayed(Duration.zero);
      expect(c.mode, ThemeMode.dark);
      expect(c.feedback, isNull);
      expect(c.loaded, true);
      expect(store.writes, isEmpty);
    },
  );
  test('late appearance read cannot undo manual choice or retry', () async {
    final store = DelayedAppearance(),
        c = AppearanceController(
          store: store,
          restoreTimeout: const Duration(milliseconds: 1),
        );
    addTearDown(c.dispose);
    await c.restore();
    await c.select(ThemeMode.light);
    store.reads.single.complete('dark');
    await Future<void>.delayed(Duration.zero);
    expect(c.mode, ThemeMode.light);
    expect(store.writes, ['light']);
    final retryStore = DelayedAppearance(),
        other = AppearanceController(
          store: retryStore,
          restoreTimeout: const Duration(milliseconds: 1),
        );
    addTearDown(other.dispose);
    await other.restore();
    final retry = other.retry();
    retryStore.reads.last.complete('dark');
    await retry;
    retryStore.reads.first.complete('light');
    await Future<void>.delayed(Duration.zero);
    expect(other.mode, ThemeMode.dark);
  });
  test(
    'late failure or invalid preference is not marked as restored',
    () async {
      final store = DelayedLocale(),
          c = LocaleController(
            store: store,
            timeout: const Duration(milliseconds: 1),
          );
      addTearDown(c.dispose);
      await c.restore();
      store.reads.single.complete('unknown');
      await Future<void>.delayed(Duration.zero);
      expect(c.readFailed, true);
      expect(store.writes, isEmpty);
      final appearance = DelayedAppearance(),
          a = AppearanceController(
            store: appearance,
            restoreTimeout: const Duration(milliseconds: 1),
          );
      addTearDown(a.dispose);
      await a.restore();
      appearance.reads.single.completeError(StateError('fixture-only'));
      await Future<void>.delayed(Duration.zero);
      expect(a.readFailed, true);
      expect(appearance.writes, isEmpty);
    },
  );
}
