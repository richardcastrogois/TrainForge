import 'package:flutter/material.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/privacy/presentation/privacy_page.dart';
import 'package:trainforge/features/food_reference/presentation/food_page.dart';
import 'package:trainforge/features/catalog/presentation/catalog_page.dart';
import 'package:trainforge/shared/widgets/auth_gate.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import '../auth_controller.dart';

class AuthPage extends StatelessWidget {
  final AuthController? _controller;
  const AuthPage({super.key, AuthController? controller})
    : _controller = controller;
  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const AuthGate();
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                const FigmaHeader(),
                Expanded(
                  child: FigmaContent(
                    title: 'Que bom ter-te por cá.',
                    subtitle: 'Entra para continuar a tua rotina.',
                    children: [
                      OutlinedButton(
                        onPressed: controller.busy ? null : controller.login,
                        child: Text(
                          controller.busy ? 'Conectando…' : 'Entrar com Google',
                        ),
                      ),
                      Material(
                        color: TrainForgeTheme.accent,
                        borderRadius: BorderRadius.circular(22),
                        child: InkWell(
                          onTap: controller.busy ? null : controller.login,
                          borderRadius: BorderRadius.circular(22),
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ainda não tens conta?',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Criar conta com Google',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: TrainForgeTheme.muted,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        'Neste incremento, o acesso é por Google. E-mail e Apple ainda não estão disponíveis.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: TrainForgeTheme.muted,
                        ),
                      ),
                      if (controller.message != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Text(controller.message!),
                        ),
                        if (controller.failedAction != null)
                          TextButton(
                            onPressed: controller.busy
                                ? null
                                : controller.retry,
                            child: const Text('Tentar novamente'),
                          ),
                      ],
                      const Text(
                        'Explorar antes de entrar',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: controller.busy
                            ? null
                            : () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CatalogPage(),
                                ),
                              ),
                        child: const Text('Consultar biblioteca sem entrar'),
                      ),
                      OutlinedButton(
                        onPressed: controller.busy
                            ? null
                            : () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FoodPage(),
                                ),
                              ),
                        child: const Text(
                          'Consultar alimentos sem registrar consumo',
                        ),
                      ),
                      TextButton(
                        onPressed: controller.busy
                            ? null
                            : () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PrivacyPage(),
                                ),
                              ),
                        child: const Text('Privacidade e dados'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
