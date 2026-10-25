import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/config/app_config.dart';

void main() {
  test('HTTP is restricted to development debug and exact local hosts', () {
    for (final host in ['127.0.0.1', 'localhost', '10.0.2.2', '[::1]']) {
      expect(
        () => AppConfig.validateEndpoint(
          url: 'http://$host:8082',
          appEnvironment: 'development',
          debug: true,
        ),
        returnsNormally,
      );
    }
    for (final env in ['development', 'staging', 'production']) {
      for (final debug in [false, true]) {
        if (env == 'development' && debug) continue;
        expect(
          () => AppConfig.validateEndpoint(
            url: 'http://localhost:8082',
            appEnvironment: env,
            debug: debug,
          ),
          throwsStateError,
        );
      }
    }
    for (final host in [
      'example.invalid',
      'localhost.example.invalid',
      '192.168.1.2',
    ]) {
      expect(
        () => AppConfig.validateEndpoint(
          url: 'http://$host:8082',
          appEnvironment: 'development',
          debug: true,
        ),
        throwsStateError,
      );
    }
  });

  test(
    'HTTPS configurations reject unexpected environment and URL components',
    () {
      for (final env in ['development', 'staging', 'production']) {
        expect(
          () => AppConfig.validateEndpoint(
            url: 'https://example.invalid',
            appEnvironment: env,
            debug: false,
          ),
          returnsNormally,
        );
      }
      expect(
        () => AppConfig.validateEndpoint(
          url: 'https://example.invalid',
          appEnvironment: 'prodution',
          debug: true,
        ),
        throwsStateError,
      );
      for (final url in [
        'https://user:password@example.invalid',
        'https://example.invalid?query=private',
        'https://example.invalid#fragment',
        'https://example.invalid/api/v1',
        'file:///local/path',
        'relative',
      'https://',
      ]) {
        expect(
          () => AppConfig.validateEndpoint(
            url: url,
            appEnvironment: 'production',
            debug: false,
          ),
          throwsStateError,
        );
      }
    },
  );
}
