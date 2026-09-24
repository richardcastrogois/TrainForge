//lib/features/profile/presentation/pages/profile_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/auth/data/auth_repository.dart';
import 'package:trainforge/features/auth/presentation/pages/auth_page.dart';
import 'package:trainforge/features/profile/data/profile_repository.dart';
import 'package:trainforge/features/profile/domain/profile_data.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileRepository repository = ProfileRepository();
  final AuthRepository authRepository = AuthRepository();

  bool loading = true;
  bool saving = false;
  String? errorMessage;
  ProfileData? profile;

  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final ageController = TextEditingController();
  final bodyFatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    weightController.dispose();
    heightController.dispose();
    ageController.dispose();
    bodyFatController.dispose();
    super.dispose();
  }

  void fillControllers(TrainData? trainData) {
    if (trainData == null) {
      weightController.text = '';
      heightController.text = '';
      ageController.text = '';
      bodyFatController.text = '';
      return;
    }

    weightController.text = trainData.weightInKg.toStringAsFixed(1);
    heightController.text = trainData.heightInCentimeters.toString();
    ageController.text = trainData.age.toString();
    bodyFatController.text = trainData.bodyFatPercentage.toString();
  }

  Future<void> loadProfile() async {
    try {
      final result = await repository.getProfile();

      if (!mounted) return;

      fillControllers(result.trainData);

      setState(() {
        profile = result;
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
        errorMessage = 'Erro ao carregar perfil';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Erro inesperado ao carregar perfil';
      });
    }
  }

  Future<void> saveTrainData() async {
    final weightText = weightController.text.trim().replaceAll(',', '.');
    final heightText = heightController.text.trim();
    final ageText = ageController.text.trim();
    final bodyFatText = bodyFatController.text.trim();

    if (weightText.isEmpty ||
        heightText.isEmpty ||
        ageText.isEmpty ||
        bodyFatText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));
      return;
    }

    final weightKg = double.tryParse(weightText);
    final height = int.tryParse(heightText);
    final age = int.tryParse(ageText);
    final bodyFat = int.tryParse(bodyFatText);

    if (weightKg == null || height == null || age == null || bodyFat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos com valores válidos')),
      );
      return;
    }

    if (weightKg <= 0 ||
        height <= 0 ||
        age <= 0 ||
        bodyFat < 0 ||
        bodyFat > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valores fora do intervalo permitido')),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final saved = await repository.upsertTrainData(
        weightInGrams: (weightKg * 1000).round(),
        heightInCentimeters: height,
        age: age,
        bodyFatPercentage: bodyFat,
      );

      if (!mounted) return;

      setState(() {
        profile = ProfileData(user: profile!.user, trainData: saved);
      });

      fillControllers(saved);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dados salvos com sucesso')));
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao salvar dados')));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro inesperado ao salvar dados')),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Future<void> handleLogout() async {
    await authRepository.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (route) => false,
    );
  }

  Widget buildField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
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
        appBar: AppBar(title: const Text('Perfil')),
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
                    loadProfile();
                  },
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = profile!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: handleLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: data.user.image != null
                      ? NetworkImage(data.user.image!)
                      : null,
                  child: data.user.image == null
                      ? Text(
                          data.user.name.isNotEmpty
                              ? data.user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 24),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.user.email,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Dados físicos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            buildField(
              label: 'Peso (kg)',
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              hint: 'Ex: 82.5',
            ),
            const SizedBox(height: 12),
            buildField(
              label: 'Altura (cm)',
              controller: heightController,
              keyboardType: TextInputType.number,
              hint: 'Ex: 178',
            ),
            const SizedBox(height: 12),
            buildField(
              label: 'Idade',
              controller: ageController,
              keyboardType: TextInputType.number,
              hint: 'Ex: 25',
            ),
            const SizedBox(height: 12),
            buildField(
              label: 'Gordura corporal (%)',
              controller: bodyFatController,
              keyboardType: TextInputType.number,
              hint: 'Ex: 18',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : saveTrainData,
                child: Text(saving ? 'Salvando...' : 'Salvar dados'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
