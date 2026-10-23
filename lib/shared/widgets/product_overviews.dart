import 'package:flutter/material.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/nutrition/presentation/daily_summary_controller.dart';
import 'figma_components.dart';

const tfBlue = Color(0xffc9eaf7), tfYellow = Color(0xfff8eba5);
String overviewDate(DateTime date) {
  const days = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];
  const months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  return '${days[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
}

class DailyOverview extends StatelessWidget {
  final DailySummaryController controller;
  final String name;
  final bool food;
  final VoidCallback openNutrition, openCatalog, openActivity;
  const DailyOverview({
    super.key,
    required this.controller,
    required this.name,
    required this.food,
    required this.openNutrition,
    required this.openCatalog,
    required this.openActivity,
  });
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final snapshot = controller.loading ? null : controller.summary;
      final count = snapshot?['entries'];
      final energy = dailyEnergy(snapshot);
      final state = controller.loading
          ? 'Consultando…'
          : controller.failed
          ? 'Consulta indisponível'
          : 'Veja os subtotais por método da fonte.';
      return RefreshIndicator(
        onRefresh: controller.load,
        child: FigmaContent(
          title: food
              ? 'Comer bem, sem complicar.'
              : 'Bora mexer, ${name.trim().split(RegExp(r'\s+')).first}!',
          subtitle:
              '${overviewDate(controller.now())} · ${food ? 'DIÁRIO ALIMENTAR' : 'O teu ritmo, todos os dias'}',
          children: [
            if (controller.loading)
              const LinearProgressIndicator(
                semanticsLabel: 'Consultando registros do dia',
              ),
            if (!food) ...[
              Material(
                color: TrainForgeTheme.primary,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: openCatalog,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'UM POUCO MAIS FORTE, TODOS OS DIAS',
                          style: TextStyle(
                            fontSize: 10,
                            color: TrainForgeTheme.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'O teu próximo movimento',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Biblioteca para consulta. Prática guiada ainda indisponível.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Text(
                'O teu dia',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: FigmaMetric(
                      value: count?.toString() ?? '—',
                      label: 'consumos confirmados',
                      color: TrainForgeTheme.nutrition,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: FigmaMetric(
                      value: '—',
                      label: 'atividade ainda indisponível',
                      color: tfBlue,
                    ),
                  ),
                ],
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: TrainForgeTheme.nutrition,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ENERGIA REGISTRADA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      energy ?? '—',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    Text(
                      energy == null
                          ? state
                          : 'kcal · subtotal de um método da fonte',
                      style: const TextStyle(fontSize: 12, height: 1.35),
                    ),
                    if (energy != null)
                      Text(
                        '${snapshot!['measuredEntries']} medidas · ${snapshot['estimatedEntries']} estimadas',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            if (controller.failed)
              OutlinedButton(
                onPressed: controller.load,
                child: const Text('Atualizar registros do dia'),
              ),
            FigmaActionCard(
              title: food ? 'Meus registros' : 'Minha alimentação',
              subtitle: count == null
                  ? state
                  : '$count consumos neste dia · ver histórico e origem',
              asset: 'food',
              color: food ? Colors.white : TrainForgeTheme.nutrition,
              onTap: openNutrition,
            ),
            if (food) ...[
              FilledButton(
                onPressed: openNutrition,
                child: const Text('Adicionar alimento'),
              ),
              FigmaActionCard(
                title: 'Hidratação',
                subtitle: 'Registro de água ainda indisponível',
                asset: 'water',
                color: tfBlue,
                onTap: () => showAvailability(
                  context,
                  'Hidratação',
                  'O registro de água ainda não foi implementado. Nenhuma quantidade foi preenchida automaticamente.',
                ),
              ),
              FigmaActionCard(
                title: 'Planear e aprender',
                subtitle: 'Conteúdo alimentar ainda não liberado',
                asset: 'plan',
                onTap: () => showAvailability(
                  context,
                  'Planejamento e aprendizagem',
                  'Planos alimentares e orientações ainda não estão disponíveis. A consulta das fontes e seus nutrientes permanece acessível pelo diário.',
                ),
              ),
            ] else
              FigmaActionCard(
                title: 'O que te apetece hoje?',
                subtitle: 'Caminhar, correr, explorar outra modalidade',
                asset: 'activity',
                color: tfYellow,
                onTap: openActivity,
              ),
          ],
        ),
      );
    },
  );
}

class ActivityOverview extends StatelessWidget {
  const ActivityOverview({super.key});
  @override
  Widget build(BuildContext context) => FigmaContent(
    title: 'Lá fora também conta.',
    subtitle: 'Caminha, corre ou regista a tua atividade.',
    children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: tfBlue,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Text(
          'Percurso ainda indisponível. Nenhuma localização está sendo coletada.',
          style: TextStyle(fontSize: 15, height: 1.35),
        ),
      ),
      const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FigmaMetric(
              value: '—',
              label: 'km · sem registro de caminhada',
              color: tfBlue,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: FigmaMetric(
              value: '—',
              label: 'min de atividade indisponíveis',
              color: tfYellow,
            ),
          ),
        ],
      ),
      FilledButton(
        onPressed: () => showAvailability(
          context,
          'Começar atividade',
          'O registro de atividade e a coleta de GPS ainda não foram implementados neste incremento.',
        ),
        child: const Text('Começar atividade'),
      ),
      FigmaActionCard(
        title: 'Registo rápido',
        subtitle: 'Registro manual e por imagem ainda indisponíveis',
        asset: 'plus',
        onTap: () => showAvailability(
          context,
          'Registo rápido',
          'Este fluxo ainda depende da implementação de atividade e suas validações. Nenhum histórico será criado por esta ação.',
        ),
      ),
      FigmaActionCard(
        title: 'Os meus dispositivos',
        subtitle: 'Permissões, origem e sincronização',
        asset: 'activity',
        color: TrainForgeTheme.soft,
        onTap: () => showAvailability(
          context,
          'Os meus dispositivos',
          'Ainda não há integração com sensores ou dispositivos. Nenhuma permissão será solicitada por esta tela.',
        ),
      ),
    ],
  );
}

class EvolutionOverview extends StatelessWidget {
  final VoidCallback openNutrition;
  const EvolutionOverview({super.key, required this.openNutrition});
  @override
  Widget build(BuildContext context) => FigmaContent(
    title: 'Olha o que já construíste.',
    subtitle: 'O TEU HISTÓRICO, COM ORIGEM',
    children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '—',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
            ),
            Text(
              'Evolução de atividade ainda indisponível. O gráfico será exibido quando houver registros e cálculo implementados.',
              style: TextStyle(fontSize: 12, height: 1.35),
            ),
          ],
        ),
      ),
      const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FigmaMetric(
              value: '—',
              label: 'treinos ainda indisponíveis',
              color: TrainForgeTheme.soft,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: FigmaMetric(
              value: '—',
              label: 'km de caminhada indisponíveis',
              color: tfBlue,
            ),
          ),
        ],
      ),
      FigmaActionCard(
        title: 'Cada registo conta',
        subtitle: 'Ver histórico e corrigir um consumo',
        asset: 'chart',
        color: tfYellow,
        onTap: openNutrition,
      ),
      FigmaActionCard(
        title: 'Medidas e objetivos',
        subtitle: 'Configuração ainda indisponível',
        asset: 'heart',
        onTap: () => showAvailability(
          context,
          'Medidas e objetivos',
          'Este fluxo ainda não persiste medidas ou metas. Nenhuma meta foi inferida a partir do seu perfil.',
        ),
      ),
    ],
  );
}
