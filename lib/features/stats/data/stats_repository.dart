//lib/features/stats/data/stats_repository.dart
import 'package:trainforge/features/stats/data/stats_api.dart';
import 'package:trainforge/features/stats/domain/stats_data.dart';

class StatsRepository {
  final StatsApi api = StatsApi();

  Future<StatsData> getStats({required String from, required String to}) {
    return api.fetchStats(from: from, to: to);
  }
}
