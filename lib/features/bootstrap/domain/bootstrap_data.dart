//lib/features/bootstrap/domain/bootstrap_data.dart
import 'package:trainforge/features/home/domain/home_summary.dart';
import 'package:trainforge/features/profile/domain/profile_data.dart';

class BootstrapData {
  final ProfileUser user;
  final HomeSummary homeData;
  final TrainData? trainData;
  final bool hasActivePlan;
  final bool needsOnboarding;

  BootstrapData({
    required this.user,
    required this.homeData,
    required this.trainData,
    required this.hasActivePlan,
    required this.needsOnboarding,
  });

  factory BootstrapData.fromJson(Map<String, dynamic> json) {
    return BootstrapData(
      user: ProfileUser.fromJson(json['user'] as Map<String, dynamic>),
      homeData: HomeSummary.fromJson(json['homeData'] as Map<String, dynamic>),
      trainData: json['trainData'] != null
          ? TrainData.fromJson(json['trainData'] as Map<String, dynamic>)
          : null,
      hasActivePlan: json['hasActivePlan'] == true,
      needsOnboarding: json['needsOnboarding'] == true,
    );
  }
}
