//lib/shared/widgets/auth_gate.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/auth/data/auth_repository.dart';
import 'package:trainforge/features/auth/presentation/pages/auth_page.dart';
import 'package:trainforge/features/bootstrap/data/bootstrap_repository.dart';
import 'package:trainforge/features/bootstrap/domain/bootstrap_data.dart';
import 'package:trainforge/features/onboarding/presentation/pages/onboarding_entry_page.dart';
import 'package:trainforge/shared/widgets/app_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthRepository authRepository = AuthRepository();
  final BootstrapRepository bootstrapRepository = BootstrapRepository();

  bool loading = true;
  String? errorMessage;
  Widget? destination;

  @override
  void initState() {
    super.initState();
    checkAppState();
  }

  Future<void> checkAppState() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final token = await authRepository.getSavedToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          loading = false;
          destination = const AuthPage();
        });
        return;
      }

      final BootstrapData bootstrap = await bootstrapRepository.getBootstrap();

      if (!mounted) return;

      setState(() {
        loading = false;
        destination = bootstrap.needsOnboarding
            ? OnboardingEntryPage(initialTrainData: bootstrap.trainData)
            : const AppShell();
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await authRepository.logout();

        if (!mounted) return;

        setState(() {
          loading = false;
          destination = const AuthPage();
        });
        return;
      }

      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Erro ao validar sessão e carregar o app';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Erro inesperado ao iniciar o app';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: checkAppState,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return destination ?? const AuthPage();
  }
}
