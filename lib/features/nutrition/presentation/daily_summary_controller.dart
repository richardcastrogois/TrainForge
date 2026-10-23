import 'package:flutter/foundation.dart';
import '../domain/nutrition.dart';

/// One account-bound daily snapshot, shared by Hoje and Diário.
class DailySummaryController extends ChangeNotifier {
  final NutritionRepository repository;
  final String accountId;
  final String? Function() currentAccountId;
  final DateTime Function() now;
  DailySummaryController({
    required this.repository,
    required this.accountId,
    required this.currentAccountId,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  Json? summary;
  String? day, zone;
  bool loading = false, failed = false, _disposed = false;
  int _generation = 0;

  Future<void> load() async {
    if (_disposed || currentAccountId() != accountId) return;
    final date = now(), generation = ++_generation;
    final requestDay = localDay(date), requestZone = offsetZone(date);
    if (day != requestDay || zone != requestZone) summary = null;
    day = requestDay;
    zone = requestZone;
    loading = true;
    failed = false;
    notifyListeners();
    try {
      final value = await repository.summary(requestDay, requestZone);
      if (_disposed ||
          generation != _generation ||
          currentAccountId() != accountId) {
        return;
      }
      summary = value;
    } catch (_) {
      if (_disposed ||
          generation != _generation ||
          currentAccountId() != accountId) {
        return;
      }
      failed = true;
      // An old value is never presented as a confirmed current snapshot.
      summary = null;
    } finally {
      if (!_disposed &&
          generation == _generation &&
          currentAccountId() == accountId) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    summary = null;
    super.dispose();
  }
}

/// A single complete source method may be previewed. Different methods are never summed.
String? dailyEnergy(Json? summary) {
  if (summary == null ||
      summary['complete'] != true ||
      summary['entries'] == 0) {
    return null;
  }
  final candidates = objects(summary['nutrients'])
      .where(
        (n) =>
            n['unit'] == 'kcal' &&
            n['value'] != null &&
            n['includedEntries'] == summary['entries'] &&
            n['unknownEntries'] == 0,
      )
      .toList();
  if (candidates.length != 1) return null;
  final value = candidates.single['value'] as String;
  return (value.contains('.')
          ? value
                .replaceFirst(RegExp(r'0+$'), '')
                .replaceFirst(RegExp(r'\.$'), '')
          : value)
      .replaceAll('.', ',');
}
