import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/presentation/daily_summary_controller.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';

class TodayPage extends StatefulWidget {
  final DailySummaryController controller;
  final String name;
  final VoidCallback openNutrition, openCatalog, openActivity;
  final ValueChanged<DateTime>? openDay;
  const TodayPage({
    super.key,
    required this.controller,
    required this.name,
    required this.openNutrition,
    required this.openCatalog,
    required this.openActivity,
    this.openDay,
  });
  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> with WidgetsBindingObserver {
  Timer? midnight;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scheduleMidnight();
  }

  void scheduleMidnight() {
    midnight?.cancel();
    final now = widget.controller.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    final wait = next.difference(now) + Duration(milliseconds: 100);
    midnight = Timer(wait.isNegative ? Duration(seconds: 1) : wait, () {
      if (!mounted) return;
      widget.controller.load();
      setState(() {});
      scheduleMidnight();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      scheduleMidnight();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller, now = controller.now();
      final dark = Theme.of(context).brightness == Brightness.dark;
      final snapshot = controller.loading ? null : controller.summary;
      final complete = snapshot?['complete'] == true;
      final int? count = complete ? (snapshot?['entries'] as int?) : null;
      final energy = dailyEnergy(snapshot);
      final name = widget.name
          .trim()
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty);
      return RefreshIndicator(
        onRefresh: controller.load,
        child: FigmaContent(
          title: name.isEmpty ? 'Bora mexer!' : 'Bora mexer, ${name.first}!',
          subtitle: todayDate(now),
          children: [
            Material(
              color: dark ? context.tf.surface : TrainForgeTheme.primary,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: widget.openCatalog,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UM POUCO MAIS FORTE, TODOS OS DIAS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: dark
                              ? context.tf.primary
                              : TrainForgeTheme.accent,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'O teu próximo movimento',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                          color: dark ? context.tf.ink : Colors.white,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Biblioteca para consulta. Prática guiada ainda indisponível.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: dark ? context.tf.ink : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Text(
              'A tua semana',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              'Consultar o diário alimentar por data.',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: context.tf.muted,
              ),
            ),
            _Week(
              now: now,
              onSelected: (date) {
                if (widget.openDay != null) {
                  widget.openDay!(date);
                } else {
                  widget.openNutrition();
                }
              },
            ),
            Text(
              'O teu dia',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            if (controller.loading) ...[
              AppMetricSkeleton(label: 'Consultando os dados reais do dia'),
              AppProgress(label: 'Consultando registros do dia'),
            ] else if (controller.failed)
              FigmaSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        'Não foi possível atualizar o dia.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Os dados não foram confirmados. Esta consulta não cria nem remove consumos.',
                    ),
                    SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: controller.load,
                      child: Text('Tentar atualizar novamente'),
                    ),
                  ],
                ),
              )
            else ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _Metric(
                        value: energy ?? '—',
                        label: energy == null
                            ? 'energia sem subtotal único confirmado'
                            : 'kcal · um método da fonte',
                        color: context.tf.nutrition,
                        onTap: widget.openNutrition,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _Metric(
                        value: '—',
                        label: 'atividade ainda indisponível',
                        color: context.tf.blue,
                        onTap: widget.openActivity,
                      ),
                    ),
                  ],
                ),
              ),
              if (snapshot != null && !complete)
                Text(
                  'O limite do resumo foi excedido. Consulte o histórico; nenhum total parcial é apresentado como completo.',
                  style: TextStyle(fontSize: 12, height: 1.35),
                ),
              if (energy != null)
                Text(
                  '${snapshot!['measuredEntries']} medidas · ${snapshot['estimatedEntries']} estimadas. Origem e método no diário.',
                  style: TextStyle(fontSize: 12, height: 1.35),
                ),
            ],
            FigmaActionCard(
              title: 'Minha alimentação',
              asset: 'food',
              color: context.tf.nutrition,
              subtitle: controller.loading
                  ? 'Consultando registros…'
                  : controller.failed
                  ? 'Abrir histórico e tentar atualizar'
                  : count == 0
                  ? 'Nenhum consumo confirmado neste dia'
                  : count == null
                  ? 'Consultar registros e origem'
                  : '$count ${count == 1 ? 'consumo confirmado' : 'consumos confirmados'} neste dia · ver origem',
              onTap: widget.openNutrition,
            ),
            FigmaActionCard(
              title: 'O que te apetece hoje?',
              subtitle: 'Caminhar, correr, explorar outra modalidade',
              asset: 'activity',
              color: context.tf.yellow,
              onTap: widget.openActivity,
            ),
            TextButton(
              onPressed: controller.loading ? null : controller.load,
              child: Text('Atualizar o dia'),
            ),
          ],
        ),
      );
    },
  );
}

String todayDate(DateTime date) {
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
  return '${days[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]} · O teu ritmo, todos os dias';
}

class _Week extends StatelessWidget {
  final DateTime now;
  final ValueChanged<DateTime> onSelected;
  const _Week({required this.now, required this.onSelected});
  @override
  Widget build(BuildContext context) {
    final monday = DateTime(now.year, now.month, now.day - now.weekday + 1);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) SizedBox(width: 1),
            Builder(
              builder: (context) {
                final day = DateTime(monday.year, monday.month, monday.day + i);
                final selected = localDay(day) == localDay(now);
                return Semantics(
                  label: 'Consultar alimentação de ${localDay(day)}',
                  button: true,
                  selected: selected,
                  excludeSemantics: true,
                  child: SizedBox(
                    width: 48,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onSelected(day),
                        borderRadius: BorderRadius.circular(17),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 2,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? context.tf.accent
                                  : context.tf.surface,
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'][i],
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value, label;
  final Color color;
  final VoidCallback onTap;
  const _Metric({
    required this.value,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 11, height: 1.35)),
          ],
        ),
      ),
    ),
  );
}
