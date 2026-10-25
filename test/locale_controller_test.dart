import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/l10n/locale_controller.dart';

class MemoryLocaleStore implements LocaleStore {
  String? value;
  Object? readError, writeError;
  Completer<void>? pendingWrite;
  int reads = 0, writes = 0;
  MemoryLocaleStore([this.value]);
  @override
  Future<String?> read() async {
    reads++;
    if (readError != null) throw readError!;
    return value;
  }

  @override
  Future<void> write(String tag) async {
    writes++;
    if (writeError != null) throw writeError!;
    if (pendingWrite != null) await pendingWrite!.future;
    value = tag;
  }
}

void main() {
  test('locale negotiation respects region and device preference order', () {
    Locale resolve(List<Locale> locales) =>
        resolveAppLocale(locales, supportedAppLocales);
    expect(resolve([const Locale('pt', 'PT')]), const Locale('pt', 'PT'));
    expect(resolve([const Locale('pt', 'MZ')]), const Locale('pt', 'BR'));
    expect(resolve([const Locale('en', 'GB')]), const Locale('en'));
    expect(resolve([const Locale('es', 'MX')]), const Locale('es'));
    expect(
      resolve([const Locale('fr'), const Locale('es')]),
      const Locale('es'),
    );
    expect(resolve([const Locale('fr')]), const Locale('pt', 'BR'));
    expect(resolve([]), const Locale('pt', 'BR'));
  });

  test('locale preference restores once and persists for reopening', () async {
    final store = MemoryLocaleStore('pt-PT');
    final c = LocaleController(store: store);
    addTearDown(c.dispose);
    await Future.wait([c.restore(), c.restore()]);
    expect(store.reads, 1);
    expect(c.choice, LanguageChoice.portuguesePortugal);
    await c.select(LanguageChoice.spanish);
    final reopened = LocaleController(store: store);
    addTearDown(reopened.dispose);
    await reopened.restore();
    expect(reopened.choice, LanguageChoice.spanish);
    await reopened.select(LanguageChoice.system);
    expect(store.value, 'system');
  });

  test(
    'invalid or unreadable preference falls back without exposing storage errors',
    () async {
      for (final fail in [false, true]) {
        final store = MemoryLocaleStore('invalid-private-value');
        if (fail) store.readError = StateError('private storage details');
        final c = LocaleController(store: store);
        await c.restore();
        expect(c.loaded, true);
        expect(c.choice, LanguageChoice.system);
        expect(c.issue, LocaleIssue.readFallback);
        c.dispose();
      }
    },
  );

  test(
    'failed save retains the previous language and blocks concurrent writes',
    () async {
      final store = MemoryLocaleStore('en');
      final c = LocaleController(store: store);
      addTearDown(c.dispose);
      await c.restore();
      store.writeError = StateError('private');
      await c.select(LanguageChoice.spanish);
      expect(c.choice, LanguageChoice.english);
      expect(c.issue, LocaleIssue.saveFailed);
      store.writeError = null;
      store.pendingWrite = Completer<void>();
      final pending = c.select(LanguageChoice.spanish);
      await c.select(LanguageChoice.portugueseBrazil);
      expect(store.writes, 2);
      store.pendingWrite!.complete();
      await pending;
      expect(store.value, 'es');
    },
  );

  test(
    'uncertain save retains applied language and late completion does not notify after disposal',
    () async {
      final store = MemoryLocaleStore('pt-BR')
        ..pendingWrite = Completer<void>();
      final c = LocaleController(
        store: store,
        timeout: const Duration(milliseconds: 10),
      );
      await c.restore();
      await c.select(LanguageChoice.english);
      expect(c.choice, LanguageChoice.english);
      expect(c.issue, LocaleIssue.saveUncertain);
      var notifications = 0;
      c.addListener(() => notifications++);
      c.dispose();
      store.pendingWrite!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(notifications, 0);
    },
  );
}
