//lib/features/onboarding/presentation/pages/manual_onboarding_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/auth/data/auth_repository.dart';
import 'package:trainforge/features/auth/presentation/pages/auth_page.dart';
import 'package:trainforge/features/onboarding/data/onboarding_repository.dart';
import 'package:trainforge/features/profile/domain/profile_data.dart';
import 'package:trainforge/shared/widgets/auth_gate.dart';

class ManualOnboardingPage extends StatefulWidget {
  final TrainData? initialTrainData;

  const ManualOnboardingPage({super.key, required this.initialTrainData});

  @override
  State<ManualOnboardingPage> createState() => _ManualOnboardingPageState();
}

class _ManualOnboardingPageState extends State<ManualOnboardingPage> {
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

  Future<void> _submit() async {
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
      await repository.createManualPlan(
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
        const SnackBar(content: Text('Plano manual criado com sucesso')),
      );

      await _goToApp();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _goToAuth();
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao criar plano manual')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro inesperado ao criar plano manual')),
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
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plano manual'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Escolha suas preferências. O backend vai montar um plano sem usar IA.',
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
            onChanged: (value) {
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
            onChanged: (value) {
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
              DropdownMenuItem(value: 'beginner', child: Text('Iniciante')),
              DropdownMenuItem(
                value: 'intermediate',
                child: Text('Intermediário'),
              ),
              DropdownMenuItem(value: 'advanced', child: Text('Avançado')),
            ],
            onChanged: (value) {
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
            onChanged: (value) {
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
              child: Text(saving ? 'Criando plano...' : 'Criar plano manual'),
            ),
          ),
        ],
      ),
    );
  }
}
