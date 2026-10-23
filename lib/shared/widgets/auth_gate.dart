import 'package:trainforge/features/privacy/presentation/privacy_page.dart';
import 'package:trainforge/features/food_reference/presentation/food_page.dart';
import 'package:trainforge/features/catalog/presentation/catalog_page.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/auth/data/auth_repository.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'package:trainforge/features/auth/presentation/pages/auth_page.dart';

class AuthGate extends StatefulWidget {
  final AuthController? controller;
  const AuthGate({super.key, this.controller});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthController controller;
  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? AuthController(AuthRepository());
    controller.restore();
  }

  @override
  void dispose() {
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (controller.busy) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Confirmando sessão',
            ),
          ),
        );
      }
      final profile = controller.profile;
      if (profile == null) return AuthPage(controller: controller);
      return Scaffold(
        appBar: AppBar(title: const Text('TrainForge · avaliação')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Conta conectada',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(profile.name),
              Text(profile.email),
              const SizedBox(height: 24),
              const Text(
                'Neste incremento: autenticação Google, confirmação da conta, renovação e saída da sessão.',
              ),
              const SizedBox(height: 16),
              const Text(
                'A biblioteca de referência está disponível para consulta. A composição alimentar também pode ser consultada. Atividades, histórico e registros de consumo continuam pendentes. Nenhum treino ou dado pessoal foi preenchido automaticamente.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Idosos, cuidadores, casa, praça e academia continuam na cobertura. Os cenários serão liberados conforme requisitos e conteúdo reais.',
              ),
              if (controller.message != null) ...[
                const SizedBox(height: 16),
                Semantics(liveRegion: true, child: Text(controller.message!)),
                TextButton(
                  onPressed: controller.retry,
                  child: const Text('Tentar novamente'),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const CatalogPage()),
                ),
                icon: const Icon(Icons.library_books_outlined),
                label: const Text('Consultar biblioteca'),
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
                label: const Text('Consultar alimentos sem registrar consumo'),
              ),
              OutlinedButton(
                onPressed: controller.busy
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => PrivacyPage(
                            authenticated: true,
                            reauthenticate: () async {
                              await controller.login();
                              if (controller.message != null) {
                                throw StateError('Confirmação indisponível');
                              }
                            },
                            currentAccountId: () => controller.profile?.id,
                            onDeleted: (erasedId) async {
                              controller.accountErased(erasedId);
                              await controller.restore();
                            },
                          ),
                        ),
                      ),
                child: const Text('Meus dados e privacidade'),
              ),
              OutlinedButton(
                onPressed: controller.restore,
                child: const Text('Confirmar conexão'),
              ),
              FilledButton(
                onPressed: controller.logout,
                child: const Text('Sair desta sessão'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
