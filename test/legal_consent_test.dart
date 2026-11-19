import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'package:trainforge/features/auth/presentation/pages/auth_page.dart';
import 'package:trainforge/features/legal/legal_consent_store.dart';
import 'package:trainforge/features/legal/legal_controller.dart';
import 'package:trainforge/features/legal/legal_documents.dart';
import 'package:trainforge/features/legal/presentation/legal_pages.dart';
import 'package:trainforge/l10n/generated/app_localizations.dart';
import 'package:trainforge/shared/widgets/auth_gate.dart';
import 'auth_controller_test.dart' show SessionFixture;
import 'nutrition_test.dart' show FakeNutrition;

/// Records POSTs; GET answers with [remote] (server-side decisions).
class _Server implements HttpClientAdapter {
  final posts = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> remote;
  bool fail;
  _Server({this.remote = const [], this.fail = false});
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async {
    if (fail) {
      throw DioException.connectionError(requestOptions: o, reason: 'offline');
    }
    if (o.method == 'POST') posts.add(Map<String, dynamic>.from(o.data as Map));
    return ResponseBody.fromString(
      jsonEncode({'items': o.method == 'GET' ? remote : []}),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// The failure suspected on a real phone: keystore writes throw.
class _BrokenStore extends MemoryLegalConsentStore {
  @override
  Future<void> write(String key, Map<String, dynamic>? value) async =>
      throw const FileSystemException('keystore unavailable');
}

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('pt', 'BR'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: TrainForgeTheme.light,
  home: home,
);

LegalController _controller(LegalConsentStore store, _Server server) =>
    LegalController(
      store: store,
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = server,
      locale: () => 'pt-BR',
      now: () => DateTime.utc(2026, 11, 19, 15),
    );

Future<void> _wait(WidgetTester t) async {
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 400)),
  );
  await t.pumpAndSettle();
}

Future<void> _accept(WidgetTester t) async {
  await t.tap(find.byKey(const ValueKey('legal-accept-documents')));
  await t.tap(find.byKey(const ValueKey('legal-accept-adult')));
  await t.pump();
  await t.tap(find.byKey(const ValueKey('legal-continue')));
  await _wait(t);
}

Map<String, dynamic> _remoteItem(LegalDocument d, String? sha) => {
  'document': d.id,
  'version': d.version,
  'documentSha': sha,
  'decision': 'accepted',
  'appVersion': legalAppVersion,
  'locale': 'pt-BR',
  'clientRecordedAt': '2026-11-19T12:00:00Z',
};

void main() {
  test('recorded app version follows pubspec', () {
    final version = RegExp(
      r'^version: (\S+)$',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1);
    expect(legalAppVersion, version);
  });

  testWidgets('visitors never see the legal gate', (t) async {
    final legal = _controller(MemoryLegalConsentStore(), _Server());
    final controller = AuthController(SessionFixture());
    addTearDown(controller.dispose);
    await t.pumpWidget(
      _app(
        AuthGate(
          controller: controller,
          nutritionRepository: FakeNutrition(),
          legal: legal,
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byType(AuthPage), findsOneWidget);
    expect(find.text('Antes de começar'), findsNothing);
  });

  testWidgets('account acceptance stores the exact text hash and reaches the server', (
    t,
  ) async {
    final server = _Server();
    final store = MemoryLegalConsentStore();
    final legal = _controller(store, server);
    await t.runAsync(() => legal.loadAccount('acc-1'));
    expect(legal.needsTerms('acc-1'), isTrue);
    await t.pumpWidget(
      _app(LegalConsentPage(controller: legal, accountId: 'acc-1')),
    );
    await t.pumpAndSettle();
    expect(find.text('Antes de começar'), findsOneWidget);
    FilledButton button() =>
        t.widget(find.byKey(const ValueKey('legal-continue')));
    expect(button().onPressed, isNull);
    await _accept(t);
    expect(legal.needsTerms('acc-1'), isFalse);
    final saved = store.values['accepted.acc-1']!;
    expect((saved['terms'] as Map)['sha'], legal.currentSha['terms']);
    final sent = server.posts.expand((b) => b['items'] as List).cast<Map>();
    expect(sent.map((i) => i['document']), containsAll(['terms', 'privacy']));
    expect(jsonEncode(server.posts), isNot(contains('acc-1')));
  });

  testWidgets('a failing device store still advances and keeps the proof queued', (
    t,
  ) async {
    final server = _Server(fail: true);
    final legal = _controller(_BrokenStore(), server);
    await t.runAsync(() => legal.loadAccount('acc-2'));
    await t.pumpWidget(
      _app(LegalConsentPage(controller: legal, accountId: 'acc-2')),
    );
    await t.pumpAndSettle();
    await _accept(t);
    expect(legal.needsTerms('acc-2'), isFalse, reason: 'no empty screen');
    server.fail = false;
    expect(await t.runAsync(() => legal.flush('acc-2')), isTrue);
    expect(server.posts.expand((b) => b['items'] as List).length, 2);
  });

  testWidgets('a reinstalled app recovers decisions from the server', (t) async {
    final texts = LegalTexts();
    final terms = await t.runAsync(() => texts.sha(termsDocument));
    final privacy = await t.runAsync(() => texts.sha(privacyDocument));
    final server = _Server(
      remote: [
        _remoteItem(termsDocument, terms),
        _remoteItem(privacyDocument, privacy),
        {
          'document': 'health_data',
          'version': healthConsentVersion,
          'decision': 'granted',
          'appVersion': legalAppVersion,
          'locale': 'pt-BR',
          'clientRecordedAt': '2026-11-19T12:00:00Z',
        },
      ],
    );
    final legal = _controller(MemoryLegalConsentStore(), server);
    await t.runAsync(() => legal.loadAccount('acc-3'));
    expect(legal.needsTerms('acc-3'), isFalse);
    expect(legal.healthGranted('acc-3'), isTrue);
    expect(HealthConsentRegistry.granted('acc-3'), isTrue);
  });

  testWidgets('a changed document asks again and offers to sign out', (
    t,
  ) async {
    final store = MemoryLegalConsentStore({
      'accepted.acc-4': {
        'terms': {'version': '0.9', 'sha': 'old', 'at': '2026-01-01T00:00:00Z'},
        'privacy': {
          'version': '0.9',
          'sha': 'old',
          'at': '2026-01-01T00:00:00Z',
        },
      },
    });
    final legal = _controller(store, _Server());
    await t.runAsync(() => legal.loadAccount('acc-4'));
    expect(legal.needsTerms('acc-4') && legal.isUpdate('acc-4'), isTrue);
    await t.pumpWidget(
      _app(
        LegalConsentPage(
          controller: legal,
          accountId: 'acc-4',
          onDeleteAccount: () {},
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Os termos mudaram'), findsOneWidget);
    expect(find.byKey(const ValueKey('legal-accept-adult')), findsNothing);
    expect(find.byKey(const ValueKey('legal-decline')), findsOneWidget);
  });

  testWidgets('declining health data blocks sync and is recorded', (t) async {
    final server = _Server();
    final legal = _controller(MemoryLegalConsentStore(), server);
    await t.runAsync(() => legal.loadAccount('acc-5'));
    expect(legal.healthGranted('acc-5'), isNull);
    await t.pumpWidget(
      _app(HealthConsentPage(controller: legal, accountId: 'acc-5')),
    );
    await t.pumpAndSettle();
    FilledButton allow() =>
        t.widget(find.byKey(const ValueKey('health-authorize')));
    expect(allow().onPressed, isNull);
    await t.tap(find.byKey(const ValueKey('health-not-now')));
    await _wait(t);
    expect(legal.healthGranted('acc-5'), isFalse);
    expect(HealthConsentRegistry.granted('acc-5'), isFalse);
    final sent = server.posts.expand((b) => b['items'] as List).cast<Map>();
    expect(sent.single['decision'], 'revoked');
  });
}
