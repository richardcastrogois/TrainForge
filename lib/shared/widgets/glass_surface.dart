import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Liquid glass like iOS: clear, sharp refraction at the edges and a light
/// rim, almost no blur (what is behind stays readable through it).
///
/// * A strong [tint] (alpha 0.85 or more) is a coloured glass button: the
///   colour is painted solid, so it reads the same over any photo, and the
///   glass adds only the rim and highlights.
/// * With high contrast it becomes an opaque surface of [tint].
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
    final solid = tint.a >= .85;
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
      decoration: BoxDecoration(
        color: solid ? tint.withValues(alpha: 1) : null,
        borderRadius: borderRadius,
        boxShadow: shadows,
      ),
      child: GlassContainer(
        shape: LiquidRoundedSuperellipse(borderRadius: radius),
        useOwnLayer: true,
        quality: GlassQuality.premium,
        settings: solid
            ? colouredGlass
            : LiquidGlassSettings(
                glassColor: tint,
                // A touch of frost only; the old values were a plain blur.
                blur: (blur / 8).clamp(.5, 3.0),
                thickness: 28,
                refractiveIndex: 1.32,
                lightIntensity: .95,
                saturation: 1.15,
              ),
        child: child,
      ),
    );
  }
}

/// Glass over a solid colour: only the rim and highlights show.
const colouredGlass = LiquidGlassSettings(
  glassColor: Color(0x0fffffff),
  blur: 0,
  thickness: 22,
  refractiveIndex: 1.2,
  lightIntensity: 1,
  saturation: 1,
);

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
