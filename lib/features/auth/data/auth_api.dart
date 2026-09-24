//lib/features/auth/data/auth_api.dart
import 'package:dio/dio.dart';
import 'package:trainforge/core/http/app_dio.dart';
import '../domain/auth_user.dart';

class AuthApi {
  final Dio dio = AppDio.instance;

  Future<AuthUser> loginWithGoogleIdToken(String idToken) async {
    final response = await dio.post(
      '/mobile-auth/google',
      data: {'idToken': idToken},
    );

    return AuthUser.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await dio.get('/mobile-auth/me');
    return response.data;
  }
}
