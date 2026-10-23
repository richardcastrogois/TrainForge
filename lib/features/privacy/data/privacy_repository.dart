import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:trainforge/core/http/app_dio.dart';
import 'package:trainforge/features/auth/data/auth_storage.dart';
import '../domain/privacy.dart';

Map<String, dynamic> _decodeExport(String raw) =>
    Map<String, dynamic>.from(jsonDecode(raw) as Map);

class GoPrivacyRepository implements PrivacyRepository {
  final Dio dio;
  final AuthStorage storage;
  String? _cleanupAccess;
  GoPrivacyRepository({Dio? dio, AuthStorage? storage})
    : dio = dio ?? AppDio.instance,
      storage = storage ?? AuthStorage();
  @override
  Future<PrivacyPolicy> policy() async {
    final r = await dio.get(
      '/api/v1/privacy',
      options: Options(extra: {'publicAuth': true}),
    );
    return PrivacyPolicy.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  @override
  Future<PrivateExportPage> export(String section, {String? cursor}) async {
    final r = await dio.get(
      '/api/v1/me/export',
      options: Options(responseType: ResponseType.plain),
      queryParameters: {'section': section, 'limit': 20, 'cursor': ?cursor},
    );
    final raw = r.data as String;
    final decoded = raw.length > 65536
        ? await compute(_decodeExport, raw)
        : _decodeExport(raw);
    return PrivateExportPage.fromJson(decoded, rawJson: raw);
  }

  @override
  Future<DeletionIntent> intent() async {
    final r = await dio.post(
      '/api/v1/me/deletion-intent',
      data: {'confirmation': 'EXCLUIR MINHA CONTA'},
    );
    return DeletionIntent.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  @override
  Future<AccountErasure> erase(
    DeletionIntent intent,
    String confirmation,
  ) async {
    final r = await dio.delete(
      '/api/v1/me',
      data: {'confirmation': confirmation, 'challenge': intent.challenge},
    );
    final data = Map<String, dynamic>.from(r.data as Map);
    if (data['deleted'] != true) {
      throw const FormatException('Exclusão não confirmada');
    }
    final authorization = r.requestOptions.headers['Authorization'];
    _cleanupAccess =
        authorization is String && authorization.startsWith('Bearer ')
        ? authorization.substring(7)
        : null;
    var pending = false;
    try {
      await finishCleanup();
    } catch (_) {
      pending = true;
    }
    return AccountErasure(
      data['accountId'] as String,
      data['backupNotice'] as String,
      cleanupPending: pending,
    );
  }

  @override
  Future<void> finishCleanup() async {
    final token = _cleanupAccess;
    if (token != null) {
      await storage.clearIfAccessToken(token);
      _cleanupAccess = null;
    }
  }
}
