import 'dart:convert';

import 'package:crypto/crypto.dart' as hashes;
import 'package:flutter/services.dart';

/// App version recorded with each consent. Kept equal to pubspec.yaml by
/// test/legal_consent_test.dart.
const legalAppVersion = '0.5.13+43';

/// Public copy of the bundled documents (Play Store requires a public URL).
const legalPublicBase =
    'https://github.com/richardcastrogois/TrainForge/blob/main/assets/legal/';

class LegalDocument {
  final String id;
  final String version;
  final String asset;
  final String titleKey;

  /// What changed in this version, shown when a previous version was accepted.
  final List<String> changesKey;
  const LegalDocument(
    this.id,
    this.version,
    this.asset,
    this.titleKey, [
    this.changesKey = const [],
  ]);
  String get publicUrl => legalPublicBase + asset.split('/').last;
}

const termsDocument = LegalDocument(
  'terms',
  '1.0',
  'assets/legal/termos-de-uso.md',
  'terms',
);
const privacyDocument = LegalDocument(
  'privacy',
  '1.0',
  'assets/legal/politica-de-privacidade.md',
  'privacy',
);
const legalDocuments = [termsDocument, privacyDocument];

/// Version of the separate health-data consent text shown in the app.
const healthConsentVersion = '1.0';

/// The SHA-256 of the exact bundled text proves which wording was accepted.
class LegalTexts {
  final Future<ByteData> Function(String) load;
  LegalTexts({Future<ByteData> Function(String)? load})
    : load = load ?? rootBundle.load;
  final Map<String, String> _sha = {};
  Future<String> sha(LegalDocument document) async =>
      _sha[document.id] ??= hashes.sha256
          .convert((await load(document.asset)).buffer.asUint8List())
          .toString();
  Future<String> text(LegalDocument document) async =>
      utf8.decode((await load(document.asset)).buffer.asUint8List());
}
