import 'package:trainforge/core/theme/appearance_page.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'package:trainforge/features/privacy/presentation/privacy_page.dart';
import 'figma_components.dart';

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
              constraints: BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  FigmaHeader(name: profile.name),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      children: [
                        FigmaBack(),
                        Text(
                          'O teu espaço.',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Conta conectada',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.tf.muted,
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: context.tf.accent,
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
                                    colorFilter:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? ColorFilter.mode(
                                            context.tf.primary,
                                            BlendMode.srcIn,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.name,
                                      style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w700,
                                        height: 1.35,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      profile.email,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.tf.primary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        FigmaActionCard(
                          title: 'Conta e dados pessoais',
                          subtitle: 'Identidade Google, exportação e exclusão',
                          asset: 'user',
                          onTap: () => privacy(context),
                        ),
                        SizedBox(height: 12),
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
                        SizedBox(height: 12),
                        FigmaActionCard(
                          title: 'Preferências',
                          subtitle: 'Aparência e acessibilidade do aparelho',
                          asset: 'settings',
                          onTap: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AppearancePage(),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        FigmaActionCard(
                          title: 'Dispositivos e permissões',
                          subtitle: 'Health Connect, localização e câmara',
                          asset: 'activity',
                          color: context.tf.blue,
                          onTap: () => showAvailability(
                            context,
                            'Dispositivos e permissões',
                            'As integrações com sensores, localização e câmera ainda não foram implementadas. Nenhuma permissão será solicitada por esta ação.',
                          ),
                        ),
                        SizedBox(height: 12),
                        FigmaActionCard(
                          title: 'Privacidade e ajuda',
                          subtitle: 'Os teus dados sob o teu controlo',
                          asset: 'heart',
                          color: context.tf.soft,
                          onTap: () => privacy(context),
                        ),
                        SizedBox(height: 12),
                        if (controller.busy)
                          AppProgress(label: 'Confirmando sessão'),
                        if (controller.message != null) ...[
                          Semantics(
                            liveRegion: true,
                            child: Text(controller.message!),
                          ),
                          TextButton(
                            onPressed: controller.busy
                                ? null
                                : controller.retry,
                            child: Text('Tentar novamente'),
                          ),
                        ],
                        OutlinedButton(
                          onPressed: controller.busy
                              ? null
                              : controller.restore,
                          child: Text('Confirmar conexão'),
                        ),
                        SizedBox(height: 12),
                        FilledButton(
                          onPressed: controller.busy ? null : controller.logout,
                          child: Text('Sair desta sessão'),
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
