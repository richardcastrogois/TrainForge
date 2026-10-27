import 'package:flutter/material.dart';
import 'locale_controller.dart';
import 'localized_context.dart';
import '../../shared/widgets/app_loading.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = LocaleScope.maybeOf(context);
    final strings = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(strings.language)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              strings.languageIntro,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(strings.languageScope),
            const SizedBox(height: 20),
            if (controller == null)
              Text(strings.languageUnavailable)
            else ...[
              RadioGroup<LanguageChoice>(
                groupValue: controller.choice,
                onChanged: (value) {
                  if (value != null && !controller.reading) {
                    controller.select(value);
                  }
                },
                child: Column(
                  children: [
                    for (final item in [
                      (LanguageChoice.system, strings.followDevice),
                      (LanguageChoice.portugueseBrazil, 'Português (Brasil)'),
                      (
                        LanguageChoice.portuguesePortugal,
                        'Português (Portugal)',
                      ),
                      (LanguageChoice.english, 'English'),
                      (LanguageChoice.spanish, 'Español'),
                    ])
                      Card(
                        child: RadioListTile<LanguageChoice>(
                          value: item.$1,
                          enabled: !controller.saving && !controller.reading,
                          title: Text(item.$2),
                        ),
                      ),
                  ],
                ),
              ),
              if (controller.saving) AppProgress(label: strings.savingLanguage),
              if (controller.reading)
                AppProgress(label: strings.readingPreferences),
              if (controller.issue != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(switch (controller.issue!) {
                    LocaleIssue.readFallback => strings.languageFallback,
                    LocaleIssue.saveFailed => strings.languageSaveFailed,
                    LocaleIssue.saveUncertain => strings.languageSaveUncertain,
                  }),
                ),
                TextButton(
                  onPressed: controller.saving || controller.reading
                      ? null
                      : controller.retry,
                  child: Text(
                    controller.readFailed
                        ? strings.retryReadPreference
                        : strings.retrySave,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 20),
            Text(strings.contentOriginal),
            const SizedBox(height: 12),
            Text(strings.languageProgress),
          ],
        ),
      ),
    );
  }
}
