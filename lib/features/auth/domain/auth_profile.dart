class AuthProfile {
  final String id;
  final String name;
  final String email;
  final String? image;
  const AuthProfile({
    required this.id,
    required this.name,
    required this.email,
    this.image,
  });
  factory AuthProfile.fromJson(Map<String, dynamic> json) {
    final profile = AuthProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      image: json['image'] as String?,
    );
    if (profile.id.isEmpty) throw const FormatException('Identidade inválida');
    return profile;
  }
}

abstract interface class SessionRepository {
  Future<AuthProfile?> restoreSession();
  Future<AuthProfile> signIn();
  Future<void> logout();
}

enum SessionFailure { cancelled, configuration }

class SessionException implements Exception {
  final SessionFailure failure;
  const SessionException(this.failure);
}
