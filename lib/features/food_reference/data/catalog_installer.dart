import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as paths;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Public catalog files contain no account data. Only trusted signed snapshots
/// are opened; updates never overwrite a file currently used by a connection.
class CatalogInstaller {
  static const assetPrefix = 'assets/food_catalog/';
  static const _channel = MethodChannel('trainforge/catalog_assets');
  Future<Database>? _opening;
  Database? _database;
  bool get ready => _database?.isOpen == true;
  Map<String, dynamic>? _activeManifest;
  Future<Map<String, dynamic>> manifest() async {
    await open();
    return _activeManifest!;
  }

  final Future<String> Function(String) readAsset;
  CatalogInstaller({Future<String> Function(String)? readAsset})
    : readAsset = readAsset ?? rootBundle.loadString;

  int _databaseBytes(Map<String, dynamic> manifest) =>
      manifest['databaseBytes'] as int? ?? manifest['bytes'] as int;
  String _databaseHash(Map<String, dynamic> manifest) =>
      manifest['databaseSha256'] as String? ?? manifest['sha256'] as String;

  Future<Directory> _directory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(
      paths.join(support.path, 'food_catalog'),
    ).create(recursive: true);
  }

  Future<Map<String, dynamic>> verifyEnvelope(String envelope) async {
    final trust =
        jsonDecode(await readAsset('${assetPrefix}trust.json')) as Map;
    final signed = jsonDecode(envelope) as Map;
    final keys = trust['keys'] as List;
    final matching = keys
        .where((v) => (v as Map)['keyId'] == signed['keyId'])
        .toList();
    if (matching.length != 1 || matching.single['algorithm'] != 'Ed25519') {
      throw const FormatException('Catalog signing key is not trusted');
    }
    final payload = base64Decode(signed['payload'] as String);
    final signature = Signature(
      base64Decode(signed['signature'] as String),
      publicKey: SimplePublicKey(
        base64Decode(matching.single['publicKey'] as String),
        type: KeyPairType.ed25519,
      ),
    );
    if (!await Ed25519().verify(payload, signature: signature)) {
      throw const FormatException('Catalog signature does not match');
    }
    final manifest = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(payload)) as Map,
    );
    if (manifest['contract'] != 'trainforge.food-catalog/1' ||
        manifest['schemaVersion'] != 1 ||
        !const {
          'catalog.sqlite',
          'catalog.sqlite.gz',
        }.contains(manifest['file']) ||
        !RegExp(
          r'^[a-f0-9]{64}$',
        ).hasMatch(manifest['sha256'] as String? ?? '') ||
        !RegExp(
          r'^[a-f0-9]{64}$',
        ).hasMatch(manifest['version'] as String? ?? '') ||
        manifest['bytes'] is! int ||
        (manifest['bytes'] as int) <= 0) {
      throw const FormatException('Catalog format is unsupported');
    }
    if (manifest['file'] == 'catalog.sqlite.gz' &&
        (manifest['databaseBytes'] is! int ||
            (manifest['databaseBytes'] as int) <= 0 ||
            !RegExp(
              r'^[a-f0-9]{64}$',
            ).hasMatch(manifest['databaseSha256'] as String? ?? ''))) {
      throw const FormatException('Uncompressed catalog integrity is missing');
    }
    return manifest;
  }

  Future<void> _verifyFile(File file, Map<String, dynamic> manifest) async {
    if (await file.length() != _databaseBytes(manifest) ||
        (await hashes.sha256.bind(file.openRead()).first).toString() !=
            _databaseHash(manifest)) {
      throw const FormatException('Catalog integrity check failed');
    }
    final db = await openDatabase(
      file.path,
      readOnly: true,
      singleInstance: false,
    );
    try {
      final check = await db.rawQuery('PRAGMA quick_check');
      final version = await db.query(
        'metadata',
        where: 'key=?',
        whereArgs: ['version'],
      );
      if (check.single.values.single != 'ok' ||
          version.single['value'] != manifest['version']) {
        throw const FormatException('Catalog database is invalid');
      }
    } finally {
      await db.close();
    }
  }

  Future<Database> open() => _opening ??= _open().catchError((Object error) {
    _opening = null;
    throw error;
  });

  Future<Database> _open() async {
    final dir = await _directory();
    final installed = File(paths.join(dir.path, 'active.json'));
    if (await installed.exists()) {
      final envelope = await installed.readAsString();
      final manifest = await verifyEnvelope(envelope);
      final bundled = await verifyEnvelope(
        await readAsset('${assetPrefix}manifest.json'),
      );
      final marker = File(paths.join(dir.path, 'bundled.sha256'));
      final previousBundle = await marker.exists()
          ? await marker.readAsString()
          : null;
      // A newly installed APK publishes a complete newer snapshot. Apply that
      // snapshot when its signed package differs from the active one.
      if (previousBundle != bundled['sha256']) {
        return _installBundled(dir);
      }
      final file = File(
        paths.join(dir.path, '${_databaseHash(manifest)}.sqlite'),
      );
      // Every installation/update validates the entire hash. Later openings
      // still validate signature, size, and SQLite; no full-file RAM allocation.
      if (await file.exists() &&
          await file.length() == _databaseBytes(manifest)) {
        _database = await openDatabase(
          file.path,
          readOnly: true,
          singleInstance: false,
        );
        _activeManifest = manifest;
        return _database!;
      }
    }
    return _installBundled(dir);
  }

  Future<Database> _installBundled(Directory dir) async {
    final envelope = await readAsset('${assetPrefix}manifest.json');
    final manifest = await verifyEnvelope(envelope);
    final destination = File(
      paths.join(dir.path, '${_databaseHash(manifest)}.sqlite'),
    );
    if (!await destination.exists()) {
      final temporary = File('${destination.path}.tmp');
      if (await temporary.exists()) await temporary.delete();
      try {
        await _channel.invokeMethod<int>('copyAsset', {
          'asset': '$assetPrefix${manifest['assetFile'] ?? manifest['file']}',
          'destination': temporary.path,
          'decompressGzip': (manifest['assetFile'] ?? manifest['file'])
              .toString()
              .endsWith('.gz'),
          'maxBytes': _databaseBytes(manifest),
        });
        await _verifyFile(temporary, manifest);
        await temporary.rename(destination.path);
      } finally {
        if (await temporary.exists()) await temporary.delete();
      }
    } else {
      await _verifyFile(destination, manifest);
    }
    await _activate(dir, envelope);
    await File(
      paths.join(dir.path, 'bundled.sha256'),
    ).writeAsString(manifest['sha256'] as String, flush: true);
    _database = await openDatabase(
      destination.path,
      readOnly: true,
      singleInstance: false,
    );
    _activeManifest = manifest;
    return _database!;
  }

  Future<void> _activate(Directory dir, String envelope) async {
    final temporary = File(paths.join(dir.path, 'active.json.tmp'));
    await temporary.writeAsString(envelope, flush: true);
    await temporary.rename(paths.join(dir.path, 'active.json'));
  }

  /// A ZIP contains only manifest.json and catalog.sqlite. The trust file is
  /// always bundled in the APK, never accepted from the imported archive.
  Future<void> importArchive(String path) async {
    final dir = await _directory();
    final input = InputFileStream(path);
    File? temporary;
    File? compressed;
    try {
      final archive = ZipDecoder().decodeStream(input);
      if (archive.files.length != 2) {
        throw const FormatException(
          'Catalog archive must contain exactly two files',
        );
      }
      final manifests = archive.files
          .where((f) => f.name == 'manifest.json' && f.isFile)
          .toList();
      if (manifests.length != 1 ||
          manifests.single.size > 262144 ||
          manifests.single.compression != CompressionType.none ||
          manifests.single.isSymbolicLink) {
        throw const FormatException('Invalid catalog archive');
      }
      final envelope = utf8.decode(manifests.single.content);
      final manifest = await verifyEnvelope(envelope);
      final databases = archive.files
          .where((f) => f.name == manifest['file'] && f.isFile)
          .toList();
      if (databases.length != 1) {
        throw const FormatException('Catalog payload missing');
      }
      if (databases.single.compression != CompressionType.none ||
          databases.single.isSymbolicLink) {
        throw const FormatException(
          'Catalog payload must use a stored archive member',
        );
      }
      if (databases.single.size != manifest['bytes']) {
        throw const FormatException('Catalog archive size mismatch');
      }
      temporary = File(
        paths.join(dir.path, '${_databaseHash(manifest)}.import.tmp'),
      );
      compressed = manifest['file'] == 'catalog.sqlite.gz'
          ? File('${temporary.path}.gz')
          : null;
      final output = OutputFileStream(compressed?.path ?? temporary.path);
      try {
        databases.single.writeContent(output);
      } finally {
        output.close();
      }
      if (compressed != null) {
        if (await compressed.length() != manifest['bytes'] ||
            (await hashes.sha256.bind(compressed.openRead()).first)
                    .toString() !=
                manifest['sha256']) {
          throw const FormatException(
            'Compressed catalog integrity check failed',
          );
        }
        var written = 0;
        final sink = temporary.openWrite();
        try {
          await sink.addStream(
            compressed.openRead().transform(gzip.decoder).map((chunk) {
              written += chunk.length;
              if (written > _databaseBytes(manifest)) {
                throw const FormatException(
                  'Catalog expanded beyond signed size',
                );
              }
              return chunk;
            }),
          );
          await sink.flush();
        } finally {
          await sink.close();
        }
      }
      await _verifyFile(temporary, manifest);
      final destination = File(
        paths.join(dir.path, '${_databaseHash(manifest)}.sqlite'),
      );
      if (await destination.exists()) {
        await temporary.delete();
      } else {
        await temporary.rename(destination.path);
      }
      await _activate(dir, envelope);
      final marker = File(paths.join(dir.path, 'bundled.sha256'));
      if (!await marker.exists()) {
        final bundled = await verifyEnvelope(
          await readAsset('${assetPrefix}manifest.json'),
        );
        await marker.writeAsString(bundled['sha256'] as String, flush: true);
      }
      final previous = _database;
      _database = null;
      _activeManifest = null;
      _opening = null;
      if (previous != null) await previous.close();
    } finally {
      input.close();
      if (temporary != null && await temporary.exists()) {
        await temporary.delete();
      }
      if (compressed != null && await compressed.exists()) {
        await compressed.delete();
      }
    }
  }
}
