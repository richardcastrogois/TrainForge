import 'package:trainforge/core/motion/app_motion.dart';
import 'startup_page.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/auth/data/auth_repository.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'package:trainforge/features/auth/presentation/pages/auth_page.dart';
import 'product_shell.dart';

class AuthGate extends StatefulWidget {
  final AuthController? controller;
  final NutritionRepository? nutritionRepository;
  const AuthGate({super.key, this.controller, this.nutritionRepository});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthController controller;
  String? accountId;
  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? AuthController(AuthRepository());
    accountId = controller.profile?.id;
    controller.addListener(accountChanged);
    controller.restore();
  }

  void accountChanged() {
    final next = controller.profile?.id;
    if (next == accountId) return;
    final previous = accountId;
    accountId = next;
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }
  }

  @override
  void dispose() {
    controller.removeListener(accountChanged);
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final profile = controller.profile;
      if (controller.busy && profile == null) {
        return const StartupPage(label: 'Confirmando sua sessão');
      }
      if (profile == null) {
        return AppAppear(
          key: const ValueKey('signed-out'),
          child: AuthPage(controller: controller),
        );
      }
      return AppAppear(
        key: ValueKey(profile.id),
        child: ProductShell(
          key: ValueKey(profile.id),
          controller: controller,
          nutritionRepository: widget.nutritionRepository,
        ),
      );
    },
  );
}
