//lib/features/workouts/presentation/pages/workout_day_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/auth/data/auth_repository.dart';
import 'package:trainforge/features/auth/presentation/pages/auth_page.dart';
import 'package:trainforge/features/workouts/data/workouts_repository.dart';
import 'package:trainforge/features/workouts/domain/workout_day_detail.dart';

class WorkoutDayPage extends StatefulWidget {
  final String workoutPlanId;
  final String workoutDayId;

  const WorkoutDayPage({
    super.key,
    required this.workoutPlanId,
    required this.workoutDayId,
  });

  @override
  State<WorkoutDayPage> createState() => _WorkoutDayPageState();
}

class _WorkoutDayPageState extends State<WorkoutDayPage> {
  final WorkoutsRepository repository = WorkoutsRepository();
  final AuthRepository authRepository = AuthRepository();

  bool loading = true;
  bool actionLoading = false;
  String? errorMessage;
  WorkoutDayDetail? workoutDay;

  @override
  void initState() {
    super.initState();
    loadWorkoutDay();
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

  WorkoutSessionSummary? get activeSession {
    final data = workoutDay;
    if (data == null) return null;

    for (final session in data.sessions) {
      if (session.completedAt == null) {
        return session;
      }
    }

    return null;
  }

  bool get hasCompletedSession {
    final data = workoutDay;
    if (data == null) return false;

    for (final session in data.sessions) {
      if (session.completedAt != null) {
        return true;
      }
    }

    return false;
  }

  Future<void> loadWorkoutDay() async {
    try {
      final result = await repository.getWorkoutDayDetail(
        workoutPlanId: widget.workoutPlanId,
        workoutDayId: widget.workoutDayId,
      );

      if (!mounted) return;

      setState(() {
        workoutDay = result;
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
        errorMessage = 'Erro ao carregar o dia de treino';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Erro inesperado ao carregar o dia de treino';
      });
    }
  }

  Future<void> handleStartWorkout() async {
    setState(() {
      actionLoading = true;
    });

    try {
      await repository.startWorkoutSession(
        workoutPlanId: widget.workoutPlanId,
        workoutDayId: widget.workoutDayId,
      );

      await loadWorkoutDay();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino iniciado com sucesso')),
      );
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

      String message = 'Erro ao iniciar treino';

      if (e.response?.statusCode == 409) {
        message = 'Já existe uma sessão iniciada para este treino';
      } else if (e.response?.statusCode == 422) {
        message = 'Este plano não está ativo';
      } else if (e.response?.statusCode == 404) {
        message = 'Treino não encontrado';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro inesperado ao iniciar treino')),
      );
    } finally {
      if (mounted) {
        setState(() {
          actionLoading = false;
        });
      }
    }
  }

  Future<void> handleFinishWorkout() async {
    final session = activeSession;
    if (session == null) return;

    setState(() {
      actionLoading = true;
    });

    try {
      await repository.finishWorkoutSession(
        workoutPlanId: widget.workoutPlanId,
        workoutDayId: widget.workoutDayId,
        sessionId: session.id,
        completedAt: DateTime.now().toUtc().toIso8601String(),
      );

      await loadWorkoutDay();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino finalizado com sucesso')),
      );
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

      String message = 'Erro ao finalizar treino';

      if (e.response?.statusCode == 404) {
        message = 'Sessão não encontrada';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro inesperado ao finalizar treino')),
      );
    } finally {
      if (mounted) {
        setState(() {
          actionLoading = false;
        });
      }
    }
  }

  Widget buildActionSection(WorkoutDayDetail data) {
    if (data.isRest) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.hotel),
          title: Text('Dia de descanso'),
          subtitle: Text('Não há sessão para iniciar neste dia'),
        ),
      );
    }

    if (activeSession != null) {
      return Column(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.play_circle_fill),
              title: const Text('Treino em andamento'),
              subtitle: Text('Sessão ativa: ${activeSession!.id}'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: actionLoading ? null : handleFinishWorkout,
              child: Text(
                actionLoading ? 'Finalizando...' : 'Marcar como concluído',
              ),
            ),
          ),
        ],
      );
    }

    if (hasCompletedSession) {
      return Column(
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.check_circle),
              title: Text('Treino já concluído'),
              subtitle: Text('Este dia já possui uma sessão finalizada'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              child: const Text('Treino concluído'),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: actionLoading ? null : handleStartWorkout,
        child: Text(actionLoading ? 'Iniciando...' : 'Iniciar treino'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dia de treino')),
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
                    loadWorkoutDay();
                  },
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = workoutDay!;

    return Scaffold(
      appBar: AppBar(title: Text(data.name), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: loadWorkoutDay,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Dia da semana'),
                subtitle: Text(data.weekDay),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Duração estimada'),
                subtitle: Text(formatDuration(data.estimatedDurationInSeconds)),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Sessões registradas'),
                subtitle: Text('${data.sessions.length} sessão(ões)'),
              ),
            ),
            const SizedBox(height: 20),
            if (!data.isRest) ...[
              const Text(
                'Exercícios',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...data.exercises.map(
                (exercise) => Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${exercise.order}')),
                    title: Text(exercise.name),
                    subtitle: Text(
                      '${exercise.sets} séries • ${exercise.reps} reps • descanso ${exercise.restTimeInSeconds}s',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            buildActionSection(data),
          ],
        ),
      ),
    );
  }
}
