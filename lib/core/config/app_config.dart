import 'package:flutter/foundation.dart';

class AppConfig {
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: kDebugMode ? 'development' : 'production',
  );
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8082',
  );
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  static void validate() => validateEndpoint(
    url: apiBaseUrl,
    appEnvironment: environment,
    debug: kDebugMode,
  );

  /// Build configuration policy; tests exercise release and staging without a build.
  static void validateEndpoint({
    required String url,
    required String appEnvironment,
    required bool debug,
  }) {
    if (!const [
      'development',
      'staging',
      'production',
    ].contains(appEnvironment)) {
      throw StateError(
        'Configure APP_ENV como development, staging ou production.',
      );
    }
    final uri = Uri.tryParse(url);
    final local =
        uri != null &&
        ['127.0.0.1', 'localhost', '10.0.2.2', '::1'].contains(uri.host);
    final localDebug = debug && appEnvironment == 'development' && local;
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        (uri.scheme != 'https' && !(localDebug && uri.scheme == 'http'))) {
      throw StateError(
        'Configure um endpoint HTTPS; HTTP local somente em development/debug.',
      );
    }
  }
}
