import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trainforge/composition/app_dependency_scope.dart';
import 'privacy_controller.dart';

class PrivacyPage extends StatefulWidget {
  final bool authenticated;
  final Future<void> Function()? reauthenticate;
  final Future<void> Function(String)? onDeleted;
  final String? Function()? currentAccountId;
  final PrivacyController? controller;
  const PrivacyPage({
    super.key,
    this.authenticated = false,
    this.reauthenticate,
    this.onDeleted,
    this.currentAccountId,
    this.controller,
  });
  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  late final PrivacyController controller;
  final confirmation = TextEditingController();
  bool acknowledged = false;
  @override
  void initState() {
    super.initState();
    controller =
        widget.controller ??
        PrivacyController(
          AppDependencyScope.read(context).createPrivacyRepository(),
          afterDeletion: widget.onDeleted,
          currentAccountId: widget.currentAccountId,
        );
    controller.loadPolicy();
  }

  @override
  void dispose() {
    confirmation.dispose();
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final policy = controller.policy,
          export = controller.exportPage,
          erased = controller.erased;
      return PopScope(
        canPop: !controller.busy,
        child: FigmaRouteFrame(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                const FigmaPageHeading(
                  title: 'Privacidade e dados',
                  subtitle: 'POLÍTICA EFETIVA · CONTROLES DA SUA CONTA',
                ),
                if (controller.busy)
                  const AppProgress(label: 'Processando solicitação de dados'),
                if (controller.error != null) ...[
                  Semantics(liveRegion: true, child: Text(controller.error!)),
                  const SizedBox(height: 12),
                ],
                if (erased != null) ...[
                  Text(
                    'Conta TrainForge excluída',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(erased.backupNotice),
                  const Text(
                    'A conta Google permanece ativa. Os dados privados e as sessões desta conta foram removidos da base corrente do TrainForge.',
                  ),
                  if (erased.cleanupPending) ...[
                    const Text(
                      'A exclusão foi confirmada no servidor. Falta concluir a limpeza ou confirmação da sessão neste aparelho.',
                    ),
                    FilledButton(
                      onPressed: controller.busy
                          ? null
                          : controller.finishCleanup,
                      child: const Text('Concluir limpeza local'),
                    ),
                  ] else
                    FilledButton(
                      onPressed: controller.busy
                          ? null
                          : () => Navigator.maybePop(context),
                      child: const Text('Concluir'),
                    ),
                ] else ...[
                  Text(
                    'Seus dados e seus controles',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  if (policy == null && !controller.busy)
                    FilledButton(
                      onPressed: controller.loadPolicy,
                      child: const Text('Tentar carregar política'),
                    ),
                  if (policy != null) ...[
                    FigmaSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(policy.accountDeletion),
                          const SizedBox(height: 12),
                          Text(
                            'Backups e recuperação',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(policy.backupRetention),
                          Text(policy.restoreRequirement),
                          const SizedBox(height: 12),
                          Text(
                            'Registro mínimo após exclusão',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(policy.erasureLedger),
                          Text(policy.sessionRetention),
                          const SizedBox(height: 12),
                          Text(policy.otherServices),
                          Text(policy.futureStorage),
                          const SizedBox(height: 12),
                          const Text(
                            'Dados que você copiar ou exportar ficam sob sua gestão; a exclusão da conta não apaga cópias externas ou a área de transferência do aparelho.',
                          ),
                        ],
                      ),
                    ),
                    if (!widget.authenticated) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Entre com Google para consultar os dados da sua conta e solicitar sua exclusão.',
                      ),
                    ] else ...[
                      const Divider(height: 32),
                      Text(
                        'Consultar e copiar meus dados',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Text(
                        'Consulta paginada por seção. Cada cópia contém somente a página visível, sem credenciais de acesso.',
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: controller.section,
                        itemHeight: null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Seção de dados',
                        ),
                        items: policy.sections
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(sectionLabel(s)),
                              ),
                            )
                            .toList(),
                        onChanged: controller.busy
                            ? null
                            : (s) {
                                if (s != null) {
                                  controller.loadExport(section: s);
                                }
                              },
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: controller.busy
                            ? null
                            : () => controller.loadExport(),
                        child: const Text('Consultar seção'),
                      ),
                      if (export != null) ...[
                        Text(export.notice),
                        const Text(
                          'Esta é somente a página atual. A próxima página substitui a anterior na tela.',
                        ),
                        if (export.items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Nenhum registro nesta seção.'),
                          )
                        else
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: SelectableText(export.previewText),
                            ),
                          ),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: controller.busy
                                  ? null
                                  : () async {
                                      await Clipboard.setData(
                                        ClipboardData(text: export.jsonText),
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Página copiada. Ela pode conter dados pessoais.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              child: const Text('Copiar esta página JSON'),
                            ),
                            if (export.cursor != null)
                              OutlinedButton(
                                onPressed: controller.busy
                                    ? null
                                    : () => controller.loadExport(next: true),
                                child: const Text('Próxima página'),
                              ),
                          ],
                        ),
                      ],
                      const Divider(height: 32),
                      Text(
                        'Excluir minha conta TrainForge',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Text(
                        'Essa ação remove seus dados correntes e revoga todas as sessões. Leia acima os limites dos backups. Exige uma entrada Google realizada nos últimos 15 minutos.',
                      ),
                      if (widget.reauthenticate != null)
                        OutlinedButton(
                          onPressed: controller.busy
                              ? null
                              : () {
                                  confirmation.clear();
                                  controller.confirmAccount(
                                    widget.reauthenticate!,
                                  );
                                },
                          child: const Text(
                            'Confirmar conta novamente com Google',
                          ),
                        ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: acknowledged,
                        onChanged: controller.busy
                            ? null
                            : (v) => setState(() => acknowledged = v ?? false),
                        title: const Text(
                          'Li os limites da exclusão, das cópias históricas e da conta Google.',
                        ),
                      ),
                      if (controller.deletionIntent == null)
                        OutlinedButton(
                          onPressed: controller.busy || !acknowledged
                              ? null
                              : () {
                                  confirmation.clear();
                                  controller.requestDeletion();
                                },
                          child: const Text(
                            'Solicitar confirmação de exclusão',
                          ),
                        )
                      else ...[
                        const Text(
                          'Confirmação temporária criada para esta sessão. Digite a frase abaixo; ela expira em até 5 minutos.',
                        ),
                        TextField(
                          controller: confirmation,
                          enabled: !controller.busy,
                          maxLength: 19,
                          textCapitalization: TextCapitalization.characters,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: const InputDecoration(
                            labelText: 'EXCLUIR MINHA CONTA',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onError,
                          ),
                          onPressed:
                              controller.busy ||
                                  !acknowledged ||
                                  confirmation.text != 'EXCLUIR MINHA CONTA'
                              ? null
                              : () => controller.erase(confirmation.text),
                          child: const Text('Excluir minha conta e seus dados'),
                        ),
                        TextButton(
                          onPressed: controller.busy
                              ? null
                              : () {
                                  confirmation.clear();
                                  controller.cancelDeletion();
                                },
                          child: const Text('Cancelar exclusão'),
                        ),
                      ],
                    ],
                  ],
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

String sectionLabel(String section) => switch (section) {
  'account' => 'Conta',
  'sessions' => 'Sessões de acesso',
  'enrollments' => 'Adesões',
  'occurrences' => 'Agenda',
  'activitySessions' => 'Atividades',
  'activityEvents' => 'Eventos de atividade',
  'foods' => 'Alimentos próprios',
  'foodEntries' => 'Registros de consumo',
  _ => section,
};
