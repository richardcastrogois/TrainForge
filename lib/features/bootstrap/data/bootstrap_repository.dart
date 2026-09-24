//lib/features/bootstrap/data/bootstrap_repository.dart
import 'package:trainforge/features/bootstrap/data/bootstrap_api.dart';
import 'package:trainforge/features/bootstrap/domain/bootstrap_data.dart';

class BootstrapRepository {
  final BootstrapApi api = BootstrapApi();

  Future<BootstrapData> getBootstrap() {
    return api.fetchBootstrap();
  }
}
