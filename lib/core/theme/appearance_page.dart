import 'package:trainforge/core/l10n/feedback_localization.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/core/theme/appearance_controller.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = AppearanceScope.maybeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.appearance)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              context.l10n.appearanceTitle,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            Text(context.l10n.appearanceIntro),
            const SizedBox(height: 20),
            if (controller == null)
              Text(context.l10n.appearanceUnavailable)
            else ...[
              RadioGroup<ThemeMode>(
                groupValue: controller.mode,
                onChanged: (value) {
                  if (value != null &&
                      !controller.saving &&
                      !controller.reading) {
                    controller.select(value);
                  }
                },
                child: Column(
                  children: [
                    for (final item in [
                      (
                        ThemeMode.system,
                        context.l10n.themeSystem,
                        context.l10n.themeSystemHint,
                      ),
                      (
                        ThemeMode.light,
                        context.l10n.light,
                        context.l10n.lightHint,
                      ),
                      (
                        ThemeMode.dark,
                        context.l10n.dark,
                        context.l10n.darkHint,
                      ),
                    ])
                      Card(
                        child: RadioListTile<ThemeMode>(
                          value: item.$1,
                          enabled: !controller.saving && !controller.reading,
                          title: Text(item.$2),
                          subtitle: Text(item.$3),
                        ),
                      ),
                  ],
                ),
              ),
              if (controller.saving)
                AppProgress(label: context.l10n.savingAppearance),
              if (controller.reading)
                AppProgress(label: context.l10n.readingPreferences),
              if (controller.message != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(controller.feedback!.localized(context)),
                ),
                TextButton(
                  onPressed: controller.saving || controller.reading
                      ? null
                      : controller.retry,
                  child: Text(
                    controller.readFailed
                        ? context.l10n.retryReadPreference
                        : context.l10n.retrySave,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 20),
            Text(context.l10n.accessibilityDevice),
          ],
        ),
      ),
    );
  }
}
