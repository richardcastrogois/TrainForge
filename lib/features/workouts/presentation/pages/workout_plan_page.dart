//lib/features/workouts/presentation/pages/workout_plan_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/auth/data/auth_repository.dart';
import 'package:trainforge/features/auth/presentation/pages/auth_page.dart';
import 'package:trainforge/features/workouts/data/workouts_repository.dart';
import 'package:trainforge/features/workouts/domain/workout_plan_detail.dart';
import 'package:trainforge/features/workouts/presentation/pages/workout_day_page.dart';

class WorkoutPlanPage extends StatefulWidget {
  final String workoutPlanId;

  const WorkoutPlanPage({super.key, required this.workoutPlanId});

  @override
  State<WorkoutPlanPage> createState() => _WorkoutPlanPageState();
}

class _WorkoutPlanPageState extends State<WorkoutPlanPage> {
  final WorkoutsRepository repository = WorkoutsRepository();
  final AuthRepository authRepository = AuthRepository();

  bool loading = true;
  String? errorMessage;
  WorkoutPlanDetail? plan;

  @override
  void initState() {
    super.initState();
    loadPlan();
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

  Future<void> loadPlan() async {
    try {
      final result = await repository.getWorkoutPlanDetail(
        widget.workoutPlanId,
      );

      if (!mounted) return;

      setState(() {
        plan = result;
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
        errorMessage = 'Erro ao carregar o plano';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Erro inesperado ao carregar o plano';
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
        appBar: AppBar(title: const Text('Plano de treino')),
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
                    loadPlan();
                  },
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = plan!;

    return Scaffold(
      appBar: AppBar(title: Text(data.name), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: loadPlan,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Dias do plano',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...data.workoutDays.map(
              (day) => Card(
                child: ListTile(
                  leading: Icon(
                    day.isRest ? Icons.hotel : Icons.fitness_center,
                  ),
                  title: Text(day.name),
                  subtitle: Text(
                    '${day.weekDay} • ${day.isRest ? "Descanso" : "${day.exercisesCount} exercícios • ${formatDuration(day.estimatedDurationInSeconds)}"}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WorkoutDayPage(
                          workoutPlanId: data.id,
                          workoutDayId: day.id,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
