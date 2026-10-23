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
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 12),
      Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          height: 1.35,
          color: TrainForgeTheme.muted,
        ),
      ),
      const SizedBox(height: 12),
      for (final child in children) ...[child, const SizedBox(height: 12)],
    ],
  );
}

class FigmaActionCard extends StatelessWidget {
  final String title, subtitle, asset;
  final Color color;
  final VoidCallback onTap;
  const FigmaActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.onTap,
    this.color = Colors.white,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: color,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox.square(
                dimension: 24,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/figma/card-$asset.svg',
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: TrainForgeTheme.muted,
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
  final Color color;
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
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 11, height: 1.35)),
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
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
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
          const Expanded(child: TrainForgeBrand()),
          const SizedBox(width: 10),
          if (name != null)
            SizedBox.square(
              dimension: 48,
              child: IconButton(
                tooltip: 'Abrir perfil',
                onPressed: onProfile,
                padding: const EdgeInsets.all(4),
                icon: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: TrainForgeTheme.soft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    initials,
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: TrainForgeTheme.primary,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 48),
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
        minimumSize: const Size(48, 48),
        alignment: Alignment.centerLeft,
      ),
      onPressed: () => Navigator.maybePop(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset('assets/figma/back.svg', excludeFromSemantics: true),
          const SizedBox(width: 8),
          const Text(
            'Voltar',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}
