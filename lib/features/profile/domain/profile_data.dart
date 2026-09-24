//lib/features/profile/domain/profile_data.dart
class TrainData {
  final String userId;
  final String? userName;
  final int weightInGrams;
  final int heightInCentimeters;
  final int age;
  final int bodyFatPercentage;

  TrainData({
    required this.userId,
    required this.userName,
    required this.weightInGrams,
    required this.heightInCentimeters,
    required this.age,
    required this.bodyFatPercentage,
  });

  double get weightInKg => weightInGrams / 1000;

  factory TrainData.fromJson(Map<String, dynamic> json) {
    return TrainData(
      userId: json['userId'],
      userName: json['userName'],
      weightInGrams: json['weightInGrams'],
      heightInCentimeters: json['heightInCentimeters'],
      age: json['age'],
      bodyFatPercentage: json['bodyFatPercentage'],
    );
  }
}

class ProfileUser {
  final String id;
  final String name;
  final String email;
  final String? image;

  ProfileUser({
    required this.id,
    required this.name,
    required this.email,
    required this.image,
  });

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      image: json['image'],
    );
  }
}

class ProfileData {
  final ProfileUser user;
  final TrainData? trainData;

  ProfileData({required this.user, required this.trainData});

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      user: ProfileUser.fromJson(json['user']),
      trainData: json['trainData'] != null
          ? TrainData.fromJson(json['trainData'])
          : null,
    );
  }
}
