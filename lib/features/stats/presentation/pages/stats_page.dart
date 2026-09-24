//lib/features/stats/presentation/pages/stats_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/auth/data/auth_repository.dart';
import 'package:trainforge/features/auth/presentation/pages/auth_page.dart';
import 'package:trainforge/features/onboarding/presentation/pages/onboarding_entry_page.dart';
import 'package:trainforge/features/stats/data/stats_repository.dart';
import 'package:trainforge/features/stats/domain/stats_data.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final StatsRepository repository = StatsRepository();
  final AuthRepository authRepository = AuthRepository();

  bool loading = true;
  String? errorMessage;
  bool noActivePlan = false;
  StatsData? stats;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> loadStats() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 0);

    try {
      final result = await repository.getStats(
        from: _formatDate(from),
        to: _formatDate(to),
      );

      if (!mounted) return;

      setState(() {
        stats = result;
        loading = false;
        errorMessage = null;
        noActivePlan = false;
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await authRepository.logout();

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthPage()),
          (route) => false,
        );
        return;
      }

      if (e.response?.statusCode == 404) {
        if (!mounted) return;

        setState(() {
          loading = false;
          errorMessage = null;
          noActivePlan = true;
        });
        return;
      }

      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Erro ao carregar estatísticas';
        noActivePlan = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Erro inesperado ao carregar estatísticas';
        noActivePlan = false;
      });
    }
  }

  String _labelForDay(DailyConsistency day) {
    if (day.workoutDayCompleted) {
      return 'Concluído';
    }

    if (day.workoutDayStarted) {
      return 'Iniciado';
    }

    return 'Sem treino';
  }

  IconData _iconForDay(DailyConsistency day) {
    if (day.workoutDayCompleted) {
      return Icons.check_circle;
    }

    if (day.workoutDayStarted) {
      return Icons.play_circle_outline;
    }

    return Icons.remove_circle_outline;
  }

  Future<void> _openOnboarding() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const OnboardingEntryPage(initialTrainData: null),
      ),
    );

    await loadStats();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (noActivePlan) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stats'), centerTitle: true),
        body: RefreshIndicator(
          onRefresh: loadStats,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 120),
              const Icon(Icons.bar_chart, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Nenhum plano ativo encontrado',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Crie seu plano para começar a visualizar suas estatísticas.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _openOnboarding,
                child: const Text('Criar plano'),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stats')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      loading = true;
                      errorMessage = null;
                      noActivePlan = false;
                    });
                    loadStats();
                  },
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = stats!;

    return Scaffold(
      appBar: AppBar(title: const Text('Stats'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: loadStats,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_fire_department),
                title: const Text('Streak atual'),
                subtitle: Text('${data.workoutStreak} dias'),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Treinos concluídos'),
                subtitle: Text('${data.completedWorkoutsCount} no período'),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.percent),
                title: const Text('Taxa de conclusão'),
                subtitle: Text(data.formattedConclusionRate),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Tempo total treinado'),
                subtitle: Text(data.formattedTotalTime),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Consistência por dia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (data.consistency.isEmpty)
              const Card(child: ListTile(title: Text('Nenhum dado no período')))
            else
              ...data.consistency.map(
                (day) => Card(
                  child: ListTile(
                    leading: Icon(_iconForDay(day)),
                    title: Text(day.date),
                    subtitle: Text(_labelForDay(day)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
