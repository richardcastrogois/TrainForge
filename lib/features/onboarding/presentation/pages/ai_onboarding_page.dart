//lib/features/onboarding/presentation/pages/ai_onboarding_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/auth/data/auth_repository.dart';
import 'package:trainforge/features/auth/presentation/pages/auth_page.dart';
import 'package:trainforge/features/onboarding/data/onboarding_repository.dart';
import 'package:trainforge/features/profile/domain/profile_data.dart';
import 'package:trainforge/shared/widgets/auth_gate.dart';

class AiOnboardingPage extends StatefulWidget {
  final TrainData? initialTrainData;

  const AiOnboardingPage({super.key, required this.initialTrainData});

  @override
  State<AiOnboardingPage> createState() => _AiOnboardingPageState();
}

class _AiOnboardingPageState extends State<AiOnboardingPage> {
  final OnboardingRepository repository = OnboardingRepository();
  final AuthRepository authRepository = AuthRepository();

  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final ageController = TextEditingController();
  final bodyFatController = TextEditingController();
  final restrictionsController = TextEditingController();

  bool saving = false;

  String goal = 'hypertrophy';
  int daysPerWeek = 4;
  String experienceLevel = 'beginner';
  int sessionDurationInMinutes = 60;

  @override
  void initState() {
    super.initState();

    final data = widget.initialTrainData;
    if (data != null) {
      weightController.text = data.weightInKg.toStringAsFixed(1);
      heightController.text = data.heightInCentimeters.toString();
      ageController.text = data.age.toString();
      bodyFatController.text = data.bodyFatPercentage.toString();
    }
  }

  @override
  void dispose() {
    weightController.dispose();
    heightController.dispose();
    ageController.dispose();
    bodyFatController.dispose();
    restrictionsController.dispose();
    super.dispose();
  }

  Future<void> _goToAuth() async {
    await authRepository.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (route) => false,
    );
  }

  Future<void> _goToApp() async {
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  int? _parseInt(String value) => int.tryParse(value.trim());

  double? _parseDouble(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  Future<void> _showResultDialog({
    required String title,
    required String message,
    bool allowRetryLater = true,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (allowRetryLater)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();

                  if (mounted) {
                    Navigator.of(context).maybePop();
                  }
                },
                child: const Text('Voltar'),
              ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(allowRetryLater ? 'Ficar aqui' : 'Entendi'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    if (saving) return;

    FocusScope.of(context).unfocus();

    final weightKg = _parseDouble(weightController.text);
    final height = _parseInt(heightController.text);
    final age = _parseInt(ageController.text);
    final bodyFat = _parseInt(bodyFatController.text);

    if (weightKg == null || height == null || age == null || bodyFat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos com valores válidos'),
        ),
      );
      return;
    }

    if (weightKg <= 0 ||
        height <= 0 ||
        age <= 0 ||
        bodyFat < 0 ||
        bodyFat > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Existem valores fora do intervalo permitido'),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await repository.createAiPlan(
        weightInGrams: (weightKg * 1000).round(),
        heightInCentimeters: height,
        age: age,
        bodyFatPercentage: bodyFat,
        goal: goal,
        daysPerWeek: daysPerWeek,
        experienceLevel: experienceLevel,
        sessionDurationInMinutes: sessionDurationInMinutes,
        restrictions: restrictionsController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plano criado com IA com sucesso')),
      );

      await _goToApp();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _goToAuth();
        return;
      }

      if (!mounted) return;

      final statusCode = e.response?.statusCode;
      final isTimeout =
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout;

      if (statusCode == 409) {
        await _showResultDialog(
          title: 'Criação já em andamento',
          message:
              'Já existe uma criação de plano acontecendo para sua conta. Aguarde um pouco e tente novamente depois.',
        );
        return;
      }

      if (isTimeout) {
        await _showResultDialog(
          title: 'A criação está demorando mais que o esperado',
          message:
              'A IA pode ainda estar processando seu plano. Você pode voltar agora e tentar novamente depois.',
        );
        return;
      }

      await _showResultDialog(
        title: 'Não foi possível criar seu plano',
        message:
            'Ocorreu um erro ao criar o plano com IA. Você pode voltar agora e tentar novamente depois.',
      );
    } catch (_) {
      if (!mounted) return;

      await _showResultDialog(
        title: 'Erro inesperado',
        message:
            'Ocorreu um erro inesperado ao criar o plano com IA. Você pode voltar agora e tentar novamente depois.',
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool decimal = false,
  }) {
    return TextField(
      controller: controller,
      enabled: !saving,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSavingOverlay() {
    if (!saving) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: Container(
            width: 320,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(),
                ),
                SizedBox(height: 20),
                Text(
                  'Criando seu plano com IA',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Isso pode levar alguns segundos. Aguarde sem sair desta tela.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Plano com IA'),
          centerTitle: true,
          automaticallyImplyLeading: !saving,
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Preencha os dados abaixo. O app vai enviar uma única requisição consolidada para a IA.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                _buildNumberField(
                  label: 'Peso (kg)',
                  controller: weightController,
                  hint: 'Ex: 82.5',
                  decimal: true,
                ),
                const SizedBox(height: 12),
                _buildNumberField(
                  label: 'Altura (cm)',
                  controller: heightController,
                  hint: 'Ex: 178',
                ),
                const SizedBox(height: 12),
                _buildNumberField(
                  label: 'Idade',
                  controller: ageController,
                  hint: 'Ex: 25',
                ),
                const SizedBox(height: 12),
                _buildNumberField(
                  label: 'Gordura corporal (%)',
                  controller: bodyFatController,
                  hint: 'Ex: 18',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: goal,
                  decoration: const InputDecoration(
                    labelText: 'Objetivo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'hypertrophy',
                      child: Text('Hipertrofia'),
                    ),
                    DropdownMenuItem(value: 'strength', child: Text('Força')),
                    DropdownMenuItem(
                      value: 'weight_loss',
                      child: Text('Emagrecimento'),
                    ),
                    DropdownMenuItem(value: 'health', child: Text('Saúde')),
                  ],
                  onChanged: saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            goal = value;
                          });
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: daysPerWeek,
                  decoration: const InputDecoration(
                    labelText: 'Dias por semana',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 dia')),
                    DropdownMenuItem(value: 2, child: Text('2 dias')),
                    DropdownMenuItem(value: 3, child: Text('3 dias')),
                    DropdownMenuItem(value: 4, child: Text('4 dias')),
                    DropdownMenuItem(value: 5, child: Text('5 dias')),
                    DropdownMenuItem(value: 6, child: Text('6 dias')),
                  ],
                  onChanged: saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            daysPerWeek = value;
                          });
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: experienceLevel,
                  decoration: const InputDecoration(
                    labelText: 'Nível',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'beginner',
                      child: Text('Iniciante'),
                    ),
                    DropdownMenuItem(
                      value: 'intermediate',
                      child: Text('Intermediário'),
                    ),
                    DropdownMenuItem(
                      value: 'advanced',
                      child: Text('Avançado'),
                    ),
                  ],
                  onChanged: saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            experienceLevel = value;
                          });
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: sessionDurationInMinutes,
                  decoration: const InputDecoration(
                    labelText: 'Duração média por sessão',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 30, child: Text('30 min')),
                    DropdownMenuItem(value: 45, child: Text('45 min')),
                    DropdownMenuItem(value: 60, child: Text('60 min')),
                    DropdownMenuItem(value: 75, child: Text('75 min')),
                    DropdownMenuItem(value: 90, child: Text('90 min')),
                  ],
                  onChanged: saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            sessionDurationInMinutes = value;
                          });
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: restrictionsController,
                  minLines: 2,
                  maxLines: 4,
                  enabled: !saving,
                  decoration: const InputDecoration(
                    labelText: 'Restrições / lesões (opcional)',
                    hintText: 'Ex: dor no joelho, desconforto no ombro...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : _submit,
                    child: Text(
                      saving ? 'Criando plano...' : 'Criar plano com IA',
                    ),
                  ),
                ),
              ],
            ),
            _buildSavingOverlay(),
          ],
        ),
      ),
    );
  }
}
