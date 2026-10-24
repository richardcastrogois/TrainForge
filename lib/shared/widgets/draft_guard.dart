import 'package:flutter/material.dart';
import 'package:trainforge/core/motion/app_motion.dart';

/// Drafts stay only in memory. Leaving never cancels an already sent request.
class DraftGuard extends StatefulWidget {
  final Widget child;
  final bool dirty, busy, uncertain;
  const DraftGuard({
    super.key,
    required this.child,
    required this.dirty,
    required this.busy,
    this.uncertain = false,
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
          widget.uncertain ? 'Conferir antes de sair' : 'Sair sem salvar?',
        ),
        content: Text(
          widget.uncertain
              ? 'A resposta do envio ainda não foi confirmada. Sair não cancela a solicitação. Confira o histórico antes de criar outro registro; para repetir com segurança, permaneça e use a mesma confirmação.'
              : 'As alterações deste formulário ainda não foram salvas. Você pode continuar preenchendo ou descartar somente este rascunho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar preenchendo'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              widget.uncertain
                  ? 'Sair e conferir histórico'
                  : 'Descartar rascunho',
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
    canPop: leaving || (!widget.busy && !widget.dirty && !widget.uncertain),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) ask();
    },
    child: widget.child,
  );
}
