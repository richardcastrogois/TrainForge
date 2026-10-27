import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/l10n/locale_controller.dart';
import 'package:trainforge/core/l10n/language_page.dart';
import 'package:trainforge/core/theme/appearance_controller.dart';
import 'package:trainforge/core/theme/appearance_page.dart';
import 'package:trainforge/l10n/generated/app_localizations.dart';
import 'locale_controller_test.dart' show MemoryLocaleStore;
import 'appearance_startup_motion_test.dart' show MemoryAppearance;

class DelayedLocaleRead extends MemoryLocaleStore {
  Completer<String?> pending = Completer<String?>();
  bool delayed = false;
  DelayedLocaleRead() : super('pt-PT');
  @override
  Future<String?> read() {
    if (!delayed) return super.read();
    reads++;
    return pending.future;
  }
}

void main() {
  test(
    'read retry restores stored language without writing fallback',
    () async {
      final store = MemoryLocaleStore('pt-PT')
        ..readError = StateError('private');
      final c = LocaleController(store: store);
      addTearDown(c.dispose);
      await c.restore();
      expect(c.readFailed, true);
      expect(c.choice, LanguageChoice.system);
      store.readError = null;
      await c.retry();
      expect(store.reads, 2);
      expect(store.writes, 0);
      expect(store.value, 'pt-PT');
      expect(c.choice, LanguageChoice.portuguesePortugal);
      expect(c.issue, isNull);
    },
  );
  test(
    'write retry sends requested language rather than restored previous choice',
    () async {
      final store = MemoryLocaleStore('pt-PT');
      final c = LocaleController(store: store);
      addTearDown(c.dispose);
      await c.restore();
      store.writeError = StateError('private');
      await c.select(LanguageChoice.spanish);
      expect(c.choice, LanguageChoice.portuguesePortugal);
      expect(c.issue, LocaleIssue.saveFailed);
      store.writeError = null;
      await c.retry();
      expect(store.writes, 2);
      expect(store.value, 'es');
      expect(c.choice, LanguageChoice.spanish);
      expect(c.issue, isNull);
    },
  );
  test(
    'read retry coalesces and prevents selection or stale read from replacing new state',
    () async {
      final store = DelayedLocaleRead()..readError = StateError('private');
      final c = LocaleController(store: store);
      addTearDown(c.dispose);
      await c.restore();
      store.readError = null;
      store.delayed = true;
      final retry = c.retry();
      expect(c.reading, true);
      await c.retry();
      await c.select(LanguageChoice.english);
      expect(store.reads, 2);
      expect(store.writes, 0);
      store.pending.complete('pt-PT');
      await retry;
      expect(c.reading, false);
      expect(c.choice, LanguageChoice.portuguesePortugal);
    },
  );
  test(
    'read retry after timeout ignores old result and does not notify after disposal',
    () async {
      final store = DelayedLocaleRead()..delayed = true;
      final c = LocaleController(
        store: store,
        timeout: const Duration(milliseconds: 10),
      );
      await c.restore();
      expect(c.readFailed, true);
      final old = store.pending;
      store.pending = Completer<String?>();
      final retried = c.retry();
      old.complete('es');
      await Future<void>.delayed(Duration.zero);
      expect(c.choice, LanguageChoice.system);
      var notices = 0;
      c.addListener(() => notices++);
      c.dispose();
      store.pending.complete('pt-PT');
      await retried;
      expect(notices, 0);
      expect(store.writes, 0);
    },
  );
  test('appearance read retry never writes system over stored dark', () async {
    final store = MemoryAppearance()
      ..saved = 'dark'
      ..failure = StateError('private');
    final c = AppearanceController(store: store);
    addTearDown(c.dispose);
    await c.restore();
    expect(c.readFailed, true);
    store.failure = null;
    await c.retry();
    expect(store.reads, 2);
    expect(store.writes, 0);
    expect(store.saved, 'dark');
    expect(c.mode, ThemeMode.dark);
    expect(c.feedback, isNull);
  });
  test(
    'appearance write retry resends selected mode and clears stale retry after success',
    () async {
      final store = MemoryAppearance()..saved = 'dark';
      final c = AppearanceController(store: store);
      addTearDown(c.dispose);
      await c.restore();
      store.failure = StateError('private');
      await c.select(ThemeMode.light);
      expect(c.mode, ThemeMode.dark);
      store.failure = null;
      await c.retry();
      await c.retry();
      expect(store.writes, 2);
      expect(store.saved, 'light');
      expect(c.mode, ThemeMode.light);
      expect(c.feedback, isNull);
    },
  );
  testWidgets('language recovery button reads instead of saving the fallback', (
    t,
  ) async {
    final store = MemoryLocaleStore('pt-PT')..readError = StateError('private');
    final c = LocaleController(store: store);
    addTearDown(c.dispose);
    await c.restore();
    await t.pumpWidget(
      LocaleScope(
        controller: c,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LanguagePage(),
        ),
      ),
    );
    final button = find.text('Try loading the preference again');
    await Scrollable.ensureVisible(t.element(button), alignment: 0.5);
    await t.pumpAndSettle();
    store.readError = null;
    await t.tap(button);
    await t.pumpAndSettle();
    expect(store.reads, 2);
    expect(store.writes, 0);
    expect(c.choice, LanguageChoice.portuguesePortugal);
  });
  testWidgets(
    'appearance recovery button reads without changing account storage',
    (t) async {
      final store = MemoryAppearance()
        ..saved = 'dark'
        ..failure = StateError('private');
      final c = AppearanceController(store: store);
      addTearDown(c.dispose);
      await c.restore();
      await t.pumpWidget(
        AppearanceScope(
          controller: c,
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AppearancePage(),
          ),
        ),
      );
      final button = find.text('Try loading the preference again');
      await Scrollable.ensureVisible(t.element(button), alignment: 0.5);
      await t.pumpAndSettle();
      store.failure = null;
      await t.tap(button);
      await t.pumpAndSettle();
      expect(store.reads, 2);
      expect(store.writes, 0);
      expect(c.mode, ThemeMode.dark);
    },
  );
}
