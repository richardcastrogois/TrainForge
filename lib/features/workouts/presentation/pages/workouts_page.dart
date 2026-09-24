//lib/features/workouts/presentation/pages/workouts_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/auth/data/auth_repository.dart';
import 'package:trainforge/features/auth/presentation/pages/auth_page.dart';
import 'package:trainforge/features/onboarding/presentation/pages/onboarding_entry_page.dart';
import 'package:trainforge/features/workouts/data/workouts_repository.dart';
import 'package:trainforge/features/workouts/domain/workout_plan_item.dart';
import 'package:trainforge/features/workouts/presentation/pages/workout_plan_page.dart';

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  final WorkoutsRepository repository = WorkoutsRepository();
  final AuthRepository authRepository = AuthRepository();

  bool loading = true;
  String? errorMessage;
  List<WorkoutPlanItem> plans = [];

  @override
  void initState() {
    super.initState();
    loadPlans();
  }

  String formatDuration(int totalSeconds) {
    final totalMinutes = totalSeconds ~/ 60;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }

    return '$minutes min';
  }

  Future<void> loadPlans() async {
    try {
      final result = await repository.getWorkoutPlans();

      if (!mounted) return;

      setState(() {
        plans = result;
        loading = false;
        errorMessage = null;
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

      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Erro ao carregar treinos';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Erro inesperado ao carregar treinos';
      });
    }
  }

  Future<void> openOnboarding() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const OnboardingEntryPage(initialTrainData: null),
      ),
    );

    await loadPlans();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treinos')),
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
                    });
                    loadPlans();
                  },
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (plans.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treinos'), centerTitle: true),
        body: RefreshIndicator(
          onRefresh: loadPlans,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 120),
              const Icon(Icons.fitness_center, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Você ainda não tem um plano ativo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Crie seu plano agora escolhendo entre modo IA e modo manual.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: openOnboarding,
                child: const Text('Criar plano'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Treinos'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: loadPlans,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ...plans.map(
              (plan) => Card(
                child: ExpansionTile(
                  leading: Icon(
                    plan.isActive ? Icons.check_circle : Icons.circle_outlined,
                  ),
                  title: Text(plan.name),
                  subtitle: Text(
                    plan.isActive ? 'Plano ativo' : 'Plano inativo',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        WorkoutPlanPage(workoutPlanId: plan.id),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('Ver plano completo'),
                            ),
                          ),
                          ...plan.workoutDays.map(
                            (day) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                day.isRest ? Icons.hotel : Icons.fitness_center,
                              ),
                              title: Text(day.name),
                              subtitle: Text(
                                '${day.weekDay} • ${day.isRest ? "Descanso" : "${day.exercises.length} exercícios • ${formatDuration(day.estimatedDurationInSeconds)}"}',
                              ),
                            ),
                          ),
                        ],
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
