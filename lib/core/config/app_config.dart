import 'package:flutter/foundation.dart';

class AppConfig {
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

  static void validate() {
    final uri = Uri.tryParse(apiBaseUrl);
    final local =
        uri != null &&
        ['127.0.0.1', 'localhost', '10.0.2.2', '::1'].contains(uri.host);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        (uri.scheme != 'https' &&
            !(kDebugMode && local && uri.scheme == 'http'))) {
      throw StateError(
        'Configure um endpoint HTTPS; HTTP local somente em debug.',
      );
    }
  }
}
