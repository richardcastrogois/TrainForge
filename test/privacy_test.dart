import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/auth/data/auth_storage.dart';
import 'package:trainforge/features/privacy/data/privacy_repository.dart';
import 'package:trainforge/features/privacy/domain/privacy.dart';
import 'package:trainforge/features/privacy/presentation/privacy_controller.dart';
import 'package:trainforge/features/privacy/presentation/privacy_page.dart';

PrivacyPolicy fixturePolicy() => PrivacyPolicy.fromJson({
  'version': 'fixture',
  'sessionRetention': 'Fixture manual bounded maintenance.',
  'accountDeletion': 'Fixture account deletion after explicit confirmation.',
  'backupRetention':
      'Fixture historical backups remain pending operational expiration.',
  'restoreRequirement':
      'Fixture restored data remains offline until erasure records are applied.',
  'erasureLedger': 'Fixture minimum UUID and date.',
  'otherServices': 'Google account is separate.',
  'futureStorage': 'No personal photos in this isolated fixture.',
  'exportSections': ['account', 'sessions', 'foods', 'foodEntries'],
});
PrivateExportPage fixtureExport({String owner = 'fixture-a', String? cursor}) =>
    PrivateExportPage.fromJson({
      'accountId': owner,
      'section': 'account',
      'items': [
        {'id': owner, 'fixture': 'private fixture only'},
      ],
      'nextCursor': cursor,
      'notice': 'Fixture paginated export without credentials.',
    });

class FixturePrivacy implements PrivacyRepository {
  Object? eraseError, intentError;
  bool cleanupPending = false;
  int erases = 0, intents = 0, cleanups = 0;
  Completer<PrivateExportPage>? pending;
  @override
  Future<PrivacyPolicy> policy() async => fixturePolicy();
  @override
  Future<PrivateExportPage> export(String section, {String? cursor}) async =>
      pending == null ? fixtureExport() : pending!.future;
  @override
  Future<DeletionIntent> intent() async {
    intents++;
    if (intentError != null) throw intentError!;
    return DeletionIntent.fromJson({
      'challenge': 'fixture-only-never-runtime',
      'expiresAt': DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 5))
          .toIso8601String(),
    });
  }

  @override
  Future<AccountErasure> erase(
    DeletionIntent intent,
    String confirmation,
  ) async {
    erases++;
    if (eraseError != null) throw eraseError!;
    return AccountErasure(
      'fixture-a',
      'Fixture backup retention',
      cleanupPending: cleanupPending,
    );
  }

  @override
  Future<void> finishCleanup() async {
    cleanups++;
  }
}

DioException outage([int? status, String? code]) => DioException(
  requestOptions: RequestOptions(path: '/private-fixture-secret'),
  response: status == null
      ? null
      : Response(
          requestOptions: RequestOptions(),
          statusCode: status,
          data: {'code': code},
        ),
  error: 'secret fixture payload never displayed',
);

class MemoryPrivacyStorage extends AuthStorage {
  String? token = 'fixture-old';
  bool fail = false;
  @override
  Future<void> clearIfAccessToken(String expected) async {
    if (fail) throw StateError('secret storage failure');
    if (token == expected) token = null;
  }
}

void main() {
  test(
    'export keeps the exact server decimals for preview and copying',
    () async {
      const raw =
          '{"accountId":"fixture-a","section":"foods","items":[{"value":0.12345678901234567890123}],"nextCursor":null,"notice":"Fixture"}';
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) => h.resolve(
            Response(requestOptions: o, statusCode: 200, data: raw),
          ),
        ),
      );
      final page = await GoPrivacyRepository(
        dio: dio,
        storage: MemoryPrivacyStorage(),
      ).export('foods');
      expect(page.jsonText, raw);
      expect(page.previewText, contains('0.12345678901234567890123'));
    },
  );
  test('large export is previewed with a bound and copied completely', () {
    final page = PrivateExportPage.fromJson({
      'accountId': 'fixture-a',
      'section': 'foods',
      'items': [
        {'name': 'x' * 15000},
      ],
      'nextCursor': null,
      'notice': 'Fixture',
    });
    expect(page.previewText.length, lessThan(12200));
    expect(page.jsonText.length, greaterThan(15000));
  });
  test(
    'loading does not initiate erasure and typed confirmation is required',
    () async {
      final r = FixturePrivacy();
      final c = PrivacyController(r);
      await c.loadPolicy();
      expect(r.intents, 0);
      expect(r.erases, 0);
      await c.erase('wrong');
      expect(r.erases, 0);
      expect(c.erased, isNull);
      await c.requestDeletion();
      await c.erase('wrong');
      expect(r.erases, 0);
      c.dispose();
    },
  );
  test(
    'offline failure never reports deletion or exposes exception data',
    () async {
      final r = FixturePrivacy()..eraseError = outage();
      final c = PrivacyController(r);
      await c.requestDeletion();
      await c.erase('EXCLUIR MINHA CONTA');
      expect(c.erased, isNull);
      expect(c.deletionIntent, isNotNull);
      expect(c.error, isNot(contains('secret')));
      c.dispose();
    },
  );
  test('expired confirmation or old login requires a new intent', () async {
    for (final code in [
      'recent_login_required',
      'deletion_confirmation_invalid',
    ]) {
      final r = FixturePrivacy()
        ..eraseError = outage(
          code == 'recent_login_required' ? 409 : 400,
          code,
        );
      final c = PrivacyController(r);
      await c.requestDeletion();
      await c.erase('EXCLUIR MINHA CONTA');
      expect(c.erased, isNull);
      expect(c.deletionIntent, isNull);
      c.dispose();
    }
  });
  test(
    'confirmed erasure stays confirmed when local cleanup needs retry',
    () async {
      final r = FixturePrivacy()..cleanupPending = true;
      String? erasedId;
      final c = PrivacyController(
        r,
        afterDeletion: (id) async {
          erasedId = id;
        },
      );
      await c.loadExport();
      await c.requestDeletion();
      await c.erase('EXCLUIR MINHA CONTA');
      expect(c.erased, isNotNull);
      expect(c.erased!.cleanupPending, isTrue);
      expect(c.exportPage, isNull);
      expect(erasedId, isNull);
      await c.finishCleanup();
      expect(erasedId, 'fixture-a');
      expect(r.erases, 1);
      expect(r.cleanups, 1);
      expect(c.erased!.cleanupPending, isFalse);
      c.dispose();
    },
  );
  test('stale export is discarded after an account change', () async {
    final r = FixturePrivacy()..pending = Completer<PrivateExportPage>();
    String? owner = 'fixture-a';
    final c = PrivacyController(r, currentAccountId: () => owner);
    final task = c.loadExport();
    owner = 'fixture-b';
    r.pending!.complete(fixtureExport());
    await task;
    expect(c.exportPage, isNull);
    expect(c.error, isNotNull);
    c.dispose();
  });
  test('disposed controller retains no late private export', () async {
    final r = FixturePrivacy()..pending = Completer<PrivateExportPage>();
    final c = PrivacyController(r);
    final task = c.loadExport();
    c.dispose();
    r.pending!.complete(fixtureExport());
    await task;
    expect(c.exportPage, isNull);
  });
  test('reauthentication clears private pages and existing intent', () async {
    final c = PrivacyController(FixturePrivacy());
    await c.loadExport();
    await c.requestDeletion();
    await c.confirmAccount(() async {});
    expect(c.exportPage, isNull);
    expect(c.deletionIntent, isNull);
    c.dispose();
  });
  test(
    'late DELETE success cannot clear credentials of another login',
    () async {
      final storage = MemoryPrivacyStorage();
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://example.invalid',
          headers: {'Authorization': 'Bearer fixture-old'},
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            storage.token = 'fixture-new-account';
            h.resolve(
              Response(
                requestOptions: o,
                statusCode: 200,
                data: {
                  'deleted': true,
                  'accountId': 'fixture-a',
                  'backupNotice': 'Fixture',
                },
              ),
            );
          },
        ),
      );
      final repo = GoPrivacyRepository(dio: dio, storage: storage);
      final result = await repo.erase(
        DeletionIntent.fromJson({
          'challenge': 'fixture',
          'expiresAt': DateTime.now().toUtc().toIso8601String(),
        }),
        'EXCLUIR MINHA CONTA',
      );
      expect(result.accountId, 'fixture-a');
      expect(storage.token, 'fixture-new-account');
      expect(result.cleanupPending, isFalse);
    },
  );
  test('storage failure after confirmed deletion remains retryable', () async {
    final storage = MemoryPrivacyStorage()..fail = true;
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://example.invalid',
        headers: {'Authorization': 'Bearer fixture-old'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) => h.resolve(
          Response(
            requestOptions: o,
            statusCode: 200,
            data: {
              'deleted': true,
              'accountId': 'fixture-a',
              'backupNotice': 'Fixture',
            },
          ),
        ),
      ),
    );
    final repo = GoPrivacyRepository(dio: dio, storage: storage);
    final result = await repo.erase(
      DeletionIntent.fromJson({
        'challenge': 'fixture',
        'expiresAt': DateTime.now().toUtc().toIso8601String(),
      }),
      'EXCLUIR MINHA CONTA',
    );
    expect(result.cleanupPending, isTrue);
    expect(storage.token, 'fixture-old');
    storage.fail = false;
    await repo.finishCleanup();
    expect(storage.token, isNull);
  });
  testWidgets('public privacy policy does not expose account actions', (
    tester,
  ) async {
    final r = FixturePrivacy();
    final c = PrivacyController(r);
    await tester.pumpWidget(MaterialApp(home: PrivacyPage(controller: c)));
    await tester.pumpAndSettle();
    expect(find.text('Solicitar confirmação de exclusão'), findsNothing);
    expect(find.text('Consultar seção'), findsNothing);
    expect(r.intents, 0);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets(
    'private policy remains scrollable with doubled text on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final r = FixturePrivacy();
      final c = PrivacyController(r);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: PrivacyPage(authenticated: true, controller: c),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(r.erases, 0);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'deletion remains disabled until acknowledgement and exact phrase',
    (tester) async {
      final r = FixturePrivacy();
      final c = PrivacyController(r);
      await tester.pumpWidget(
        MaterialApp(home: PrivacyPage(authenticated: true, controller: c)),
      );
      await tester.pumpAndSettle();
      final request = find.widgetWithText(
        OutlinedButton,
        'Solicitar confirmação de exclusão',
      );
      await tester.scrollUntilVisible(
        request,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.widget<OutlinedButton>(request).onPressed, isNull);
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.ensureVisible(request);
      await tester.pumpAndSettle();
      await tester.tap(request);
      await tester.pumpAndSettle();
      final erase = find.widgetWithText(
        FilledButton,
        'Excluir minha conta e seus dados',
      );
      await tester.scrollUntilVisible(
        erase,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(erase).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'EXCLUIR MINHA CONTA');
      await tester.pumpAndSettle();
      await tester.ensureVisible(erase);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(erase).onPressed, isNotNull);
      expect(r.erases, 0);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
