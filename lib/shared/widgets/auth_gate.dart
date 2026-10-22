import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/auth/data/auth_repository.dart';
import 'package:trainforge/features/auth/presentation/pages/auth_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final repository = AuthRepository();
  bool loading = true;
  bool signedIn = false;
  String? errorMessage;
  Map<String, dynamic>? user;
  @override
  void initState() {
    super.initState();
    checkSession();
  }

  Future<void> checkSession() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final authenticated = await repository.isAuthenticated();
      final profile = authenticated ? await repository.getMe() : null;
      if (!mounted) return;
      setState(() {
        signedIn = authenticated;
        user = profile;
        loading = false;
      });
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage =
            'Não foi possível confirmar a sessão. Confira sua conexão e tente novamente.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage =
            'Não foi possível acessar a sessão armazenada. Tente novamente.';
      });
    }
  }

  Future<void> logout() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      await repository.logout();
      if (!mounted) return;
      setState(() {
        signedIn = false;
        user = null;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage =
            'A saída não foi confirmada pelo servidor. Conecte-se e tente novamente.';
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
                  onPressed: checkSession,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!signedIn) return const AuthPage();
    // The Go checkpoint never invokes legacy bootstrap, generators or fake data.
    return Scaffold(
      appBar: AppBar(title: const Text('TrainForge · avaliação')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Conta conectada',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(user?['name'] as String? ?? ''),
          Text(user?['email'] as String? ?? ''),
          const SizedBox(height: 24),
          const Text(
            'Neste incremento: autenticação Google, confirmação da conta, renovação e saída da sessão.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Biblioteca, atividades, histórico e alimentação ainda não estão integrados à nova API. Nenhum treino ou dado pessoal foi preenchido automaticamente.',
          ),
          const SizedBox(height: 16),
          const Text(
            'A cobertura continua incluindo idosos, cuidadores, casa, praça e academia. Os cenários serão liberados em próximos incrementos conforme conteúdo e requisitos reais.',
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: checkSession,
            child: const Text('Confirmar conexão'),
          ),
          ElevatedButton(
            onPressed: logout,
            child: const Text('Sair desta sessão'),
          ),
        ],
      ),
    );
  }
}
