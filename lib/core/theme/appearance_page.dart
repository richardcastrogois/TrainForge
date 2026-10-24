import 'package:flutter/material.dart';
import 'package:trainforge/core/theme/appearance_controller.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = AppearanceScope.maybeOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Aparência')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'O teu ritmo, o teu tema.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'A escolha vale neste aparelho e continua após fechar o app. Seus dados da conta não são alterados.',
            ),
            const SizedBox(height: 20),
            if (controller == null)
              const Text('A aparência não está disponível neste contexto.')
            else ...[
              RadioGroup<ThemeMode>(
                groupValue: controller.mode,
                onChanged: (value) {
                  if (value != null && !controller.saving) {
                    controller.select(value);
                  }
                },
                child: Column(
                  children: [
                    for (final item in [
                      (
                        ThemeMode.system,
                        'Seguir o aparelho',
                        'Acompanha o tema claro ou escuro do sistema.',
                      ),
                      (
                        ThemeMode.light,
                        'Claro',
                        'A identidade original em superfícies claras.',
                      ),
                      (
                        ThemeMode.dark,
                        'Escuro',
                        'Superfícies escuras e contraste adaptado.',
                      ),
                    ])
                      Card(
                        child: RadioListTile<ThemeMode>(
                          value: item.$1,
                          enabled: !controller.saving,
                          title: Text(item.$2),
                          subtitle: Text(item.$3),
                        ),
                      ),
                  ],
                ),
              ),
              if (controller.saving)
                const AppProgress(label: 'Salvando aparência'),
              if (controller.message != null) ...[
                Semantics(liveRegion: true, child: Text(controller.message!)),
                TextButton(
                  onPressed: controller.saving
                      ? null
                      : () => controller.select(controller.mode),
                  child: const Text('Tentar salvar novamente'),
                ),
              ],
            ],
            const SizedBox(height: 20),
            const Text(
              'O tamanho do texto e a redução de movimento seguem as configurações de acessibilidade do aparelho.',
            ),
          ],
        ),
      ),
    );
  }
}
