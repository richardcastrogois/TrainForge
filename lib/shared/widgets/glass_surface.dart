import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Liquid glass with a little frost (refraction + light rim + blur), the
/// same material as the bottom bar. With high contrast it becomes an opaque
/// surface of [tint].
class GlassSurface extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final Color tint;
  final double blur;
  final List<BoxShadow> shadows;
  const GlassSurface({
    super.key,
    required this.child,
    required this.borderRadius,
    required this.tint,
    this.blur = 18,
    this.shadows = const [],
  });

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    final radius = borderRadius.topLeft.x;
    if (highContrast) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 1),
          borderRadius: borderRadius,
          boxShadow: shadows,
        ),
        child: child,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
      child: GlassContainer(
        shape: LiquidRoundedSuperellipse(borderRadius: radius),
        useOwnLayer: true,
        quality: GlassQuality.premium,
        settings: LiquidGlassSettings(
          glassColor: tint,
          // Frost scaled down: the old blur values were for a plain blur.
          blur: (blur / 2).clamp(4.0, 12.0),
          thickness: 22,
          refractiveIndex: 1.22,
          lightIntensity: .8,
        ),
        child: child,
      ),
    );
  }
}

/// Big action button in liquid glass tinted with [color]; [foreground] for
/// the icon and text. Keeps a 56 px minimum height.
class LiquidButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color, foreground;
  final VoidCallback? onPressed;
  final double height;
  const LiquidButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.color,
    required this.foreground,
    this.icon,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        child: Opacity(
          opacity: enabled ? 1 : .5,
          child: GlassSurface(
            borderRadius: BorderRadius.circular(20),
            tint: color.withValues(alpha: .9),
            blur: 12,
            shadows: [
              BoxShadow(
                color: color.withValues(alpha: .3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 26, color: foreground),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
