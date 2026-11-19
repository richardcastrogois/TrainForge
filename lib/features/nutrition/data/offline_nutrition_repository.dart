import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/http/app_dio.dart';
import '../../food_reference/data/local_food_repository.dart';
import '../domain/exact_nutrition.dart';
import '../domain/meals.dart';
import '../domain/nutrition.dart';
import '../domain/portion_quantity.dart';
import 'nutrition_local_store.dart';
import 'nutrition_sync.dart';

class OfflineNutritionRepository extends ChangeNotifier
    implements
        NutritionRepository,
        LocalizedNutritionRepository,
        MealRepository {
  final NutritionLocalStore store;
  final LocalFoodRepository catalog;
  final bool autoSync;

  /// Health-data consent (LGPD art. 11). Without it records stay on the device.
  final bool Function()? syncAllowed;
  late final NutritionSync synchronizer;
  bool syncBusy = false;
  Future<void>? _syncTask;
  bool _syncAgain = false;
  String? syncFailure;
  int pendingCount = 0, conflictCount = 0;
  OfflineNutritionRepository({
    required this.store,
    required this.catalog,
    Dio? dio,
    this.autoSync = true,
    this.syncAllowed,
  }) {
    synchronizer = NutritionSync(store: store, dio: dio ?? AppDio.instance);
  }

  Future<void> synchronize() {
    if (_syncTask != null) {
      _syncAgain = true;
      return _syncTask!;
    }
    final task = _syncLoop();
    _syncTask = task;
    return task.whenComplete(() => _syncTask = null);
  }

  Future<void> _syncLoop() async {
    do {
      _syncAgain = false;
      await _synchronizeOnce();
    } while (_syncAgain && syncFailure == null);
  }

  Future<void> _synchronizeOnce() async {
    syncBusy = true;
    syncFailure = null;
    notifyListeners();
    try {
      store.check();
      if (syncAllowed != null && !syncAllowed!()) {
        syncFailure = 'consent';
      } else {
        await synchronizer.run();
      }
    } on DioException catch (e) {
      syncFailure = e.response?.statusCode == 401
          ? 'authentication'
          : 'network';
      if (e.response?.statusCode == 401) {
        try {
          await store.lockAccount();
        } catch (_) {
          syncFailure = 'authentication';
        }
      }
    } catch (_) {
      syncFailure = 'storage';
    } finally {
      try {
        final db = await store.open();
        pendingCount =
            Sqflite.firstIntValue(
              await db.rawQuery(
                "SELECT COUNT(*) FROM outbox WHERE state NOT IN ('confirmed','cancelled')",
              ),
            ) ??
            0;
        conflictCount =
            Sqflite.firstIntValue(
              await db.rawQuery(
                "SELECT COUNT(*) FROM outbox WHERE state='conflict'",
              ),
            ) ??
            0;
      } catch (_) {
        /* The account may have changed during the request. */
      }
      syncBusy = false;
      notifyListeners();
    }
  }

  void _saved() {
    pendingCount++;
    notifyListeners();
    if (autoSync) unawaited(synchronize());
  }

  Future<Json> _food(String id, String version) async {
    if (id.startsWith('own:')) {
      final food = await store.resource('food', id);
      if (food == null || food['versionId'] != version) {
        final historical = await store.foodVersion(id, version);
        if (historical != null) return historical;
        throw const FormatException('Private food version unavailable');
      }
      return food;
    }
    return catalog.foodJson(id, version);
  }

  @override
  Future<NutritionPageData> foods({String q = '', String? cursor}) async {
    final offset = cursor == null ? 0 : int.tryParse(cursor);
    if (offset == null || offset < 0) {
      throw const FormatException('Invalid cursor');
    }
    final query = LocalFoodRepository.normalize(q);
    final values =
        (await store.resources('food'))
            .where(
              (f) => LocalFoodRepository.normalize(
                f['nameOriginal'] as String,
              ).contains(query),
            )
            .toList()
          ..sort(
            (a, b) => (a['nameOriginal'] as String).compareTo(
              b['nameOriginal'] as String,
            ),
          );
    return NutritionPageData.fromJson({
      'items': values.skip(offset).take(10).toList(),
      'nextCursor': values.length > offset + 10 ? '${offset + 10}' : null,
    });
  }

  @override
  Future<Json> createFood(Json body, String key) async {
    store.check();
    final id = 'own:$key';
    final existing = await store.resource('food', id);
    if (existing != null) return existing;
    final value = ownFood(body, id);
    await store.transaction((tx) async {
      store.check();
      await NutritionLocalStore.put(tx, 'food', id, value);
      await NutritionLocalStore.enqueue(
        tx,
        key,
        'food',
        key,
        'food.create',
        body,
      );
    });
    store.check();
    _saved();
    return {...value, 'syncState': 'pending'};
  }

  static Json ownFood(Json body, String id) {
    final name = (body['name'] as String).trim();
    if (name.isEmpty || name.length > 180) {
      throw const FormatException('Invalid food name');
    }
    final version = sha256.convert(utf8.encode(jsonEncode(body))).toString();
    final basis = object(body['basis']);
    final nutrients = objects(body['nutrients']);
    final portions = objects(body['portions'] ?? const []);
    if (nutrients.length > 32 ||
        (basis['quantity'] == null) != (basis['unit'] == null) ||
        (basis['quantity'] != null &&
            (!validDecimal(basis['quantity'] as String, positive: true) ||
                !const {'g', 'ml'}.contains(basis['unit'])))) {
      throw const FormatException('Invalid private food composition');
    }
    for (final portion in portions) {
      final quantity = portion['quantity'];
      if (quantity is! String || !validDecimal(quantity, positive: true)) {
        throw const FormatException('Invalid private food portion quantity');
      }
    }
    final identities = <String>{};
    for (final nutrient in nutrients) {
      final key = _canonicalId(
        nutrient['name'] as String,
        nutrient['unit'] as String,
      );
      if (!identities.add(key) ||
          (nutrient['value'] != null &&
              !validDecimal(nutrient['value'] as String))) {
        throw const FormatException(
          'Duplicate nutrient meaning or invalid value',
        );
      }
    }
    return {
      'id': id,
      'versionId': version,
      'nameOriginal': name,
      'nameLocale': 'und',
      'sourceId': 'personal',
      'sourceFoodId': id,
      'sourcePublishedVersion': 'user-declaration-v1',
      'basis': basis,
      'brand': body['brand'],
      'barcodes': body['barcodes'] ?? [],
      'portions': body['portions'] ?? [],
      'preparation': body['preparation'] ?? '',
      'source': {
        'name': 'User declaration',
        'publisher': '',
        'sourceUrl': '',
        'licenseLabel': 'Private',
        'licenseUrl': '',
        'attribution': '',
        'publishedAt': '',
        'changes': '',
        'warrantyNotice': '',
        'conditions': <String>[],
      },
      'nutrients': nutrients,
      'canonicalNutrients': nutrients.map((n) {
        final id =
            n['nutrientId'] as String? ??
            _canonicalId(n['name'] as String, n['unit'] as String);
        return {
          'nutrientId': id,
          'unit': n['unit'],
          'value': n['value'],
          'state': n['value'] == null ? 'missing' : 'numeric',
          'methodId': 'user-declaration',
          'primaryForTotals': true,
          'basisQuantity': basis['quantity'],
          'basisUnit': basis['unit'],
          'sourceColumnKey': id,
        };
      }).toList(),
    };
  }

  static String _canonicalId(String name, String unit) {
    final n = LocalFoodRepository.normalize(name);
    const synonyms = <String, List<String>>{
      'energy_kcal': ['energy', 'energia', 'calorias', 'calories'],
      'protein_g': ['protein', 'proteina', 'proteinas'],
      'carbohydrate_g': [
        'carbohydrate',
        'carboidrato',
        'carboidratos',
        'carbohidratos',
      ],
      'fat_g': ['fat', 'gordura', 'gorduras', 'gorduras totais', 'lipidios'],
      'fiber_g': ['fiber', 'fibre', 'fibra', 'fibras'],
      'sodium_mg': ['sodium', 'sodio'],
    };
    for (final e in synonyms.entries) {
      if (e.value.contains(n) && e.key.endsWith('_$unit')) return e.key;
    }
    // Unmapped user fields remain distinct; they cannot masquerade as a macro.
    return 'declared:${sha256.convert(utf8.encode('$n|$unit'))}';
  }

  Future<Json> _entry(Json body, String id, {Json? previous}) async {
    final quantity = body['quantity'] as String;
    if (!validSourceQuantity(quantity) ||
        !const {'g', 'ml'}.contains(body['unit']) ||
        !const {'measured', 'estimated'}.contains(body['quantityEvidence']) ||
        DateTime.tryParse(body['occurredAt'] as String) == null) {
      throw const FormatException('Invalid intake');
    }
    Json food;
    if (previous != null &&
        previous['foodId'] == body['foodId'] &&
        previous['foodVersion'] == body['foodVersion'] &&
        object(previous['calculation'])['algorithm'] ==
            'trainforge.canonical-nutrition/1') {
      final calculation = object(previous['calculation']);
      food = {
        ...object(calculation['food']),
        'canonicalNutrients': objects(calculation['nutrients'])
            .map(
              (n) => {
                'nutrientId': n['nutrientId'],
                'unit': n['unit'],
                'value': n['sourceValue'],
                'state': n['sourceState'],
                'upperBound': n['sourceUpperBound'],
                'methodId': n['methodId'],
                'primaryForTotals': true,
                'basisQuantity': object(n['basis'])['quantity'],
                'basisUnit': object(n['basis'])['unit'],
                'sourceColumnKey': n['sourceColumnKey'],
              },
            )
            .toList(),
      };
    } else {
      food = await _food(
        body['foodId'] as String,
        body['foodVersion'] as String,
      );
    }
    if (!validFoodIntakeQuantity(asFood(food), body)) {
      throw const FormatException('Invalid intake portion or quantity');
    }
    final revision = previous == null
        ? 1
        : (object(previous['calculation'])['revision'] as int) + 1;
    return {
      'id': id,
      'foodId': food['id'],
      'foodVersion': food['versionId'],
      'quantity': quantity,
      'unit': body['unit'],
      'occurredAt': body['occurredAt'],
      'timezone': body['timezone'],
      'deletedAt': null,
      'calculation': {
        'algorithm': 'trainforge.canonical-nutrition/1',
        'food': food,
        'origin': food['sourceId'] == 'personal' ? 'personal' : 'reference',
        'revision': revision,
        'preparation': body['preparation'],
        'quantityEvidence': body['quantityEvidence'],
        if (body['portion'] != null) 'portion': body['portion'],
        'nutrients': scaleCanonical(food, quantity, body['unit'] as String),
        'changes': previous == null
            ? <Json>[]
            : objects(object(previous['calculation'])['changes'] ?? []),
      },
    };
  }

  @override
  Future<Json> saveEntry(Json body, String key, {String? id}) async {
    body = {
      ...body,
      'calculationAlgorithm': 'trainforge.canonical-nutrition/1',
    };
    final localId = id ?? key;
    final previous = id == null ? null : await store.resource('entry', id);
    if (id != null &&
        (previous == null ||
            object(previous['calculation'])['revision'] != body['revision'])) {
      throw StateError('Intake revision changed');
    }
    if (id == null) {
      final old = await store.resource('entry', localId);
      if (old != null) return old;
    }
    final value = await _entry(body, localId, previous: previous);
    await store.transaction((tx) async {
      store.check();
      await NutritionLocalStore.put(tx, 'entry', localId, value);
      await NutritionLocalStore.enqueue(
        tx,
        key,
        'entry',
        localId,
        id == null ? 'entry.create' : 'entry.update',
        body,
        expectedRevision: body['revision'] as int?,
        snapshot: value,
      );
    });
    store.check();
    _saved();
    return {...value, 'syncState': 'pending'};
  }

  @override
  Future<void> deleteEntry(String id, int revision, String key) async {
    final value = await store.resource('entry', id);
    if (value == null || object(value['calculation'])['revision'] != revision) {
      throw StateError('Intake revision changed');
    }
    value['deletedAt'] = DateTime.now().toUtc().toIso8601String();
    await store.transaction((tx) async {
      await NutritionLocalStore.put(tx, 'entry', id, value, deleted: true);
      final neverSent = await tx.query(
        'outbox',
        where: 'entity=? AND local_id=? AND kind=? AND wire IS NULL',
        whereArgs: ['entry', id, 'entry.create'],
      );
      if (neverSent.isNotEmpty) {
        await tx.update(
          'outbox',
          {'state': 'cancelled'},
          where: 'entity=? AND local_id=?',
          whereArgs: ['entry', id],
        );
        return;
      }
      await NutritionLocalStore.enqueue(
        tx,
        key,
        'entry',
        id,
        'entry.delete',
        {'revision': revision},
        expectedRevision: revision,
        snapshot: value,
      );
    });
    store.check();
    _saved();
  }

  Future<List<Json>> _day(String day, String zone) async {
    final entries = await store.resources('entry');
    final offset = RegExp(r'^([+-])(\d{2}):(\d{2})$').firstMatch(zone);
    if (offset == null) {
      throw const FormatException('Unsupported timezone offset');
    }
    final minutes =
        (int.parse(offset[2]!) * 60 + int.parse(offset[3]!)) *
        (offset[1] == '-' ? -1 : 1);
    return entries
        .where(
          (e) =>
              localDay(
                DateTime.parse(
                  e['occurredAt'] as String,
                ).toUtc().add(Duration(minutes: minutes)),
              ) ==
              day,
        )
        .toList()
      ..sort(
        (a, b) =>
            (b['occurredAt'] as String).compareTo(a['occurredAt'] as String),
      );
  }

  @override
  Future<NutritionPageData> entries(
    String day,
    String zone, {
    String? cursor,
  }) async {
    final offset = cursor == null ? 0 : int.tryParse(cursor);
    if (offset == null || offset < 0) {
      throw const FormatException('Invalid cursor');
    }
    final values = await _day(day, zone);
    return NutritionPageData.fromJson({
      'items': values.skip(offset).take(10).toList(),
      'nextCursor': values.length > offset + 10 ? '${offset + 10}' : null,
    });
  }

  @override
  Future<NutritionPageData> localizedEntries(
    String day,
    String zone, {
    required String locale,
    String? cursor,
    String? namesVersion,
  }) async {
    final page = await entries(day, zone, cursor: cursor);
    return NutritionPageData.fromJson({
      'items': page.items.map((e) => _display(e, locale)).toList(),
      'nextCursor': page.cursor,
      'nameCatalog': {'locale': locale, 'version': '0'},
    });
  }

  Json _display(Json e, String locale) => {
    ...e,
    'foodDisplay': {
      'foodId': e['foodId'],
      'foodVersion': e['foodVersion'],
      'nameCatalog': {'locale': locale, 'version': '0'},
      'reviewedName': null,
    },
  };
  @override
  Future<Json> localizedEntry(String id, {required String locale}) async {
    final value = await store.resource('entry', id);
    if (value == null || value['deletedAt'] != null) {
      throw StateError('Intake unavailable');
    }
    return _display(value, locale);
  }

  @override
  Future<Json> summary(String day, String zone) async {
    final values = await _day(day, zone);
    return {
      'date': day,
      'timezone': zone,
      ...exactTotals(values),
      'confirmedTotals': exactTotals(
        values.where((e) => e['syncState'] == 'confirmed').toList(),
      ),
    };
  }

  @override
  Future<MealDay> mealDay(
    String day,
    String timezone, {
    required String locale,
  }) async {
    final entries = await _day(day, timezone);
    final ids = entries.map((e) => e['id']).toSet();
    final groups = <Json>[];
    final grouped = <String>{};
    for (final value in await store.resources('meal')) {
      if (value['deletedAt'] != null) continue;
      final meal = object(value['meal']);
      final all = objects(value['entries']);
      final selected = all
          .where((e) => ids.contains(e['id']) && e['deletedAt'] == null)
          .toList();
      if (selected.isEmpty) continue;
      final current = entries
          .where((e) => selected.any((s) => s['id'] == e['id']))
          .toList();
      grouped.addAll(current.map((e) => e['id'] as String));
      final active = all.where((e) => e['deletedAt'] == null).length;
      groups.add({
        'meal': {...meal, 'totalActiveItems': active},
        'entryIds': current.map((e) => e['id']).toList(),
        'otherActiveItems': active - current.length,
        'totals': exactTotals(current),
      });
    }
    final visible = entries.take(100).toList();
    final visibleIds = visible.map((e) => e['id']).toSet();
    groups.removeWhere(
      (g) => (g['entryIds'] as List).any((id) => !visibleIds.contains(id)),
    );
    grouped.clear();
    for (final group in groups) {
      grouped.addAll(List<String>.from(group['entryIds'] as List));
    }
    return MealDay.fromJson({
      'date': day,
      'timezone': timezone,
      'nameCatalog': {'locale': locale, 'version': '0'},
      'diary': {
        'entries': visible.map((e) => _display(e, locale)).toList(),
        'meals': groups,
        'ungroupedEntryIds': visible
            .where((e) => !grouped.contains(e['id']))
            .map((e) => e['id'])
            .toList(),
        'totals': exactTotals(visible, complete: entries.length <= 100),
        'complete': entries.length <= 100,
      },
    });
  }

  @override
  Future<ConfirmedMeal> meal(String id, {required String locale}) async {
    final value = await store.resource('meal', id);
    if (value == null) throw StateError('Meal unavailable');
    final entries = <Json>[];
    for (final e in objects(value['entries'])) {
      entries.add(
        _display(await store.resource('entry', e['id'] as String) ?? e, locale),
      );
    }
    return ConfirmedMeal.fromJson({
      ...value,
      'entries': entries,
      'meal': {
        ...object(value['meal']),
        'totalActiveItems': entries.where((e) => e['deletedAt'] == null).length,
      },
    });
  }

  @override
  Future<ConfirmedMeal> createMeal(Json body, String key) async {
    final existing = await store.resource('meal', key);
    if (existing != null) return ConfirmedMeal.fromJson(existing);
    final items = objects(body['items'])
        .map(
          (i) => {
            ...i,
            'calculationAlgorithm': 'trainforge.canonical-nutrition/1',
          },
        )
        .toList();
    body = {...body, 'items': items};
    if (items.isEmpty || items.length > 32) {
      throw const FormatException('Invalid meal size');
    }
    final entries = <Json>[];
    for (final item in items) {
      entries.add(await _entry(item, mutationKey()));
    }
    final value = {
      'meal': {
        'id': key,
        'title': body['title'],
        'occurredAt': body['occurredAt'],
        'timezone': body['timezone'],
        'revision': 1,
        'totalActiveItems': entries.length,
      },
      'entries': entries,
      'deletedAt': null,
    };
    await store.transaction((tx) async {
      store.check();
      for (final e in entries) {
        await NutritionLocalStore.put(tx, 'entry', e['id'] as String, e);
      }
      await NutritionLocalStore.put(tx, 'meal', key, value);
      await NutritionLocalStore.enqueue(
        tx,
        key,
        'meal',
        key,
        'meal.create',
        body,
        snapshot: value,
      );
    });
    store.check();
    _saved();
    return ConfirmedMeal.fromJson(value);
  }

  @override
  Future<ConfirmedMeal> editMeal(String id, Json body, String key) async {
    final value = await store.resource('meal', id);
    if (value == null) throw StateError('Meal unavailable');
    final metadata = object(value['meal']);
    if (metadata['revision'] != body['revision']) {
      throw StateError('Meal revision changed');
    }
    value['meal'] = {
      ...metadata,
      'title': body['title'],
      'occurredAt': body['occurredAt'],
      'timezone': body['timezone'],
      'revision': (body['revision'] as int) + 1,
    };
    await store.transaction((tx) async {
      await NutritionLocalStore.put(tx, 'meal', id, value);
      await NutritionLocalStore.enqueue(
        tx,
        key,
        'meal',
        id,
        'meal.update',
        body,
        expectedRevision: body['revision'] as int,
        snapshot: value,
      );
    });
    store.check();
    _saved();
    return ConfirmedMeal.fromJson(value);
  }

  @override
  Future<ConfirmedMeal> deleteMeal(String id, int revision, String key) async {
    final value = await store.resource('meal', id);
    if (value == null || object(value['meal'])['revision'] != revision) {
      throw StateError('Meal revision changed');
    }
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final entries = <Json>[];
    for (final e in objects(value['entries'])) {
      entries.add({
        ...await store.resource('entry', e['id'] as String) ?? e,
        'deletedAt': timestamp,
      });
    }
    value['deletedAt'] = timestamp;
    value['entries'] = entries;
    value['meal'] = {
      ...object(value['meal']),
      'revision': revision + 1,
      'totalActiveItems': 0,
    };
    await store.transaction((tx) async {
      for (final e in entries) {
        await NutritionLocalStore.put(
          tx,
          'entry',
          e['id'] as String,
          e,
          deleted: true,
        );
      }
      await NutritionLocalStore.put(tx, 'meal', id, value, deleted: true);
      final neverSent = await tx.query(
        'outbox',
        where: 'entity=? AND local_id=? AND kind=? AND wire IS NULL',
        whereArgs: ['meal', id, 'meal.create'],
      );
      if (neverSent.isNotEmpty) {
        await tx.update(
          'outbox',
          {'state': 'cancelled'},
          where: 'entity=? AND local_id=?',
          whereArgs: ['meal', id],
        );
        return;
      }
      await NutritionLocalStore.enqueue(
        tx,
        key,
        'meal',
        id,
        'meal.delete',
        {'revision': revision, 'reviewed': true},
        expectedRevision: revision,
        snapshot: value,
      );
    });
    store.check();
    _saved();
    return ConfirmedMeal.fromJson(value);
  }

  Future<List<Json>> conflicts() async {
    final db = await store.open();
    final rows = await db.query(
      'outbox',
      where: "state IN ('conflict','invalid')",
      orderBy: 'created_at',
    );
    final result = <Json>[];
    for (final row in rows) {
      final entity = row['entity'] as String;
      final id = entity == 'food' ? 'own:${row['local_id']}' : row['local_id'];
      final saved = await db.query(
        'conflicts',
        where: 'entity=? AND id=?',
        whereArgs: [entity, id],
      );
      result.add({
        ...row,
        'body': object(jsonDecode(row['body'] as String)),
        if (saved.isNotEmpty)
          'server': object(jsonDecode(saved.single['value'] as String)),
      });
    }
    return result;
  }

  Future<void> acceptServer(String operationId) async {
    await synchronizer.acceptServer(operationId);
    await synchronize();
  }

  Future<void> keepLocal(String operationId) async {
    await synchronizer.keepLocal(operationId);
    await synchronize();
  }

  Future<String> contribute(
    Json foodBody, {
    List<String> photoPaths = const [],
  }) async {
    if (photoPaths.length > 2) {
      throw const FormatException('Too many label photos');
    }
    final media = <Json>[];
    for (final path in photoPaths) {
      final file = File(path);
      if (await file.length() > 4 * 1024 * 1024) {
        throw const FormatException('Label photo too large');
      }
      final bytes = await file.readAsBytes();
      final png =
          bytes.length >= 8 &&
          bytes[0] == 137 &&
          bytes[1] == 80 &&
          bytes[2] == 78 &&
          bytes[3] == 71;
      final jpeg =
          bytes.length >= 3 &&
          bytes[0] == 255 &&
          bytes[1] == 216 &&
          bytes[2] == 255;
      if (!png && !jpeg) throw const FormatException('Unsupported label photo');
      media.add({
        'id': mutationKey(),
        'mime': png ? 'image/png' : 'image/jpeg',
        'content': bytes,
      });
    }
    final id = mutationKey();
    final body = {
      'operationId': id,
      'food': foodBody,
      'consent': {
        'accepted': true,
        'version': 'trainforge.food-contribution/1',
        'license': 'CC0-1.0',
      },
    };
    await store.transaction((tx) async {
      await NutritionLocalStore.put(tx, 'contribution', id, {
        'id': id,
        'status': 'queued',
        'food': foodBody,
        'consent': body['consent'],
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      });
      await NutritionLocalStore.enqueue(
        tx,
        id,
        'contribution',
        id,
        'contribution.create',
        body,
      );
      for (final photo in media) {
        await tx.insert('contribution_media', {
          ...photo,
          'contribution_id': id,
          'state': 'pending',
        });
      }
    });
    store.check();
    _saved();
    return id;
  }

  Future<bool> contributionInvitesEnabled() async {
    final rows = await (await store.open()).query(
      'metadata',
      where: 'key=?',
      whereArgs: ['contribution_invite_suppressed'],
    );
    store.check();
    return rows.isEmpty || rows.single['value'] != 'true';
  }

  Future<void> setContributionInvites(bool enabled) async {
    await store.transaction(
      (tx) => tx.rawInsert(
        'INSERT INTO metadata(key,value) VALUES(?,?) '
        'ON CONFLICT(key) DO UPDATE SET value=excluded.value',
        ['contribution_invite_suppressed', enabled ? 'false' : 'true'],
      ),
    );
  }

  Future<void> cancelContribution(String id) async {
    if (syncBusy) {
      throw StateError('Wait for synchronization before withdrawing');
    }
    final db = await store.open();
    final row = await db.query(
      'resources',
      where: 'entity=? AND id=?',
      whereArgs: ['contribution', id],
    );
    if (row.isEmpty) throw StateError('Contribution unavailable');
    final remoteId = row.single['remote_id'];
    if (remoteId == null) {
      final operations = await db.query(
        'outbox',
        where: 'entity=? AND local_id=? AND wire IS NOT NULL',
        whereArgs: ['contribution', id],
      );
      if (operations.isNotEmpty) {
        throw StateError(
          'Synchronize the uncertain submission before withdrawal',
        );
      }
    }
    if (remoteId != null) {
      await synchronizer.cancelContribution(remoteId as String);
    }
    await store.transaction((tx) async {
      final value = object(jsonDecode(row.single['value'] as String));
      await NutritionLocalStore.put(tx, 'contribution', id, {
        ...value,
        'status': 'cancelled',
      }, state: 'cancelled');
      await tx.update(
        'outbox',
        {'state': 'cancelled'},
        where: 'entity=? AND local_id=?',
        whereArgs: ['contribution', id],
      );
      await tx.delete(
        'contribution_media',
        where: 'contribution_id=?',
        whereArgs: [id],
      );
    });
    notifyListeners();
  }
}
