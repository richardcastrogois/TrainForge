import 'package:dio/dio.dart';
import 'package:trainforge/core/http/app_dio.dart';
import '../domain/auth_user.dart';

class AuthApi {
  final Dio dio;
  AuthApi({Dio? dio}) : dio = dio ?? AppDio.instance;

  Future<AuthUser> loginWithGoogleIdToken(String idToken) async {
    final response = await dio.post(
      '/api/v1/auth/google',
      data: {'idToken': idToken},
      options: Options(extra: {'publicAuth': true}),
    );
    return AuthUser.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await dio.get('/api/v1/me');
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> logout(String refreshToken) async {
    await dio.post(
      '/api/v1/auth/logout',
      data: {'refreshToken': refreshToken},
      options: Options(extra: {'publicAuth': true}),
    );
  }
}
