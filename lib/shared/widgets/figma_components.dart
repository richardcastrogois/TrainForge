import 'package:trainforge/core/motion/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';

class FigmaContent extends StatelessWidget {
  final String title, subtitle;
  final List<Widget> children;
  const FigmaContent({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });
  @override
  Widget build(BuildContext context) => ListView(
    physics: AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineLarge),
      SizedBox(height: 12),
      Text(
        subtitle,
        style: TextStyle(fontSize: 12, height: 1.35, color: context.tf.muted),
      ),
      SizedBox(height: 12),
      for (final child in children) ...[child, SizedBox(height: 12)],
    ],
  );
}

class FigmaActionCard extends StatelessWidget {
  final String title, subtitle, asset;
  final Color? color;
  final VoidCallback onTap;
  const FigmaActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.onTap,
    this.color,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: color ?? context.tf.surface,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.tf.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox.square(
                dimension: 24,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/figma/card-$asset.svg',
                    excludeFromSemantics: true,
                    colorFilter: Theme.of(context).brightness == Brightness.dark
                        ? ColorFilter.mode(context.tf.primary, BlendMode.srcIn)
                        : null,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: color == null || color == context.tf.surface
                          ? context.tf.muted
                          : context.tf.cardMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class FigmaMetric extends StatelessWidget {
  final String value, label;
  final Color? color;
  const FigmaMetric({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color ?? context.tf.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 11, height: 1.35)),
      ],
    ),
  );
}

/// Preserve the visual affordance while explaining the real, unimplemented capability.
Future<void> showAvailability(
  BuildContext context,
  String title,
  String message,
) => showModalBottomSheet<void>(
  context: context,
  sheetAnimationStyle: AppMotion.style(context),
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 12),
          Text(message),
          SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendi'),
          ),
        ],
      ),
    ),
  ),
);

class FigmaHeader extends StatelessWidget {
  final String? name;
  final VoidCallback? onProfile;
  const FigmaHeader({super.key, this.name, this.onProfile});
  @override
  Widget build(BuildContext context) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? '?'
        : (parts.first.characters.first +
                  (parts.length > 1 ? parts.last.characters.first : ''))
              .toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
      child: Row(
        children: [
          Expanded(child: TrainForgeBrand()),
          SizedBox(width: 10),
          if (name != null)
            SizedBox.square(
              dimension: 48,
              child: Semantics(
                label: 'Abrir perfil',
                button: true,
                onTap: onProfile,
                excludeSemantics: true,
                child: IconButton(
                  tooltip: 'Abrir perfil',
                  onPressed: onProfile,
                  padding: const EdgeInsets.all(4),
                  icon: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.tf.soft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      initials,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.tf.primary,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            SizedBox(height: 48),
        ],
      ),
    );
  }
}

class FigmaBack extends StatelessWidget {
  const FigmaBack({super.key});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size(48, 48),
        alignment: Alignment.centerLeft,
      ),
      onPressed: () => Navigator.maybePop(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/figma/back.svg',
            excludeFromSemantics: true,
            colorFilter: Theme.of(context).brightness == Brightness.dark
                ? ColorFilter.mode(context.tf.primary, BlendMode.srcIn)
                : null,
          ),
          SizedBox(width: 8),
          Text(
            'Voltar',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

class FigmaRouteFrame extends StatelessWidget {
  final Widget body;
  const FigmaRouteFrame({super.key, required this.body});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              FigmaHeader(),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    ),
  );
}

class FigmaPageHeading extends StatelessWidget {
  final String title, subtitle;
  const FigmaPageHeading({
    super.key,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FigmaBack(),
      Text(title, style: Theme.of(context).textTheme.headlineLarge),
      SizedBox(height: 12),
      Text(
        subtitle,
        style: TextStyle(fontSize: 12, height: 1.35, color: context.tf.muted),
      ),
      SizedBox(height: 12),
    ],
  );
}

class FigmaSection extends StatelessWidget {
  final Widget child;
  final Color? color;
  const FigmaSection({super.key, required this.child, this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color ?? context.tf.surface,
      borderRadius: BorderRadius.circular(22),
    ),
    child: child,
  );
}
