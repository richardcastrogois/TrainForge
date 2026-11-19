import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/nutrition.dart';
import 'calculation_parity.dart';
import 'nutrition_local_store.dart';

/// A durable immutable wire envelope survives process death and lost responses.
/// Local records are never replaced by pull data while they have pending edits.
class NutritionSync {
  final NutritionLocalStore store;
  final Dio dio;
  NutritionSync({required this.store, required this.dio});
  Options get options =>
      Options(headers: {'X-TrainForge-Account': store.accountId});

  Future<void> cancelContribution(String remoteId) async {
    await dio.delete(
      '/api/v1/me/food-contributions/${Uri.encodeComponent(remoteId)}',
      options: options,
    );
    store.check();
  }

  Future<void> acceptServer(String operationId) async {
    await store.transaction((tx) async {
      final operations = await tx.query(
        'outbox',
        where: 'operation_id=? AND state=?',
        whereArgs: [operationId, 'conflict'],
      );
      if (operations.length != 1) throw StateError('Conflict unavailable');
      final operation = operations.single;
      final entity = operation['entity'] as String;
      final id = entity == 'food'
          ? 'own:${operation['local_id']}'
          : operation['local_id'] as String;
      final values = await tx.query(
        'conflicts',
        where: 'entity=? AND id=?',
        whereArgs: [entity, id],
      );
      if (values.isEmpty) {
        throw StateError('Connect to retrieve the current server record');
      }
      final resource = object(jsonDecode(values.single['value'] as String));
      final remoteId = entity == 'meal'
          ? object(resource['meal'])['id'] as String
          : resource['id'] as String;
      await tx.update(
        'outbox',
        {'state': 'cancelled'},
        where: 'entity=? AND local_id=? AND state<>?',
        whereArgs: [entity, operation['local_id'], 'confirmed'],
      );
      await _ingest(
        tx,
        entity,
        remoteId,
        resource,
        resource['deletedAt'] != null,
      );
      await tx.delete(
        'conflicts',
        where: 'entity=? AND id=?',
        whereArgs: [entity, id],
      );
    });
  }

  Future<void> keepLocal(String operationId) async {
    await store.transaction((tx) async {
      final operations = await tx.query(
        'outbox',
        where: 'operation_id=? AND state=?',
        whereArgs: [operationId, 'conflict'],
      );
      if (operations.length != 1) throw StateError('Conflict unavailable');
      final operation = operations.single,
          entity = operation['entity'] as String;
      if (entity == 'food') {
        throw StateError('Create a corrected personal food instead');
      }
      final id = operation['local_id'] as String;
      final conflicts = await tx.query(
        'conflicts',
        where: 'entity=? AND id=?',
        whereArgs: [entity, id],
      );
      if (conflicts.isEmpty) {
        throw StateError('Current server record unavailable');
      }
      final remote = object(jsonDecode(conflicts.single['value'] as String));
      if (remote['deletedAt'] != null) {
        throw StateError('Deleted records cannot be recreated by a retry');
      }
      final revision = entity == 'meal'
          ? object(remote['meal'])['revision'] as int
          : object(remote['calculation'])['revision'] as int;
      final latest = await tx.query(
        'outbox',
        where: 'entity=? AND local_id=? AND state NOT IN (?,?)',
        whereArgs: [entity, id, 'confirmed', 'cancelled'],
        orderBy: 'rowid DESC',
        limit: 1,
      );
      final intent = latest.single;
      final body = object(jsonDecode(intent['body'] as String));
      body['revision'] = revision;
      final local = await tx.query(
        'resources',
        where: 'entity=? AND id=?',
        whereArgs: [entity, id],
      );
      final snapshot = object(jsonDecode(local.single['value'] as String));
      if (entity == 'meal') {
        snapshot['meal'] = {
          ...object(snapshot['meal']),
          'revision': revision + 1,
        };
      } else {
        snapshot['calculation'] = {
          ...object(snapshot['calculation']),
          'revision': revision + 1,
        };
      }
      final kind = (intent['kind'] as String).endsWith('.delete')
          ? '$entity.delete'
          : '$entity.update';
      await tx.update(
        'outbox',
        {'state': 'cancelled'},
        where: 'entity=? AND local_id=? AND state<>?',
        whereArgs: [entity, id, 'confirmed'],
      );
      await NutritionLocalStore.put(tx, entity, id, snapshot);
      await NutritionLocalStore.enqueue(
        tx,
        mutationKey(),
        entity,
        id,
        kind,
        body,
        expectedRevision: revision,
        snapshot: snapshot,
      );
    });
  }

  Future<void> run() async {
    store.check();
    final db = await store.open();
    // Serialize pending operations to preserve revision dependencies. Read state
    // after each confirmation so newly assigned IDs can enter the next envelope.
    for (var sent = 0; sent < 100; sent++) {
      store.check();
      final rows = await db.query(
        'outbox',
        where:
            "state IN ('pending','sending','pending_catalog','dependency_pending')",
        orderBy: 'rowid',
        limit: 1,
      );
      if (rows.isEmpty) break;
      final row = rows.single;
      final entity = row['entity'] as String;
      if (entity == 'contribution') {
        await _contribution(db, row);
        continue;
      }
      final wire = row['wire'] == null
          ? await _wire(db, row)
          : object(jsonDecode(row['wire'] as String));
      if (wire == null) break;
      await db.update(
        'outbox',
        {'wire': jsonEncode(wire), 'state': 'sending'},
        where: 'operation_id=?',
        whereArgs: [row['operation_id']],
      );
      store.check();
      final response = await dio.post(
        '/api/v1/me/nutrition/sync',
        options: options,
        data: {
          'contract': 'trainforge.nutrition-sync/1',
          'operations': [wire],
        },
      );
      store.check();
      final data = object(response.data);
      final results = objects(data['results']);
      if (data['contract'] != 'trainforge.nutrition-sync/1' ||
          results.length != 1 ||
          results.single['operationId'] != row['operation_id']) {
        throw const FormatException('Invalid synchronization confirmation');
      }
      final result = results.single;
      var status = result['status'] as String;
      if (!const {
        'confirmed',
        'conflict',
        'pending_catalog',
        'dependency_pending',
        'invalid',
      }.contains(status)) {
        throw const FormatException('Invalid synchronization state');
      }
      if (status == 'confirmed' && (entity == 'entry' || entity == 'meal')) {
        final local = row['snapshot'] is String
            ? object(jsonDecode(row['snapshot'] as String))
            : await store.resource(entity, row['local_id'] as String);
        final confirmed = result['value'] is Map
            ? object(result['value'])
            : null;
        final expectedBody = object(wire['body']);
        if (entity == 'meal' &&
            expectedBody['items'] is! List &&
            local != null) {
          final items = <Json>[];
          for (final entry in objects(local['entries'])) {
            final item = {...entry};
            final foodMap = await db.query(
              'remote_maps',
              where: 'entity=? AND local_id=?',
              whereArgs: ['food', entry['foodId']],
            );
            if (foodMap.isNotEmpty) {
              item['foodId'] = foodMap.single['remote_id'];
            }
            items.add(item);
          }
          expectedBody['items'] = items;
        }
        if (local != null &&
            confirmed != null &&
            !sameCalculationSnapshot(
              local,
              confirmed,
              meal: entity == 'meal',
              expectedBody: expectedBody,
            )) {
          status = 'conflict';
          result['code'] = 'calculation_mismatch';
        }
      }
      await store.transaction((tx) async {
        store.check();
        await tx.update(
          'outbox',
          {'state': status, 'code': result['code']},
          where: 'operation_id=?',
          whereArgs: [row['operation_id']],
        );
        if (status == 'confirmed') {
          final localId = row['local_id'] as String;
          final remoteId = result['remoteId'] as String?;
          final value = result['value'];
          if (remoteId == null || value is! Map) {
            throw const FormatException('Missing confirmed resource');
          }
          final localResourceId = entity == 'food' ? 'own:$localId' : localId;
          await tx.rawInsert(
            'INSERT INTO remote_maps(entity,local_id,remote_id) VALUES(?,?,?) '
            'ON CONFLICT(entity,local_id) DO UPDATE SET remote_id=excluded.remote_id',
            [entity, localResourceId, remoteId],
          );
          if (entity == 'meal' && (row['kind'] as String) == 'meal.create') {
            final localRows = await tx.query(
              'resources',
              where: 'entity=? AND id=?',
              whereArgs: ['meal', localResourceId],
            );
            final local = object(
              jsonDecode(localRows.single['value'] as String),
            );
            final localEntries = objects(local['entries']);
            final remoteEntries = objects(object(value)['entries']);
            if (localEntries.length != remoteEntries.length) {
              throw const FormatException('Meal mapping mismatch');
            }
            for (var i = 0; i < localEntries.length; i++) {
              await tx.rawInsert(
                'INSERT INTO remote_maps(entity,local_id,remote_id) VALUES(?,?,?) '
                'ON CONFLICT(entity,local_id) DO UPDATE SET remote_id=excluded.remote_id',
                ['entry', localEntries[i]['id'], remoteEntries[i]['id']],
              );
            }
          }
          final others =
              Sqflite.firstIntValue(
                await tx.rawQuery(
                  "SELECT COUNT(*) FROM outbox WHERE entity=? AND local_id=? AND state NOT IN ('confirmed','cancelled')",
                  [entity, localId],
                ),
              ) ??
              0;
          if (others == 0) {
            await _ingest(tx, entity, remoteId, object(value), false);
          } else {
            await tx.update(
              'resources',
              {'remote_id': remoteId},
              where: 'entity=? AND id=?',
              whereArgs: [entity, localResourceId],
            );
          }
        } else {
          final local = entity == 'food'
              ? 'own:${row['local_id']}'
              : row['local_id'];
          await tx.update(
            'resources',
            {'sync_state': status},
            where: 'entity=? AND id=?',
            whereArgs: [entity, local],
          );
          if (result['value'] is Map) {
            if (result['remoteId'] is String) {
              await tx.rawInsert(
                'INSERT INTO remote_maps(entity,local_id,remote_id) VALUES(?,?,?) '
                'ON CONFLICT(entity,local_id) DO UPDATE SET remote_id=excluded.remote_id',
                [entity, local, result['remoteId']],
              );
              if (entity == 'meal') {
                final current = await tx.query(
                  'resources',
                  where: 'entity=? AND id=?',
                  whereArgs: [entity, row['local_id']],
                );
                final desired = row['snapshot'] is String
                    ? object(jsonDecode(row['snapshot'] as String))
                    : current.isEmpty
                    ? null
                    : object(jsonDecode(current.single['value'] as String));
                final remoteEntries = objects(
                  object(result['value'])['entries'],
                );
                final localEntries = desired == null
                    ? <Json>[]
                    : objects(desired['entries']);
                if (localEntries.length == remoteEntries.length) {
                  for (var i = 0; i < localEntries.length; i++) {
                    await tx.rawInsert(
                      'INSERT INTO remote_maps(entity,local_id,remote_id) VALUES(?,?,?) '
                      'ON CONFLICT(entity,local_id) DO UPDATE SET remote_id=excluded.remote_id',
                      ['entry', localEntries[i]['id'], remoteEntries[i]['id']],
                    );
                  }
                }
              }
            }
            await tx.rawInsert(
              'INSERT INTO conflicts(entity,id,value) VALUES(?,?,?) '
              'ON CONFLICT(entity,id) DO UPDATE SET value=excluded.value',
              [entity, local, jsonEncode(result['value'])],
            );
          }
        }
      });
      if (status != 'confirmed') break;
    }
    await _pull(db);
    await _media(db);
    await _contributionStatuses(db);
  }

  Future<Json?> _wire(Database db, Map<String, Object?> row) async {
    final entity = row['entity'] as String;
    final local = entity == 'food'
        ? 'own:${row['local_id']}'
        : row['local_id'] as String;
    final mapping = await db.query(
      'remote_maps',
      where: 'entity=? AND local_id=?',
      whereArgs: [entity, local],
    );
    final body = object(jsonDecode(row['body'] as String));
    Future<bool> food(Json b) async {
      final id = b['foodId'] as String?;
      if (id == null || !id.startsWith('own:')) return true;
      final mapped = await db.query(
        'remote_maps',
        where: 'entity=? AND local_id=?',
        whereArgs: ['food', id],
      );
      if (mapped.isEmpty) return false;
      final values = await db.query(
        'resources',
        where: 'entity=? AND id=?',
        whereArgs: ['food', id],
      );
      b['foodId'] = mapped.single['remote_id'];
      b['foodVersion'] = object(
        jsonDecode(values.single['value'] as String),
      )['versionId'];
      return true;
    }

    if (!await food(body)) return null;
    if (body['items'] is List) {
      final items = objects(body['items']);
      for (final item in items) {
        if (!await food(item)) return null;
      }
      body['items'] = items;
    }
    final creating = (row['kind'] as String).endsWith('.create');
    if (!creating && mapping.isEmpty) {
      final create = await db.query(
        'outbox',
        where: 'entity=? AND local_id=? AND kind=?',
        whereArgs: [entity, row['local_id'], '$entity.create'],
      );
      if (create.isNotEmpty) return null;
    }
    return {
      'operationId': row['operation_id'],
      'kind': row['kind'],
      'localId': row['local_id'],
      if (!creating)
        'remoteId': mapping.isEmpty ? local : mapping.single['remote_id'],
      if (row['expected_revision'] != null)
        'expectedRevision': row['expected_revision'],
      'body': body,
    };
  }

  Future<void> _pull(Database db) async {
    for (var page = 0; page < 1000; page++) {
      final stored = await db.query(
        'metadata',
        where: 'key=?',
        whereArgs: ['cursor'],
      );
      final response = await dio.get(
        '/api/v1/me/nutrition/changes',
        options: options,
        queryParameters: {
          'limit': 100,
          if (stored.isNotEmpty) 'cursor': stored.single['value'],
        },
      );
      store.check();
      final data = object(response.data);
      final cursor = data['nextCursor'] ?? data['cursor'];
      if (cursor is! String || data['hasMore'] is! bool) {
        throw const FormatException('Invalid change cursor');
      }
      await store.transaction((tx) async {
        for (final item in objects(data['items'])) {
          final entity = item['entity'] as String;
          if (!const {'food', 'entry', 'meal'}.contains(entity)) {
            throw const FormatException('Invalid entity');
          }
          await _ingest(
            tx,
            entity,
            item['id'] as String,
            object(item['value']),
            item['deleted'] == true,
          );
        }
        await tx.rawInsert(
          'INSERT INTO metadata(key,value) VALUES(?,?) '
          'ON CONFLICT(key) DO UPDATE SET value=excluded.value',
          ['cursor', cursor],
        );
      });
      if (data['hasMore'] == false) return;
    }
    throw StateError(
      'Synchronization page budget reached; retry resumes from saved cursor',
    );
  }

  Future<void> _ingest(
    DatabaseExecutor tx,
    String entity,
    String remoteId,
    Json value,
    bool deleted,
  ) async {
    final maps = await tx.query(
      'remote_maps',
      where: 'entity=? AND remote_id=?',
      whereArgs: [entity, remoteId],
    );
    final localId = maps.isEmpty ? remoteId : maps.single['local_id'] as String;
    final operationLocalId = entity == 'food' && localId.startsWith('own:')
        ? localId.substring(4)
        : localId;
    final pending =
        Sqflite.firstIntValue(
          await tx.rawQuery(
            "SELECT COUNT(*) FROM outbox WHERE entity=? AND local_id=? AND state NOT IN ('confirmed','cancelled')",
            [entity, operationLocalId],
          ),
        ) ??
        0;
    if (pending > 0) {
      await tx.rawInsert(
        'INSERT INTO conflicts(entity,id,value) VALUES(?,?,?) '
        'ON CONFLICT(entity,id) DO UPDATE SET value=excluded.value',
        [entity, localId, jsonEncode(value)],
      );
      return;
    }
    if (entity == 'meal') {
      value['meal'] = {...object(value['meal']), 'id': localId};
      final entries = <Json>[];
      for (final e in objects(value['entries'])) {
        await _ingest(
          tx,
          'entry',
          e['id'] as String,
          e,
          e['deletedAt'] != null,
        );
        entries.add(await _mapEntry(tx, e));
      }
      value['entries'] = entries;
    } else if (entity == 'entry') {
      value = await _mapEntry(tx, value);
      value['id'] = localId;
    } else {
      value['id'] = localId;
    }
    await NutritionLocalStore.put(
      tx,
      entity,
      localId,
      value,
      state: 'confirmed',
      remoteId: remoteId,
      deleted: deleted || value['deletedAt'] != null,
    );
  }

  Future<Json> _mapEntry(DatabaseExecutor tx, Json value) async {
    Future<String> local(String entity, String remote) async {
      final rows = await tx.query(
        'remote_maps',
        where: 'entity=? AND remote_id=?',
        whereArgs: [entity, remote],
      );
      return rows.isEmpty ? remote : rows.single['local_id'] as String;
    }

    final id = await local('entry', value['id'] as String);
    final foodId = await local('food', value['foodId'] as String);
    final calculation = object(value['calculation']);
    final food = object(calculation['food']);
    return {
      ...value,
      'id': id,
      'foodId': foodId,
      'calculation': {
        ...calculation,
        'food': {...food, 'id': foodId},
      },
    };
  }

  Future<void> _contribution(Database db, Map<String, Object?> row) async {
    final body = object(jsonDecode(row['body'] as String));
    await db.update(
      'outbox',
      {'state': 'sending', 'wire': jsonEncode(body)},
      where: 'operation_id=?',
      whereArgs: [row['operation_id']],
    );
    store.check();
    final response = await dio.post(
      '/api/v1/me/food-contributions',
      data: body,
      options: options,
    );
    store.check();
    final result = object(response.data);
    if (result['id'] is! String ||
        !const {
          'submitted',
          'approved',
          'rejected',
          'withdrawn',
        }.contains(result['status'])) {
      throw const FormatException('Invalid contribution receipt');
    }
    await store.transaction((tx) async {
      await NutritionLocalStore.put(
        tx,
        'contribution',
        row['local_id'] as String,
        result,
        state: 'confirmed',
        remoteId: result['id'] as String,
      );
      await tx.update(
        'outbox',
        {'state': 'confirmed'},
        where: 'operation_id=?',
        whereArgs: [row['operation_id']],
      );
    });
  }

  Future<void> _media(Database db) async {
    final rows = await db.rawQuery(
      "SELECT m.*,r.remote_id FROM contribution_media m JOIN resources r "
      "ON r.entity='contribution' AND r.id=m.contribution_id "
      "WHERE m.state='pending' AND r.remote_id IS NOT NULL AND r.sync_state<>'cancelled' ORDER BY m.id",
    );
    for (final row in rows) {
      store.check();
      await dio.post(
        '/api/v1/me/food-contributions/${Uri.encodeComponent(row['remote_id'] as String)}/media',
        data: Stream<List<int>>.value(row['content'] as List<int>),
        options: Options(
          headers: {
            'X-TrainForge-Account': store.accountId,
            'Idempotency-Key': row['id'],
            'Content-Length': (row['content'] as List<int>).length,
          },
          contentType: row['mime'] as String,
        ),
      );
      store.check();
      await db.update(
        'contribution_media',
        {'state': 'confirmed'},
        where: 'id=?',
        whereArgs: [row['id']],
      );
    }
  }

  Future<void> _contributionStatuses(Database db) async {
    final local = await db.query(
      'resources',
      where: 'entity=? AND remote_id IS NOT NULL',
      whereArgs: ['contribution'],
    );
    for (final row in local) {
      final response = await dio.get(
        '/api/v1/me/food-contributions/${Uri.encodeComponent(row['remote_id'] as String)}',
        options: options,
      );
      store.check();
      final resource = object(response.data);
      await NutritionLocalStore.put(
        db,
        'contribution',
        row['id'] as String,
        resource,
        state: resource['status'] == 'withdrawn' ? 'cancelled' : 'confirmed',
        remoteId: row['remote_id'] as String,
      );
    }
  }
}
