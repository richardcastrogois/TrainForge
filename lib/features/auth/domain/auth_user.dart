//lib/features/auth/domain/auth_user.dart
class AuthUser {
  final String id;
  final String name;
  final String email;
  final String? image;
  final String token;

  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.image,
    required this.token,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;

    return AuthUser(
      id: user['id'],
      name: user['name'],
      email: user['email'],
      image: user['image'],
      token: json['token'],
    );
  }
}
