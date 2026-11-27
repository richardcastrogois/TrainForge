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
        tint: sheet.tf.surface.withValues(alpha: .86),
        blur: 24,
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
    child: Material(
      color: context.tf.surface.withValues(alpha: .7),
      borderRadius: BorderRadius.circular(20),
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
              tint: menu.tf.surface.withValues(alpha: .9),
              blur: 24,
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
