//lib/features/profile/data/profile_api.dart
import 'package:dio/dio.dart';
import 'package:trainforge/core/http/app_dio.dart';
import 'package:trainforge/features/profile/domain/profile_data.dart';

class ProfileApi {
  final Dio dio = AppDio.instance;

  Future<ProfileData> fetchProfile() async {
    final response = await dio.get('/mobile/profile');
    return ProfileData.fromJson(response.data);
  }

  Future<TrainData> saveTrainData({
    required int weightInGrams,
    required int heightInCentimeters,
    required int age,
    required int bodyFatPercentage,
  }) async {
    final response = await dio.put(
      '/mobile/profile/train-data',
      data: {
        'weightInGrams': weightInGrams,
        'heightInCentimeters': heightInCentimeters,
        'age': age,
        'bodyFatPercentage': bodyFatPercentage,
      },
    );

    return TrainData.fromJson(response.data);
  }
}
