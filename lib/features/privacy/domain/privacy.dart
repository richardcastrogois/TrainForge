import 'dart:convert';

class PrivacyPolicy {
  final String sessionRetention;
  final String version,
      accountDeletion,
      backupRetention,
      restoreRequirement,
      erasureLedger,
      otherServices,
      futureStorage;
  final List<String> sections;
  PrivacyPolicy.fromJson(Map<String, dynamic> j)
    : sessionRetention = j['sessionRetention'] as String,
      version = j['version'] as String,
      accountDeletion = j['accountDeletion'] as String,
      backupRetention = j['backupRetention'] as String,
      restoreRequirement = j['restoreRequirement'] as String,
      erasureLedger = j['erasureLedger'] as String,
      otherServices = j['otherServices'] as String,
      futureStorage = j['futureStorage'] as String,
      sections = List<String>.from(j['exportSections'] as List);
}

class PrivateExportPage {
  final String? _rawJson;
  final String section, accountId;
  final List<Map<String, dynamic>> items;
  final String? cursor;
  final String notice;
  PrivateExportPage.fromJson(Map<String, dynamic> j, {String? rawJson})
    : _rawJson = rawJson,
      section = j['section'] as String,
      accountId = j['accountId'] as String,
      items = (j['items'] as List)
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList(),
      cursor = j['nextCursor'] as String?,
      notice = j['notice'] as String;
  late final String jsonText =
      _rawJson ??
      const JsonEncoder.withIndent(
        '  ',
      ).convert({'accountId': accountId, 'section': section, 'items': items});
  String get previewText {
    if (jsonText.length <= 12000) return jsonText;
    var end = 12000;
    final last = jsonText.codeUnitAt(end - 1);
    if (last >= 0xD800 && last <= 0xDBFF) end--;
    return '${jsonText.substring(0, end)}\n… Prévia limitada. A cópia inclui a página completa.';
  }
}

class DeletionIntent {
  final String challenge;
  final DateTime expiresAt;
  DeletionIntent.fromJson(Map<String, dynamic> j)
    : challenge = j['challenge'] as String,
      expiresAt = DateTime.parse(j['expiresAt'] as String);
}

class AccountErasure {
  final String accountId, backupNotice;
  final bool cleanupPending;
  const AccountErasure(
    this.accountId,
    this.backupNotice, {
    this.cleanupPending = false,
  });
}

abstract interface class PrivacyRepository {
  Future<PrivacyPolicy> policy();
  Future<PrivateExportPage> export(String section, {String? cursor});
  Future<DeletionIntent> intent();
  Future<AccountErasure> erase(DeletionIntent intent, String confirmation);
  Future<void> finishCleanup();
}
