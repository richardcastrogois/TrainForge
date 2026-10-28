import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/core/motion/app_motion.dart';

/// Drafts stay only in memory. Leaving never cancels an already sent request.
class DraftGuard extends StatefulWidget {
  final Widget child;
  final bool dirty, busy, uncertain;
  final String? uncertainMessage, uncertainLeaveLabel;
  final VoidCallback? onStepBack;
  const DraftGuard({
    super.key,
    required this.child,
    required this.dirty,
    required this.busy,
    this.uncertain = false,
    this.uncertainMessage,
    this.uncertainLeaveLabel,
    this.onStepBack,
  });
  @override
  State<DraftGuard> createState() => DraftGuardState();
}

class DraftGuardState extends State<DraftGuard> {
  bool leaving = false, asking = false;
  void complete(Object? result) {
    setState(() => leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, result);
    });
  }

  Future<void> ask() async {
    if (asking || widget.busy || leaving) return;
    asking = true;
    FocusManager.instance.primaryFocus?.unfocus();
    final leave = await showDialog<bool>(
      context: context,
      animationStyle: AppMotion.style(context),
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(
          widget.uncertain
              ? context.l10n.checkBeforeLeaving
              : context.l10n.leaveUnsaved,
        ),
        content: Text(
          widget.uncertain
              ? (widget.uncertainMessage ?? context.l10n.uncertainDraftNotice)
              : context.l10n.unsavedDraftNotice,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.continueEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              widget.uncertain
                  ? (widget.uncertainLeaveLabel ??
                        context.l10n.leaveCheckHistory)
                  : context.l10n.discardDraft,
            ),
          ),
        ],
      ),
    );
    asking = false;
    if (mounted && leave == true && !widget.busy) complete(null);
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop:
        leaving ||
        (widget.onStepBack == null &&
            !widget.busy &&
            !widget.dirty &&
            !widget.uncertain),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) {
        if (widget.onStepBack != null && !widget.busy && !widget.uncertain) {
          widget.onStepBack!();
        } else {
          ask();
        }
      }
    },
    child: widget.child,
  );
}
