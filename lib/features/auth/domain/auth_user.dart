class AuthUser {
  final String id;
  final String name;
  final String email;
  final String? image;
  final String token;
  final String refreshToken;
  final int expiresIn;

  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.image,
    required this.token,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final result = AuthUser(
      id: user['id'] as String,
      name: user['name'] as String,
      email: user['email'] as String,
      image: user['image'] as String?,
      token: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
    );
    if (result.id.isEmpty ||
        result.token.isEmpty ||
        result.refreshToken.isEmpty ||
        result.expiresIn <= 0) {
      throw const FormatException('Resposta de sessão inválida');
    }
    return result;
  }
}
