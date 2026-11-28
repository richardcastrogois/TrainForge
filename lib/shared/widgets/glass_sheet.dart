import 'package:flutter/material.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';

import 'glass_surface.dart';
import 'shell_labels.dart';

/// Panel that rises from the bottom over the page, in frosted glass. It
/// closes by dragging down, by tapping outside or with the close button.
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required String title,
  required List<Widget> children,
  Widget? header,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  showDragHandle: false,
  backgroundColor: Colors.transparent,
  barrierColor: Colors.black.withValues(alpha: .32),
  builder: (sheet) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(30),
        tint: sheet.tf.surface.withValues(alpha: .72),
        blur: 16,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheet).height * .85,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: sheet.tf.outline,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: sheet.tf.ink,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: shellLabel(sheet, 'close'),
                    iconSize: 28,
                    onPressed: () => Navigator.pop(sheet),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              if (header != null) ...[header, const SizedBox(height: 6)],
              const SizedBox(height: 6),
              ...children,
            ],
          ),
        ),
      ),
    ),
  ),
);

/// Big option inside a [showGlassSheet]: round icon, name and one hint line.
class GlassSheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final Color? color;
  final VoidCallback onTap;
  const GlassSheetOption({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: GlassSurface(
      borderRadius: BorderRadius.circular(20),
      tint: context.tf.surface.withValues(alpha: .4),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color ?? context.tf.soft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 26, color: TrainForgeTheme.ink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.tf.ink,
                          ),
                        ),
                        if (hint != null)
                          Text(
                            hint!,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.3,
                              color: context.tf.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: context.tf.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Floating glass squares over the page, just above the bottom bar (no
/// panel behind them). Tapping outside or the system back closes them.
Future<void> showFloatingTiles(
  BuildContext context, {
  required String label,
  required List<GlassTile> tiles,
  double bottom = 0,
}) {
  final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: shellLabel(context, 'close'),
    barrierColor: Colors.black.withValues(alpha: .2),
    transitionDuration: Duration(milliseconds: reduced ? 0 : 220),
    pageBuilder: (menu, _, _) => SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, bottom),
          child: Semantics(
            label: label,
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            // Fingertip-sized squares; they grow a little with the text size
            // setting but never fill the screen.
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, tile) in tiles.indexed) ...[
                  if (i > 0) const SizedBox(width: 12),
                  SizedBox.square(
                    dimension: MediaQuery.textScalerOf(
                      menu,
                    ).scale(76).clamp(76, 96),
                    child: tile,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        alignment: Alignment.bottomCenter,
        scale: Tween(begin: .9, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: child,
      ),
    ),
  );
}

/// Square of clear liquid glass with Apple-style continuous corners
/// (superellipse, no visible start of the curve): a round coloured icon over
/// one or two words, about the size of a fingertip. The corner is about a
/// fifth of the side (16 px on a 76 px square), so it scales with the square.
class GlassTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  const GlassTile({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: title,
    excludeSemantics: true,
    child: AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, box) {
          final side = box.maxWidth;
          final radius = BorderRadius.circular(side * .21);
          return GlassSurface(
            borderRadius: radius,
            // Clear glass: only a hint of white so the words stay readable.
            tint: context.tf.surface.withValues(alpha: .28),
            blur: 16,
            shadows: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: RoundedSuperellipseBorder(borderRadius: radius),
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.all(side * .1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: FittedBox(
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              size: 19,
                              color: TrainForgeTheme.ink,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: side * .05),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          title,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.tf.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// Small glass card that drops from the top right (under the profile
/// picture): a short header and a few one-line links.
Future<void> showTopMenu(
  BuildContext context, {
  required Widget header,
  required List<TopMenuItem> items,
}) {
  final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: shellLabel(context, 'close'),
    barrierColor: Colors.black.withValues(alpha: .18),
    transitionDuration: Duration(milliseconds: reduced ? 0 : 200),
    pageBuilder: (menu, _, _) => SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 78, 16, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: GlassSurface(
              borderRadius: BorderRadius.circular(22),
              tint: menu.tf.surface.withValues(alpha: .78),
              blur: 16,
              shadows: const [
                BoxShadow(
                  color: Color(0x33183e32),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
              child: Material(
                type: MaterialType.transparency,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      Divider(
                        height: 1,
                        color: menu.tf.outline.withValues(alpha: .4),
                      ),
                      for (final item in items)
                        InkWell(
                          onTap: () {
                            Navigator.pop(menu);
                            item.onTap();
                          },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 52),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Icon(item.icon, size: 22, color: menu.tf.ink),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: menu.tf.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
    transitionBuilder: (_, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        alignment: Alignment.topRight,
        scale: Tween(begin: .92, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
  );
}

class TopMenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const TopMenuItem(this.icon, this.title, this.onTap);
}
