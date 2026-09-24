//lib/features/home/data/home_repository.dart
import '../domain/home_summary.dart';
import 'home_api.dart';

class HomeRepository {
  final api = HomeApi();

  Future<HomeSummary> getSummary(String date) {
    return api.fetchSummary(date);
  }
}
