import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/auth/data/auth_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  test(
    'native storage failure preserves the credential and allows a later read',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final calls = <MethodCall>[];
      var failRead = true;
      final persisted = jsonEncode({
        'accessToken': 'fixture-access',
        'refreshToken': 'fixture-refresh',
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            final args = call.arguments as Map;
            expect((args['options'] as Map)['resetOnError'], 'false');
            if (call.method == 'read') {
              if (failRead) {
                throw PlatformException(code: 'fixture-keystore-unavailable');
              }
              return persisted;
            }
            fail('Unexpected credential mutation during a read');
          });
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });
      final storage = AuthStorage();
      await expectLater(storage.getToken(), throwsA(isA<PlatformException>()));
      failRead = false;
      expect(await storage.getToken(), 'fixture-access');
      expect(await storage.getRefreshToken(), 'fixture-refresh');
      expect(calls.map((call) => call.method), everyElement('read'));
      expect(
        calls.every(
          (call) => (call.arguments as Map)['key'] == 'trainforge.go.v1.tokens',
        ),
        isTrue,
      );
    },
  );
}
