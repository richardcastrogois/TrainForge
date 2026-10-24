import 'evaluation_guide_page.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/catalog/data/catalog_repository.dart';
import 'package:trainforge/features/catalog/domain/catalog_entry.dart';
import 'package:trainforge/features/catalog/presentation/catalog_controller.dart';
import 'package:trainforge/features/catalog/presentation/catalog_page.dart';
import 'figma_components.dart';

class PlansOverview extends StatefulWidget {
  final CatalogController? controller;
  const PlansOverview({super.key, this.controller});
  @override
  State<PlansOverview> createState() => _PlansOverviewState();
}

class _PlansOverviewState extends State<PlansOverview> {
  late final CatalogController controller;
  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? CatalogController(GoCatalogRepository());
    controller.load(filters: CatalogFilters(kind: 'programs'));
  }

  @override
  void dispose() {
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  void library({String kind = 'movements'}) => Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => CatalogPage(initialFilters: CatalogFilters(kind: kind)),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => FigmaContent(
      title: 'Encontra o teu movimento.',
      subtitle: 'Com orientação, ao teu ritmo.',
      children: [
        Material(
          color: context.tf.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: library,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PESQUISAR',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.tf.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Movimento, modalidade ou fonte',
                    style: TextStyle(fontSize: 15, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (controller.busy)
          AppProgress(label: 'Consultando programas disponíveis'),
        if (controller.error != null) ...[
          Text(
            'Não foi possível consultar os programas. A disponibilidade não foi confirmada.',
          ),
          OutlinedButton(
            onPressed: () => controller.load(),
            child: Text('Tentar novamente'),
          ),
        ] else if (!controller.busy)
          FigmaActionCard(
            title: controller.facets?.programCount == 0
                ? 'Programas ainda indisponíveis'
                : 'Consultar programas',
            subtitle: controller.facets?.programCount == 0
                ? 'Nenhum programa liberado para prática. Consulte as referências disponíveis.'
                : 'Ver origem, requisitos e disponibilidade',
            asset: 'plan',
            color: context.tf.accent,
            onTap: () => library(kind: 'programs'),
          ),
        FigmaActionCard(
          title: 'Explorar modalidades',
          subtitle: 'Biblioteca de referência · somente consulta',
          asset: 'activity',
          color: context.tf.blue,
          onTap: library,
        ),
        FigmaActionCard(
          title: 'Criar o meu plano',
          subtitle: 'Escolher exercícios e organizar a semana',
          asset: 'plus',
          onTap: () => showAvailability(
            context,
            'Criar o meu plano',
            'A composição de planos ainda não está implementada e não há instruções ou doses liberadas. Nenhum treino será criado automaticamente.',
          ),
        ),
        FigmaActionCard(
          title: 'Ajuda-me a começar',
          subtitle: 'Casa, praça, academia, idosos e cuidadores',
          asset: 'spark',
          color: context.tf.pink,
          onTap: () =>
              openEvaluationGuide(context, EvaluationTopic.firstAccess),
        ),
      ],
    ),
  );
}
