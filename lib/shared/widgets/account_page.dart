import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'package:trainforge/features/privacy/presentation/privacy_page.dart';
import 'figma_components.dart';
import 'product_overviews.dart';

class AccountPage extends StatelessWidget {
  final AuthController controller;
  const AccountPage({super.key, required this.controller});
  void privacy(BuildContext context) => Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => PrivacyPage(
        authenticated: true,
        reauthenticate: () async {
          await controller.login();
          if (controller.message != null) {
            throw StateError('Confirmação indisponível');
          }
        },
        currentAccountId: () => controller.profile?.id,
        onDeleted: (erasedId) async {
          controller.accountErased(erasedId);
          await controller.restore();
        },
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final profile = controller.profile;
      if (profile == null) return const SizedBox.shrink();
      return Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  FigmaHeader(name: profile.name),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      children: [
                        const FigmaBack(),
                        Text(
                          'O teu espaço.',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Conta conectada',
                          style: TextStyle(
                            fontSize: 12,
                            color: TrainForgeTheme.muted,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: TrainForgeTheme.accent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox.square(
                                dimension: 48,
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/figma/profile-user.svg',
                                    excludeFromSemantics: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.name,
                                      style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w700,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      profile.email,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: TrainForgeTheme.primary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        FigmaActionCard(
                          title: 'Conta e dados pessoais',
                          subtitle: 'Identidade Google, exportação e exclusão',
                          asset: 'user',
                          onTap: () => privacy(context),
                        ),
                        const SizedBox(height: 12),
                        FigmaActionCard(
                          title: 'Objetivos e rotina',
                          subtitle: 'Equipamento, dias e modalidades',
                          asset: 'plan',
                          onTap: () => showAvailability(
                            context,
                            'Objetivos e rotina',
                            'A configuração de contexto e rotina ainda não está implementada. Nenhuma preferência foi inferida da sua conta Google.',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FigmaActionCard(
                          title: 'Preferências',
                          subtitle: 'Notificações, idioma e acessibilidade',
                          asset: 'settings',
                          onTap: () => showAvailability(
                            context,
                            'Preferências',
                            'As preferências próprias do app ainda não são persistidas. O tamanho do texto e o leitor de tela seguem as configurações de acessibilidade do aparelho.',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FigmaActionCard(
                          title: 'Dispositivos e permissões',
                          subtitle: 'Health Connect, localização e câmara',
                          asset: 'activity',
                          color: tfBlue,
                          onTap: () => showAvailability(
                            context,
                            'Dispositivos e permissões',
                            'As integrações com sensores, localização e câmera ainda não foram implementadas. Nenhuma permissão será solicitada por esta ação.',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FigmaActionCard(
                          title: 'Privacidade e ajuda',
                          subtitle: 'Os teus dados sob o teu controlo',
                          asset: 'heart',
                          color: TrainForgeTheme.soft,
                          onTap: () => privacy(context),
                        ),
                        const SizedBox(height: 12),
                        if (controller.busy)
                          const LinearProgressIndicator(
                            semanticsLabel: 'Confirmando sessão',
                          ),
                        if (controller.message != null) ...[
                          Semantics(
                            liveRegion: true,
                            child: Text(controller.message!),
                          ),
                          TextButton(
                            onPressed: controller.busy
                                ? null
                                : controller.retry,
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                        OutlinedButton(
                          onPressed: controller.busy
                              ? null
                              : controller.restore,
                          child: const Text('Confirmar conexão'),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: controller.busy ? null : controller.logout,
                          child: const Text('Sair desta sessão'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
