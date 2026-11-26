import 'dart:ui';

import 'package:flutter/material.dart';

/// Frosted glass with Flutter's own blur (no extra package): blurs what is
/// behind, then adds a translucent tint and a thin light edge. With high
/// contrast or reduced transparency needs, [tint] can be made opaque.
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
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: highContrast ? tint.withValues(alpha: 1) : tint,
              borderRadius: borderRadius,
              gradient: highContrast
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.alphaBlend(
                          Colors.white.withValues(alpha: .18),
                          tint,
                        ),
                        tint,
                      ],
                    ),
              border: Border.all(
                color: Colors.white.withValues(alpha: .45),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
