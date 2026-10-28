import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/flow_components.dart';
import '../domain/training_configuration.dart';
import 'training_configuration_controller.dart';

String configWeekday(BuildContext context, int day) => [
  context.l10n.configMonday,
  context.l10n.configTuesday,
  context.l10n.configWednesday,
  context.l10n.configThursday,
  context.l10n.configFriday,
  context.l10n.configSaturday,
  context.l10n.configSunday,
][day - 1];
String configPlace(BuildContext context, String place) => switch (place) {
  'home' => context.l10n.configHome,
  'park' => context.l10n.configPark,
  _ => context.l10n.configGym,
};
String configResourceStatus(BuildContext context, String? status) =>
    switch (status) {
      'declared' => context.l10n.configDeclared,
      'none' => context.l10n.configNone,
      _ => context.l10n.configUnknown,
    };

/// Step content uses the existing visual primitives; the controller owns the draft.
class TrainingConfigurationSections extends StatelessWidget {
  final TrainingConfigurationController controller;
  final int step;
  final ValueChanged<int> edit;
  const TrainingConfigurationSections({
    super.key,
    required this.controller,
    required this.step,
    required this.edit,
  });
  TrainingDraft get d => controller.draft;
  bool get enabled => controller.editable;
  bool invalid(String path) => [
    ...d.validate().keys,
    ...controller.issues.keys,
  ].any((key) => key == path || key.startsWith('$path.'));
  Widget group(String path, String message, Widget child) => FormField<void>(
    key: ValueKey(path),
    validator: (_) => invalid(path) ? message : null,
    builder: (state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        if (state.hasError)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                state.errorText!,
                style: TextStyle(
                  color: Theme.of(state.context).colorScheme.error,
                ),
              ),
            ),
          ),
      ],
    ),
  );
  void resourceStatus(String? value) {
    if (value == null) return;
    controller.update((d) {
      d.resourceStatus = value;
      if (value != 'declared') d.resources.clear();
    });
    if (value == 'declared') controller.loadOptions();
  }

  Widget places(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FlowSectionTitle(context.l10n.configWhere),
      group(
        'configuration.environments',
        context.l10n.configChoosePlace,
        Column(
          children: [
            for (final place in ['home', 'park', 'gym'])
              CheckboxListTile(
                key: ValueKey('place-$place'),
                contentPadding: EdgeInsets.zero,
                title: Text(configPlace(context, place)),
                value: d.environments.contains(place),
                onChanged: !enabled
                    ? null
                    : (checked) => controller.update((d) {
                        if (checked == true) {
                          d.environments.add(place);
                        } else {
                          d.environments.remove(place);
                        }
                      }),
              ),
          ],
        ),
      ),
      FlowSectionTitle(context.l10n.configContext),
      group(
        'configuration.context',
        context.l10n.configChooseContext,
        RadioGroup<String>(
          groupValue: d.context,
          onChanged: enabled
              ? (value) => controller.update((d) => d.context = value)
              : (_) {},
          child: Column(
            children: [
              RadioListTile<String>(
                key: const Key('context-personal'),
                enabled: enabled,
                contentPadding: EdgeInsets.zero,
                value: 'personal',
                title: Text(context.l10n.configPersonal),
              ),
              RadioListTile<String>(
                key: const Key('context-caregiver'),
                enabled: enabled,
                contentPadding: EdgeInsets.zero,
                value: 'caregiver_break',
                title: Text(context.l10n.configCaregiver),
                subtitle: Text(context.l10n.configCaregiverHint),
              ),
            ],
          ),
        ),
      ),
    ],
  );
  Widget resources(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(context.l10n.configEquipmentHint),
      const SizedBox(height: 12),
      group(
        'configuration.resources.status',
        context.l10n.configChooseStatus,
        RadioGroup<String>(
          groupValue: d.resourceStatus,
          onChanged: enabled ? resourceStatus : (_) {},
          child: Column(
            children: [
              for (final status in ['declared', 'none', 'unknown'])
                RadioListTile<String>(
                  key: ValueKey('resources-$status'),
                  enabled: enabled,
                  value: status,
                  contentPadding: EdgeInsets.zero,
                  title: Text(configResourceStatus(context, status)),
                ),
            ],
          ),
        ),
      ),
      if (d.resourceStatus == 'declared') ...[
        group(
          'configuration.resources.items',
          context.l10n.configChooseResource,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (d.resources.isNotEmpty) ...[
                FlowSectionTitle(context.l10n.configSelected),
                for (final ref in d.resources.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      controller.labels[ref.key]?.name ??
                          context.l10n.configResourceWithdrawn,
                    ),
                    subtitle: Text(
                      controller.labels[ref.key]?.source ?? ref.sourceId,
                    ),
                    trailing: IconButton(
                      tooltip: context.l10n.discardDraft,
                      onPressed: !enabled
                          ? null
                          : () => controller.update(
                              (d) => d.resources.remove(ref.key),
                            ),
                      icon: const Icon(Icons.close),
                    ),
                  ),
              ],
              if (d.resources.keys.any(controller.unavailable.contains))
                Semantics(
                  liveRegion: true,
                  child: Text(context.l10n.configResourceWithdrawn),
                ),
              TextFormField(
                key: const Key('resource-search'),
                enabled: enabled,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: context.l10n.searchOriginal,
                ),
                onChanged: controller.search,
              ),
              if (controller.optionsLoading)
                AppProgress(label: context.l10n.loadingQuery)
              else if (controller.options.isEmpty &&
                  controller.optionsError == null)
                Text(context.l10n.configNoResources),
              for (final option in controller.options)
                CheckboxListTile(
                  key: ValueKey('option-${option.reference.key}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(option.name),
                  subtitle: Text(option.source),
                  value: d.resources.containsKey(option.reference.key),
                  onChanged:
                      !enabled ||
                          (!d.resources.containsKey(option.reference.key) &&
                              d.resources.length >= 32)
                      ? null
                      : (value) => controller.update((d) {
                          if (value == true) {
                            d.resources[option.reference.key] =
                                option.reference;
                          } else {
                            d.resources.remove(option.reference.key);
                          }
                        }),
                ),
              if (controller.optionsError != null)
                FlowStatus(
                  title: context.l10n.queryUnavailable,
                  message: context.l10n.configUnavailable,
                  actionLabel: context.l10n.retry,
                  onAction: () =>
                      controller.loadOptions(more: controller.cursor != null),
                ),
              if (controller.moreBusy)
                AppProgress(label: context.l10n.loadingQuery)
              else if (controller.cursor != null &&
                  controller.optionsError == null)
                OutlinedButton(
                  onPressed: () => controller.loadOptions(more: true),
                  child: Text(context.l10n.loadMore),
                ),
            ],
          ),
        ),
      ],
    ],
  );
  Future<void> pickStart(BuildContext context, AvailabilityDraft slot) async {
    // The initial picker position is not a declared time until the user confirms it.
    final old = slot.start?.split(':');
    final now = TimeOfDay.now();
    final time = await showTimePicker(
      context: context,
      initialTime: old == null
          ? now
          : TimeOfDay(hour: int.parse(old[0]), minute: int.parse(old[1])),
    );
    if (time != null && controller.active) {
      controller.update(
        (d) => slot.start =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  Widget availability(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        key: const Key('config-timezone'),
        initialValue: d.timezone,
        enabled: enabled,
        maxLength: 80,
        autocorrect: false,
        decoration: InputDecoration(labelText: context.l10n.configTimezone),
        validator: (_) => invalid('configuration.timezone')
            ? context.l10n.configInvalidTimezone
            : null,
        onChanged: (v) => controller.update((d) => d.timezone = v),
      ),
      Text(context.l10n.configTimezoneHint),
      const SizedBox(height: 16),
      Text(context.l10n.configAvailabilityHint),
      group(
        'configuration.availability',
        context.l10n.configInvalidSlot,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < d.availability.length; i++)
              slot(context, d.availability[i], i),
            OutlinedButton.icon(
              key: const Key('add-availability'),
              onPressed: !enabled || d.availability.length >= 28
                  ? null
                  : () => controller.update(
                      (d) =>
                          d.availability.add(AvailabilityDraft(id: d.nextId++)),
                    ),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.configAddSlot),
            ),
          ],
        ),
      ),
    ],
  );
  Widget slot(BuildContext context, AvailabilityDraft a, int index) {
    final field = 'configuration.availability.$index';
    return Padding(
      key: ValueKey('slot-${a.id}'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: FigmaSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              key: ValueKey('day-${a.id}'),
              initialValue: a.weekday,
              isExpanded: true,
              itemHeight: null,
              decoration: InputDecoration(labelText: context.l10n.configDay),
              items: [
                for (var day = 1; day <= 7; day++)
                  DropdownMenuItem(
                    value: day,
                    child: Text(configWeekday(context, day)),
                  ),
              ],
              onChanged: !enabled
                  ? null
                  : (value) => controller.update((d) => a.weekday = value),
              validator: (_) => invalid('$field.weekday')
                  ? context.l10n.configChooseDay
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('minutes-${a.id}'),
              initialValue: a.minutes,
              enabled: enabled,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 4,
              decoration: InputDecoration(
                labelText: context.l10n.configMinutes,
              ),
              onChanged: (v) => controller.update((d) => a.minutes = v),
              validator: (_) => invalid('$field.minutesAvailable')
                  ? context.l10n.configInvalidMinutes
                  : null,
            ),
            Text(context.l10n.configStart),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: !enabled ? null : () => pickStart(context, a),
              child: Text(a.start ?? context.l10n.configUnfixed),
            ),
            if (a.start != null)
              TextButton(
                onPressed: !enabled
                    ? null
                    : () => controller.update((d) => a.start = null),
                child: Text(context.l10n.configUnfixed),
              ),
            TextButton.icon(
              onPressed: !enabled || d.availability.length == 1
                  ? null
                  : () => controller.update(
                      (d) => d.availability.removeWhere((v) => v.id == a.id),
                    ),
              icon: const Icon(Icons.remove_circle_outline),
              label: Text(context.l10n.configRemoveSlot),
            ),
          ],
        ),
      ),
    );
  }

  Widget reviewSection(
    BuildContext context,
    String title,
    int target,
    List<Widget> children,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: FigmaSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FlowSectionTitle(title),
          ...children,
          TextButton(
            onPressed: !enabled ? null : () => edit(target),
            child: Text(context.l10n.configEdit),
          ),
        ],
      ),
    ),
  );
  Widget review(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      reviewSection(context, context.l10n.configPlaces, 0, [
        for (final place in d.environments) Text(configPlace(context, place)),
        const SizedBox(height: 8),
        Text(
          d.context == 'caregiver_break'
              ? context.l10n.configCaregiver
              : context.l10n.configPersonal,
        ),
      ]),
      reviewSection(context, context.l10n.configResources, 1, [
        Text(configResourceStatus(context, d.resourceStatus)),
        for (final ref in d.resources.values)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  controller.labels[ref.key]?.name ??
                      context.l10n.configResourceWithdrawn,
                ),
                Text(controller.labels[ref.key]?.source ?? ref.sourceId),
              ],
            ),
          ),
      ]),
      reviewSection(context, context.l10n.configAvailability, 2, [
        Text(d.timezone),
        for (final a in d.availability)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${configWeekday(context, a.weekday!)} · ${a.minutes} min · ${a.start ?? context.l10n.configUnfixed}',
            ),
          ),
      ]),
    ],
  );
  @override
  Widget build(BuildContext context) => switch (step) {
    0 => places(context),
    1 => resources(context),
    2 => availability(context),
    _ => review(context),
  };
}
