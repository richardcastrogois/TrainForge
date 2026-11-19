import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as paths;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart'
    show Database, DatabaseExecutor, Transaction;
import 'package:sqflite_sqlcipher/sqflite.dart' as cipher;

import '../domain/nutrition.dart';

typedef PrivateDatabaseOpener = Future<Database> Function();

class NutritionLocalStore {
  static Future<void> _keyPending = Future.value();
  static final _handles = <String, Set<Database>>{};
  static final _pendingOpens = <String, Set<Future<Database>>>{};
  static final _erasedAccounts = <String>{};
  static final _lockedAccounts = <String>{};
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
  );
  final String accountId;
  final String? Function() currentAccountId;
  final PrivateDatabaseOpener? databaseOpener;
  final FlutterSecureStorage secureStorage;
  Future<Database>? _opening;
  NutritionLocalStore({
    required this.accountId,
    required this.currentAccountId,
    this.databaseOpener,
    this.secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(resetOnError: false),
    ),
  });

  void check() {
    if (currentAccountId() != accountId ||
        _erasedAccounts.contains(accountId) ||
        _lockedAccounts.contains(accountId)) {
      throw StateError('Account changed');
    }
  }

  Future<Database> open() async {
    check();
    final task = _opening ??= _open().catchError((Object error) {
      _opening = null;
      throw error;
    });
    final pending = _pendingOpens.putIfAbsent(accountId, () => {});
    pending.add(task);
    late Database db;
    try {
      db = await task;
    } finally {
      pending.remove(task);
    }
    _handles.putIfAbsent(accountId, () => {}).add(db);
    check();
    return db;
  }

  Future<Database> _open() async {
    if (databaseOpener != null) return databaseOpener!();
    if (await isErased(accountId)) throw StateError('Account erased');
    if (await secureStorage.read(
          key: 'trainforge.nutrition.locked.$accountId',
        ) ==
        'true') {
      _lockedAccounts.add(accountId);
      throw StateError('Account requires authentication');
    }
    if (!RegExp(r'^[a-f0-9-]{36}$').hasMatch(accountId)) {
      throw const FormatException('Invalid account');
    }
    final directory = await getApplicationSupportDirectory();
    final filename = paths.join(directory.path, 'nutrition-$accountId.sqlite');
    final keyTask = _keyPending.then((_) async {
      final keyName = 'trainforge.nutrition.key.$accountId';
      var key = await secureStorage.read(key: keyName);
      if (key == null) {
        if (await File(filename).exists()) {
          throw StateError('Private database key unavailable');
        }
        key = base64UrlEncode(
          List<int>.generate(32, (_) => Random.secure().nextInt(256)),
        );
        await secureStorage.write(key: keyName, value: key);
      }
      return key;
    });
    _keyPending = keyTask.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    final key = await keyTask;
    check();
    return cipher.openDatabase(
      filename,
      password: key,
      version: 1,
      onCreate: (db, version) => createSchema(db),
    );
  }

  Future<T> transaction<T>(Future<T> Function(Transaction tx) action) async {
    final db = await open();
    return db.transaction((tx) async {
      check();
      final result = await action(tx);
      check();
      return result;
    });
  }

  static Future<void> createSchema(DatabaseExecutor db) async {
    await db.execute(
      'CREATE TABLE resources(entity TEXT NOT NULL,id TEXT NOT NULL,'
      'remote_id TEXT,value TEXT NOT NULL,deleted INTEGER NOT NULL DEFAULT 0,'
      'sync_state TEXT NOT NULL,PRIMARY KEY(entity,id))',
    );
    await db.execute(
      'CREATE INDEX resource_remote ON resources(entity,remote_id)',
    );
    await db.execute(
      'CREATE TABLE outbox(operation_id TEXT PRIMARY KEY,entity TEXT NOT NULL,'
      'local_id TEXT NOT NULL,kind TEXT NOT NULL,body TEXT NOT NULL,expected_revision INTEGER,'
      'state TEXT NOT NULL,code TEXT,wire TEXT,snapshot TEXT,created_at TEXT NOT NULL)',
    );
    await db.execute('CREATE INDEX pending_outbox ON outbox(state,created_at)');
    await db.execute(
      'CREATE TABLE metadata(key TEXT PRIMARY KEY,value TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE remote_maps(entity TEXT NOT NULL,local_id TEXT NOT NULL,'
      'remote_id TEXT NOT NULL,PRIMARY KEY(entity,local_id),UNIQUE(entity,remote_id))',
    );
    await db.execute(
      'CREATE TABLE conflicts(entity TEXT NOT NULL,id TEXT NOT NULL,'
      'value TEXT NOT NULL,PRIMARY KEY(entity,id))',
    );
    await db.execute(
      'CREATE TABLE contribution_media(id TEXT PRIMARY KEY,contribution_id TEXT NOT NULL,'
      'mime TEXT NOT NULL,content BLOB NOT NULL,state TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE private_food_versions(id TEXT NOT NULL,version TEXT NOT NULL,'
      'value TEXT NOT NULL,PRIMARY KEY(id,version))',
    );
  }

  static Future<bool> isErased(String accountId) async =>
      _erasedAccounts.contains(accountId) ||
      await _secure.read(key: 'trainforge.nutrition.erased.$accountId') ==
          'true';

  bool get locked => _lockedAccounts.contains(accountId);
  static Future<bool> isLocked(String accountId) async =>
      _lockedAccounts.contains(accountId) ||
      await _secure.read(key: 'trainforge.nutrition.locked.$accountId') ==
          'true';
  Future<void> lockAccount() async {
    _lockedAccounts.add(accountId);
    await secureStorage.write(
      key: 'trainforge.nutrition.locked.$accountId',
      value: 'true',
    );
  }

  static Future<void> unlockAccount(String accountId) async {
    await _secure.delete(key: 'trainforge.nutrition.locked.$accountId');
    _lockedAccounts.remove(accountId);
  }

  /// The tombstone is written before deleting files or keys and survives process
  /// death. It blocks cached offline login even before token cleanup finishes.
  static Future<void> eraseAccount(String accountId) async {
    if (!RegExp(r'^[a-f0-9-]{36}$').hasMatch(accountId)) {
      throw const FormatException('Invalid account');
    }
    await _secure.write(
      key: 'trainforge.nutrition.erased.$accountId',
      value: 'true',
    );
    _erasedAccounts.add(accountId);
    for (final opening
        in _pendingOpens[accountId]?.toList() ?? <Future<Database>>[]) {
      try {
        final db = await opening;
        _handles.putIfAbsent(accountId, () => {}).add(db);
      } catch (_) {}
    }
    final handles = _handles.remove(accountId) ?? <Database>{};
    for (final db in handles) {
      if (db.isOpen) await db.close();
    }
    final directory = await getApplicationSupportDirectory();
    final path = paths.join(directory.path, 'nutrition-$accountId.sqlite');
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final file = File('$path$suffix');
      if (await file.exists()) await file.delete();
    }
    await _secure.delete(key: 'trainforge.nutrition.key.$accountId');
  }

  Future<List<Json>> resources(String entity) async {
    final rows = await (await open()).query(
      'resources',
      where: 'entity=? AND deleted=0',
      whereArgs: [entity],
    );
    check();
    return rows
        .map(
          (r) => {
            ...object(jsonDecode(r['value'] as String)),
            'syncState': r['sync_state'],
            'localResourceId': r['id'],
          },
        )
        .toList();
  }

  Future<Json?> foodVersion(String id, String version) async {
    final rows = await (await open()).query(
      'private_food_versions',
      where: 'id=? AND version=?',
      whereArgs: [id, version],
    );
    check();
    return rows.isEmpty
        ? null
        : object(jsonDecode(rows.single['value'] as String));
  }

  Future<Json?> resource(String entity, String id) async {
    final rows = await (await open()).query(
      'resources',
      where: 'entity=? AND (id=? OR remote_id=?)',
      whereArgs: [entity, id, id],
      limit: 1,
    );
    check();
    if (rows.isEmpty) return null;
    return {
      ...object(jsonDecode(rows.single['value'] as String)),
      'syncState': rows.single['sync_state'],
    };
  }

  static Future<void> put(
    DatabaseExecutor db,
    String entity,
    String id,
    Json value, {
    String state = 'pending',
    String? remoteId,
    bool deleted = false,
  }) async {
    if (entity == 'food' && value['versionId'] is String) {
      await db.rawInsert(
        'INSERT OR IGNORE INTO private_food_versions(id,version,value) VALUES(?,?,?)',
        [id, value['versionId'], jsonEncode(value)],
      );
    }
    await db.rawInsert(
      'INSERT INTO resources(entity,id,remote_id,value,deleted,sync_state) '
      'VALUES(?,?,?,?,?,?) ON CONFLICT(entity,id) DO UPDATE SET '
      'remote_id=COALESCE(excluded.remote_id,resources.remote_id),value=excluded.value,'
      'deleted=excluded.deleted,sync_state=excluded.sync_state',
      [entity, id, remoteId, jsonEncode(value), deleted ? 1 : 0, state],
    );
  }

  static Future<void> enqueue(
    DatabaseExecutor db,
    String operationId,
    String entity,
    String localId,
    String kind,
    Json body, {
    int? expectedRevision,
    Json? snapshot,
  }) async {
    final existing = await db.query(
      'outbox',
      where: 'operation_id=?',
      whereArgs: [operationId],
    );
    if (existing.isNotEmpty) {
      if (existing.single['body'] != jsonEncode(body) ||
          existing.single['kind'] != kind) {
        throw StateError('Idempotency key reused for different intent');
      }
      return;
    }
    await db.insert('outbox', {
      'operation_id': operationId,
      'entity': entity,
      'local_id': localId,
      'kind': kind,
      'body': jsonEncode(body),
      'expected_revision': expectedRevision,
      'snapshot': snapshot == null ? null : jsonEncode(snapshot),
      'state': 'pending',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
