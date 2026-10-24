import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/theme/appearance_controller.dart';
import 'package:trainforge/core/motion/app_motion.dart';
import 'package:trainforge/features/auth/domain/auth_profile.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'auth_controller_test.dart' show fixtureProfile;

class MemoryAppearance implements AppearanceStore {
  String? saved;
  Object? failure;
  Completer<void>? pending;
  int writes = 0, reads = 0;
  @override
  Future<String?> read() async {
    reads++;
    if (failure != null) throw failure!;
    return saved;
  }

  @override
  Future<void> write(String value) async {
    writes++;
    if (failure != null) throw failure!;
    if (pending != null) await pending!.future;
    saved = value;
  }
}

class DelayedRestore implements SessionRepository {
  Completer<AuthProfile?> pending = Completer<AuthProfile?>();
  @override
  Future<AuthProfile?> restoreSession() => pending.future;
  @override
  Future<AuthProfile> signIn() async => fixtureProfile;
  @override
  Future<void> logout() async {}
}

void main() {
  test(
    'appearance is coalesced, persists, and rejects concurrent writes',
    () async {
      final store = MemoryAppearance()..saved = 'dark';
      final c = AppearanceController(store: store);
      await Future.wait([c.restore(), c.restore()]);
      expect(store.reads, 1);
      expect(c.mode, ThemeMode.dark);
      store.pending = Completer<void>();
      final pending = c.select(ThemeMode.light);
      await c.select(ThemeMode.system);
      expect(store.writes, 1);
      store.pending!.complete();
      await pending;
      expect(store.saved, 'light');
      final reopened = AppearanceController(store: store);
      await reopened.restore();
      expect(reopened.mode, ThemeMode.light);
      reopened.dispose();
      c.dispose();
    },
  );
  test(
    'appearance fallback and failed write never clear account credentials',
    () async {
      final store = MemoryAppearance()..saved = 'invalid';
      final c = AppearanceController(store: store);
      await c.restore();
      expect(c.mode, ThemeMode.system);
      expect(c.message, isNotNull);
      store.failure = StateError('private details must not be exposed');
      await c.select(ThemeMode.dark);
      expect(c.mode, ThemeMode.system);
      expect(c.message, contains('Não foi possível'));
      expect(c.message, isNot(contains('private')));
      c.dispose();
    },
  );
  test('late appearance write does not notify a disposed controller', () async {
    final store = MemoryAppearance(),
        c = AppearanceController(store: MemoryAppearance());
    await c.restore();
    c.dispose();
    final controller = AppearanceController(store: store);
    await controller.restore();
    store.pending = Completer<void>();
    final pending = controller.select(ThemeMode.dark);
    controller.dispose();
    store.pending!.complete();
    await pending;
  });
  test(
    'startup restore timeout remains retryable and ignores late identity',
    () async {
      final repo = DelayedRestore();
      final c = AuthController(
        repo,
        restoreTimeout: const Duration(milliseconds: 15),
      );
      await c.restore();
      expect(c.busy, false);
      expect(c.profile, isNull);
      expect(c.message, contains('preservada'));
      expect(c.failedAction, AuthAction.restore);
      repo.pending.complete(fixtureProfile);
      await Future<void>.delayed(Duration.zero);
      expect(c.profile, isNull);
      repo.pending = Completer<AuthProfile?>()..complete(fixtureProfile);
      await c.retry();
      expect(c.profile?.id, fixtureProfile.id);
      c.dispose();
    },
  );
  testWidgets('reduced motion skips incoming fades and modal animation', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              expect(AppMotion.style(context).duration, Duration.zero);
              return const AppAppear(child: Text('Movimento reduzido'));
            },
          ),
        ),
      ),
    );
    await t.pump();
    final fade = t.widget<FadeTransition>(
      find.descendant(
        of: find.byType(AppAppear),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fade.opacity.value, 1);
    expect(find.text('Movimento reduzido'), findsOneWidget);
  });
}
