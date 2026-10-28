import 'package:flutter/material.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'figma_components.dart';

/// Composition of the existing Figma primitives for additional real data fields.
/// This is not an acceptance claim for an unread Figma frame.
class FlowStatus extends StatelessWidget {
  final String title, message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool announce;
  const FlowStatus({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.announce = true,
  });
  @override
  Widget build(BuildContext context) => FigmaSection(
    child: Semantics(
      liveRegion: announce,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          Text(message),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

class FlowSectionTitle extends StatelessWidget {
  final String title;
  const FlowSectionTitle(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}

class FlowRecord extends StatelessWidget {
  final String title, subtitle;
  final VoidCallback? onTap;
  const FlowRecord({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: MergeSemantics(
      child: Semantics(
        button: true,
        enabled: onTap != null,
        child: Material(
          color: context.tf.surface,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: context.tf.muted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const ExcludeSemantics(child: Icon(Icons.chevron_right)),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
