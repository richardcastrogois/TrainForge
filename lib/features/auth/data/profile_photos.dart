import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Profile picture per account, kept only on this device.
///
/// * The Google account picture (its public URL) is saved at sign-in and
///   used by default.
/// * The person can pick another photo in Perfil e ajustes; it is copied to
///   the app's private folder and never uploaded.
/// * Erasing the account removes both.
class ProfilePhotos extends ChangeNotifier {
  ProfilePhotos._();
  static final instance = ProfilePhotos._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
  );
  static const _google = 'trainforge.photo.google.v1.';
  static const _custom = 'trainforge.photo.custom.v1.';

  final _googleUrls = <String, String?>{};
  final _customPaths = <String, String?>{};
  final _loaded = <String>{};

  String? googleUrl(String accountId) => _googleUrls[accountId];
  String? customPath(String accountId) => _customPaths[accountId];

  /// Reads what this device keeps for the account (once).
  Future<void> load(String accountId) async {
    if (!_loaded.add(accountId)) return;
    try {
      _googleUrls[accountId] = await _storage.read(key: _google + accountId);
      final path = await _storage.read(key: _custom + accountId);
      _customPaths[accountId] = path != null && File(path).existsSync()
          ? path
          : null;
    } catch (_) {
      // No secure storage (tests, desktop): the picture is optional.
    }
    notifyListeners();
  }

  Future<void> setGoogle(String accountId, String? url) async {
    if (url == null || !url.startsWith('https://')) return;
    _googleUrls[accountId] = url;
    notifyListeners();
    try {
      await _storage.write(key: _google + accountId, value: url);
    } catch (_) {}
  }

  /// Copies [source] into the private folder as this account's picture.
  Future<void> setCustom(String accountId, String source) async {
    final folder = Directory(
      '${(await getApplicationSupportDirectory()).path}/profile',
    );
    await folder.create(recursive: true);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final target = '${folder.path}/$accountId-$stamp.jpg';
    await File(source).copy(target);
    final old = _customPaths[accountId];
    _customPaths[accountId] = target;
    notifyListeners();
    try {
      await _storage.write(key: _custom + accountId, value: target);
    } catch (_) {}
    if (old != null && old != target) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
  }

  /// Back to the Google picture (or initials).
  Future<void> removeCustom(String accountId) async {
    final old = _customPaths.remove(accountId);
    notifyListeners();
    try {
      await _storage.delete(key: _custom + accountId);
      if (old != null) await File(old).delete();
    } catch (_) {}
  }

  /// Account erased on this device: forget everything about its picture.
  Future<void> forget(String accountId) async {
    await removeCustom(accountId);
    _googleUrls.remove(accountId);
    _loaded.remove(accountId);
    notifyListeners();
    try {
      await _storage.delete(key: _google + accountId);
    } catch (_) {}
  }
}
