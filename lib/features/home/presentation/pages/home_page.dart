//lib/features/home/presentation/pages/home_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/auth/data/auth_repository.dart';
import 'package:trainforge/features/auth/presentation/pages/auth_page.dart';
import 'package:trainforge/features/home/data/home_repository.dart';
import 'package:trainforge/features/home/domain/home_summary.dart';
import 'package:trainforge/features/workouts/presentation/pages/workout_day_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final repository = HomeRepository();
  final authRepository = AuthRepository();

  HomeSummary? summary;
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  String _todayUtcDate() {
    final now = DateTime.now().toUtc();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> loadData() async {
    try {
      final result = await repository.getSummary(_todayUtcDate());

      if (!mounted) return;

      setState(() {
        summary = result;
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
        errorMessage = 'Erro ao carregar a home';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Erro inesperado ao carregar a home';
      });
    }
  }

  Future<void> openTodayWorkout() async {
    final data = summary;

    if (data == null ||
        data.todayWorkoutPlanId == null ||
        data.todayWorkoutId == null ||
        data.isRestDay) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutDayPage(
          workoutPlanId: data.todayWorkoutPlanId!,
          workoutDayId: data.todayWorkoutId!,
        ),
      ),
    );

    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('TrainForge'), centerTitle: true),
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
                    loadData();
                  },
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = summary!;

    return Scaffold(
      appBar: AppBar(title: const Text('TrainForge'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Bem-vindo',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                title: const Text('Streak atual'),
                subtitle: Text('${data.workoutStreak} dias'),
                leading: const Icon(Icons.local_fire_department),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                title: const Text('Treinos iniciados na semana'),
                subtitle: Text('${data.weeklyStarted} iniciados'),
                leading: const Icon(Icons.fitness_center),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                title: const Text('Treinos concluídos na semana'),
                subtitle: Text('${data.weeklyCompleted} concluídos'),
                leading: const Icon(Icons.check_circle_outline),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                title: const Text('Treino de hoje'),
                subtitle: Text(
                  data.todayWorkoutName == null
                      ? 'Nenhum treino para hoje'
                      : data.isRestDay
                      ? '${data.todayWorkoutName} (descanso)'
                      : '${data.todayWorkoutName} • ${data.exercisesCount} exercícios',
                ),
                leading: const Icon(Icons.today),
                trailing: data.todayWorkoutId != null && !data.isRestDay
                    ? const Icon(Icons.chevron_right)
                    : null,
                onTap: data.todayWorkoutId != null && !data.isRestDay
                    ? openTodayWorkout
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: data.todayWorkoutId == null || data.isRestDay
                    ? null
                    : openTodayWorkout,
                child: const Text('Iniciar treino'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
