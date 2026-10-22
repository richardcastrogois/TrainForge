import 'package:trainforge/features/food_reference/presentation/food_page.dart';
import 'package:trainforge/features/catalog/presentation/catalog_page.dart';
import 'package:trainforge/shared/widgets/auth_gate.dart';
import 'package:flutter/material.dart';
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TrainForge',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Entre com sua conta Google para avaliar sua sessão.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: controller.busy ? null : controller.login,
                      icon: const Icon(Icons.login),
                      label: Text(
                        controller.busy ? 'Conectando…' : 'Entrar com Google',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.busy
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const CatalogPage(),
                            ),
                          ),
                    icon: const Icon(Icons.library_books_outlined),
                    label: const Text('Consultar biblioteca sem entrar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.busy
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const FoodPage(),
                            ),
                          ),
                    icon: const Icon(Icons.restaurant_outlined),
                    label: const Text(
                      'Consultar alimentos sem registrar consumo',
                    ),
                  ),
                  if (controller.message != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        controller.message!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (controller.failedAction != null)
                      TextButton(
                        onPressed: controller.busy ? null : controller.retry,
                        child: const Text('Tentar novamente'),
                      ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Versão de avaliação. Outros cenários serão liberados conforme a integração e o conteúdo permitido.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
