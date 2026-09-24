//lib/features/onboarding/presentation/pages/onboarding_entry_page.dart
import 'package:flutter/material.dart';
import 'package:trainforge/features/auth/data/auth_repository.dart';
import 'package:trainforge/features/auth/presentation/pages/auth_page.dart';
import 'package:trainforge/features/onboarding/presentation/pages/ai_onboarding_page.dart';
import 'package:trainforge/features/onboarding/presentation/pages/manual_onboarding_page.dart';
import 'package:trainforge/features/profile/domain/profile_data.dart';

class OnboardingEntryPage extends StatelessWidget {
  final TrainData? initialTrainData;

  const OnboardingEntryPage({super.key, required this.initialTrainData});

  Future<void> _logout(BuildContext context) async {
    final authRepository = AuthRepository();
    await authRepository.logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar plano'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Vamos montar seu plano',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Escolha como você quer criar seu treino inicial. '
              'O modo IA usa uma única requisição consolidada. '
              'O modo manual monta seu plano sem IA.',
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      'Montar com IA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Você preenche os dados uma vez e o backend cria o plano com IA.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AiOnboardingPage(
                                initialTrainData: initialTrainData,
                              ),
                            ),
                          );
                        },
                        child: const Text('Usar IA'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tune, size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      'Montar manualmente',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Você escolhe objetivo, frequência e nível. O app cria um plano sem IA.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ManualOnboardingPage(
                                initialTrainData: initialTrainData,
                              ),
                            ),
                          );
                        },
                        child: const Text('Montar manualmente'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
