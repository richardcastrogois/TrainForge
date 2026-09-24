//lib/features/profile/data/profile_repository.dart
import 'package:trainforge/features/profile/data/profile_api.dart';
import 'package:trainforge/features/profile/domain/profile_data.dart';

class ProfileRepository {
  final ProfileApi api = ProfileApi();

  Future<ProfileData> getProfile() {
    return api.fetchProfile();
  }

  Future<TrainData> upsertTrainData({
    required int weightInGrams,
    required int heightInCentimeters,
    required int age,
    required int bodyFatPercentage,
  }) {
    return api.saveTrainData(
      weightInGrams: weightInGrams,
      heightInCentimeters: heightInCentimeters,
      age: age,
      bodyFatPercentage: bodyFatPercentage,
    );
  }
}
