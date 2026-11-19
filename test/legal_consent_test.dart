import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/legal/legal_consent_store.dart';
import 'package:trainforge/features/legal/legal_controller.dart';
import 'package:trainforge/features/legal/legal_documents.dart';
import 'package:trainforge/features/legal/presentation/legal_pages.dart';
import 'package:trainforge/l10n/generated/app_localizations.dart';

class _Capture implements HttpClientAdapter {
  final bodies = <Map<String, dynamic>>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async {
    bodies.add(Map<String, dynamic>.from(o.data as Map));
    return ResponseBody.fromString(
      '{"items":[]}',
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('pt', 'BR'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: TrainForgeTheme.light,
  home: home,
);

LegalController _controller(
  MemoryLegalConsentStore store, [
  _Capture? capture,
]) => LegalController(
  store: store,
  dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = capture ?? _Capture(),
  locale: () => 'pt-BR',
  now: () => DateTime.utc(2026, 11, 19, 15),
);

void main() {
  test('recorded app version follows pubspec', () {
    final version = RegExp(
      r'^version: (\S+)$',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1);
    expect(legalAppVersion, version);
  });

  testWidgets(
    'first use requires both checks and stores version and exact text hash',
    (t) async {
      final store = MemoryLegalConsentStore();
      final legal = _controller(store);
      await t.runAsync(legal.load);
      expect(legal.needsTerms, isTrue);
      await t.pumpWidget(_app(LegalConsentPage(controller: legal)));
      await t.pumpAndSettle();
      expect(find.text('Antes de começar'), findsOneWidget);
      FilledButton button() =>
          t.widget(find.byKey(const ValueKey('legal-continue')));
      expect(button().onPressed, isNull);
      await t.tap(find.byKey(const ValueKey('legal-accept-documents')));
      await t.pump();
      expect(
        button().onPressed,
        isNull,
        reason: 'age confirmation still missing',
      );
      await t.tap(find.byKey(const ValueKey('legal-accept-adult')));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('legal-continue')));
      await t.pumpAndSettle();
      expect(legal.needsTerms, isFalse);
      final saved = store.values['accepted']!;
      expect((saved['terms'] as Map)['version'], termsDocument.version);
      expect((saved['terms'] as Map)['sha'], legal.currentSha['terms']);
      expect((saved['privacy'] as Map)['at'], '2026-11-19T15:00:00.000Z');
    },
  );

  testWidgets('a changed document asks again with the update variant', (
    t,
  ) async {
    final store = MemoryLegalConsentStore({
      'accepted': {
        'terms': {'version': '0.9', 'sha': 'old', 'at': '2026-01-01T00:00:00Z'},
        'privacy': {
          'version': '0.9',
          'sha': 'old',
          'at': '2026-01-01T00:00:00Z',
        },
      },
    });
    final legal = _controller(store);
    await t.runAsync(legal.load);
    expect(legal.needsTerms && legal.isUpdate, isTrue);
    await t.pumpWidget(
      _app(LegalConsentPage(controller: legal, onDeleteAccount: () {})),
    );
    await t.pumpAndSettle();
    expect(find.text('Os termos mudaram'), findsOneWidget);
    expect(find.byKey(const ValueKey('legal-accept-adult')), findsNothing);
    expect(find.text('Excluir minha conta'), findsOneWidget);
  });

  testWidgets(
    'health consent is separate; declining keeps sync blocked and is recorded',
    (t) async {
      final capture = _Capture();
      final store = MemoryLegalConsentStore();
      final legal = _controller(store, capture);
      await t.runAsync(legal.load);
      await t.runAsync(legal.acceptTerms);
      await t.runAsync(() => legal.loadAccount('acc-1'));
      expect(legal.healthGranted('acc-1'), isNull);
      await t.pumpWidget(
        _app(HealthConsentPage(controller: legal, accountId: 'acc-1')),
      );
      await t.pumpAndSettle();
      FilledButton allow() =>
          t.widget(find.byKey(const ValueKey('health-authorize')));
      expect(allow().onPressed, isNull, reason: 'explicit checkbox required');
      await t.tap(find.byKey(const ValueKey('health-not-now')));
      await t.runAsync(() async {
        await t.pumpAndSettle();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      expect(legal.healthGranted('acc-1'), isFalse);
      expect(HealthConsentRegistry.granted('acc-1'), isFalse);
      final sent = capture.bodies
          .expand((b) => b['items'] as List)
          .cast<Map>()
          .toList();
      expect(
        sent.map((i) => i['document']),
        containsAll(['terms', 'privacy', 'health_data']),
      );
      expect(
        sent.firstWhere((i) => i['document'] == 'health_data')['decision'],
        'revoked',
      );
      expect(
        sent.firstWhere((i) => i['document'] == 'terms')['documentSha'],
        legal.currentSha['terms'],
      );
      expect(
        store.values['pending.acc-1'],
        isNull,
        reason: 'queue cleared after the server accepted',
      );
      expect(
        jsonEncode(sent),
        isNot(contains('acc-1')),
        reason: 'the server derives the account from the token',
      );
    },
  );

  testWidgets('a failed upload keeps decisions queued for the next opening', (
    t,
  ) async {
    final store = MemoryLegalConsentStore();
    final legal = LegalController(
      store: store,
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = _Failing(),
      locale: () => 'pt-BR',
    );
    await t.runAsync(legal.load);
    await t.runAsync(legal.acceptTerms);
    await t.runAsync(() => legal.loadAccount('acc-2'));
    await t.runAsync(() => legal.decideHealth('acc-2', granted: true));
    expect(HealthConsentRegistry.granted('acc-2'), isTrue);
    expect(((store.values['pending.acc-2']!['items']) as List).length, 3);
  });
}

class _Failing implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async =>
      throw DioException.connectionError(requestOptions: o, reason: 'offline');
  @override
  void close({bool force = false}) {}
}
