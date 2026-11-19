import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path/path.dart' as paths;
import 'package:path_provider/path_provider.dart';
import 'package:trainforge/features/food_reference/data/catalog_installer.dart';
import 'package:trainforge/features/food_reference/data/local_food_repository.dart';
import 'package:trainforge/features/nutrition/data/nutrition_local_store.dart';
import 'package:trainforge/features/nutrition/data/offline_nutrition_repository.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';

/// Run only on a disposable Android AVD. This uses native SQLite/SQLCipher,
/// Keystore, asset streaming and bundled ML Kit, with no Google login or API.
/// Reopening a real database is tested; process death is not simulated here.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'complete bundled catalog, encrypted queue and EAN scanner work offline',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Offline native verification')),
        ),
      );
      final report = await tester.runAsync(() async {
        final installer = CatalogInstaller();
        final catalog = LocalFoodRepository(
          installer.open,
          installer: installer,
        );
        final opening = Stopwatch()..start();
        final db = await installer.open();
        opening.stop();
        final manifest = await installer.manifest();
        final rice = await catalog.list(q: 'arroz', sourceId: 'AL-TACO');
        expect(rice.items, isNotEmpty);
        final riceFood = await catalog.foodJson(
          rice.items.first.id,
          rice.items.first.versionId,
        );
        expect(riceFood['canonicalNutrients'], isNotEmpty);
        final candidates = await db.rawQuery(
          'SELECT code FROM barcodes WHERE length(code)=13 LIMIT 100',
        );
        final codes = candidates
            .map((r) => r['code'] as String)
            .where(LocalFoodRepository.validBarcode)
            .toList();
        expect(
          codes,
          isNotEmpty,
          reason: 'A full product catalog must contain a valid EAN-13',
        );
        final code = codes.first;
        expect(await catalog.barcode(code), isNotEmpty);

        final account = mutationKey();
        var current = account;
        final support = await getApplicationSupportDirectory();
        final databaseFile = File(
          paths.join(support.path, 'nutrition-$account.sqlite'),
        );
        final barcodeFile = File(
          paths.join(support.path, 'native-ean-$account.png'),
        );
        final scanner = MobileScannerController(
          autoStart: false,
          formats: [BarcodeFormat.ean13],
        );
        final transport = _NoNetwork();
        final dio = Dio(BaseOptions(baseUrl: 'https://unused.invalid'))
          ..httpClientAdapter = transport;
        const secure = FlutterSecureStorage(
          aOptions: AndroidOptions(resetOnError: false),
        );
        try {
          final store = NutritionLocalStore(
            accountId: account,
            currentAccountId: () => current,
          );
          final repository = OfflineNutritionRepository(
            store: store,
            catalog: catalog,
            dio: dio,
            autoSync: false,
          );
          final id = mutationKey();
          final entry = await repository.saveEntry({
            'foodId': rice.items.first.id,
            'foodVersion': rice.items.first.versionId,
            'quantity': '100',
            'unit': 'g',
            'preparation': riceFood['preparation'] ?? '',
            'occurredAt': '2026-11-18T12:00:00Z',
            'timezone': '-03:00',
            'quantityEvidence': 'measured',
            'revision': 0,
          }, id);
          expect(entry['syncState'], 'pending');
          final privateDb = await store.open();
          expect(await privateDb.query('outbox'), hasLength(1));
          await privateDb.close();
          final header = await databaseFile
              .openRead(0, 16)
              .fold<List<int>>([], (a, b) => a..addAll(b));
          expect(
            header,
            isNot(orderedEquals(utf8.encode('SQLite format 3\u0000'))),
          );
          final reopened = NutritionLocalStore(
            accountId: account,
            currentAccountId: () => current,
          );
          expect((await reopened.resources('entry')).single['id'], id);
          current = mutationKey();
          await expectLater(reopened.resources('entry'), throwsStateError);
          current = account;
          await reopened.lockAccount();
          expect(
            await secure.read(key: 'trainforge.nutrition.locked.$account'),
            'true',
          );
          expect(await NutritionLocalStore.isLocked(account), isTrue);
          final locked = NutritionLocalStore(
            accountId: account,
            currentAccountId: () => current,
          );
          await expectLater(locked.open(), throwsStateError);
          await NutritionLocalStore.unlockAccount(account);
          final unlocked = NutritionLocalStore(
            accountId: account,
            currentAccountId: () => current,
          );
          expect((await unlocked.resources('entry')).single['id'], id);

          await _drawEan(code, barcodeFile);
          final capture = await scanner.analyzeImage(
            barcodeFile.path,
            formats: [BarcodeFormat.ean13],
          );
          expect(capture?.barcodes.any((b) => b.rawValue == code), isTrue);
          expect(transport.requests, 0);
          repository.dispose();
          return <String, dynamic>{
            'contract': 'trainforge.food-offline-native/1',
            'catalogVersion': manifest['version'],
            'catalogBytes': manifest['databaseBytes'] ?? manifest['bytes'],
            'catalogOpeningMilliseconds': opening.elapsedMilliseconds,
            'tacoRiceFound': true,
            'barcodeLookup': true,
            'nativeEanImageDecoded': true,
            'privateFileHeaderEncrypted': true,
            'reopenPreservedOutbox': true,
            'accountIsolation': true,
            'persistentLockVerified': true,
            'networkRequests': transport.requests,
            'processDeathTested': false,
          };
        } finally {
          await scanner.dispose();
          await NutritionLocalStore.eraseAccount(account);
          expect(await databaseFile.exists(), isFalse);
          expect(
            await secure.read(key: 'trainforge.nutrition.key.$account'),
            isNull,
          );
          if (await barcodeFile.exists()) await barcodeFile.delete();
          await db.close();
        }
      });
      binding.reportData = report;
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

class _NoNetwork implements HttpClientAdapter {
  int requests = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? request,
    Future<void>? cancel,
  ) async {
    requests++;
    throw StateError('Native offline verification must not use HTTP');
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _drawEan(String code, File target) async {
  const left = [
    '0001101',
    '0011001',
    '0010011',
    '0111101',
    '0100011',
    '0110001',
    '0101111',
    '0111011',
    '0110111',
    '0001011',
  ];
  const alternate = [
    '0100111',
    '0110011',
    '0011011',
    '0100001',
    '0011101',
    '0111001',
    '0000101',
    '0010001',
    '0001001',
    '0010111',
  ];
  const right = [
    '1110010',
    '1100110',
    '1101100',
    '1000010',
    '1011100',
    '1001110',
    '1010000',
    '1000100',
    '1001000',
    '1110100',
  ];
  const parity = [
    'LLLLLL',
    'LLGLGG',
    'LLGGLG',
    'LLGGGL',
    'LGLLGG',
    'LGGLLG',
    'LGGGLL',
    'LGLGLG',
    'LGLGGL',
    'LGGLGL',
  ];
  final digits = code.split('').map(int.parse).toList();
  final pattern = parity[digits.first];
  var bits = '101';
  for (var i = 1; i <= 6; i++) {
    bits += (pattern[i - 1] == 'L' ? left : alternate)[digits[i]];
  }
  bits += '01010';
  for (var i = 7; i < 13; i++) {
    bits += right[digits[i]];
  }
  bits += '101';
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const width = 476, height = 240, scale = 4.0, quiet = 48.0;
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, width * 1.0, height * 1.0),
    ui.Paint()..color = const ui.Color(0xffffffff),
  );
  final paint = ui.Paint()..color = const ui.Color(0xff000000);
  for (var i = 0; i < bits.length; i++) {
    if (bits[i] == '1') {
      canvas.drawRect(
        ui.Rect.fromLTWH(quiet + i * scale, 24, scale, 192),
        paint,
      );
    }
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) throw StateError('EAN fixture rendering failed');
  await target.writeAsBytes(data.buffer.asUint8List(), flush: true);
  image.dispose();
  picture.dispose();
}
