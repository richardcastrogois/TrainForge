import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/preferences/read_diagnostics.dart';

void main() {
  test(
    'preference diagnostics expose only fixed codes, never platform details',
    () {
      final messages = <String>[];
      final previous = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) messages.add(message);
      };
      addTearDown(() => debugPrint = previous);
      final failures = <Object>[
        TimeoutException('private-timeout-detail'),
        MissingPluginException('private-channel-detail'),
        PlatformException(
          code: 'private-code',
          message: 'private-message',
          details: {'token': 'private-token'},
        ),
        StateError('private-other-detail'),
      ];
      for (final area in PreferenceArea.values) {
        for (final error in failures) {
          reportPreferenceReadFailure(area, error);
        }
      }
      expect(messages, [
        '[PREFERENCES] read_appearance_timeout',
        '[PREFERENCES] read_appearance_missing_channel',
        '[PREFERENCES] read_appearance_platform',
        '[PREFERENCES] read_appearance_other',
        '[PREFERENCES] read_locale_timeout',
        '[PREFERENCES] read_locale_missing_channel',
        '[PREFERENCES] read_locale_platform',
        '[PREFERENCES] read_locale_other',
      ]);
      expect(messages.join(), isNot(contains('private')));
      expect(messages.join(), isNot(contains('token')));
    },
  );
}
