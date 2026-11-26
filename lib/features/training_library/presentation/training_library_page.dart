import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/training_library.dart';

String trainingLabel(BuildContext context, String key) {
  final language = Localizations.localeOf(context).languageCode;
  return (_labels[language] ?? _labels['en']!)[key] ?? _labels['en']![key]!;
}

const _labels = <String, Map<String, String>>{
  'en': {
    'title': 'Ready workouts',
    'subtitle': 'Sessions from professional sources, by place and level',
    'place': 'Where will you train?',
    'level': 'Level',
    'empty': 'No session for this choice yet.',
    'loadFailed': 'The workout library could not be opened.',
    'minutes': 'min',
    'equipment': 'Equipment',
    'benefit': 'Benefit declared by the source',
    'exercises': 'Exercises',
    'dose': 'How much',
    'advice': 'Source recommendation',
    'audience': 'Who it is for',
    'source': 'Source',
    'openSource': 'Open source',
    'noLoad': 'No extra weight',
    'safety':
        'Stop if you feel pain, shortness of breath, dizziness or palpitations. If you have a health condition, talk to your doctor before starting. TrainForge does not prescribe exercise; the content is from the cited sources.',
    'content': 'Session content in Portuguese, as recorded from the source.',
  },
  'pt': {
    'title': 'Treinos prontos',
    'subtitle': 'Sessões de fontes profissionais, por lugar e nível',
    'place': 'Onde você vai treinar?',
    'level': 'Nível',
    'empty': 'Ainda não há sessão para esta escolha.',
    'loadFailed': 'Não foi possível abrir a biblioteca de treinos.',
    'minutes': 'min',
    'equipment': 'Material',
    'benefit': 'Benefício declarado pela fonte',
    'exercises': 'Exercícios',
    'dose': 'Quanto fazer',
    'advice': 'Recomendação da fonte',
    'audience': 'Para quem',
    'source': 'Fonte',
    'openSource': 'Abrir a fonte',
    'noLoad': 'Sem peso extra',
    'safety':
        'Pare se sentir dor, falta de ar, tontura ou palpitação. Se você tem alguma condição de saúde, converse com seu médico antes de começar. O TrainForge não prescreve exercícios; o conteúdo é das fontes citadas.',
    'content': 'Conteúdo da sessão conforme registrado da fonte.',
  },
  'es': {
    'title': 'Entrenamientos listos',
    'subtitle': 'Sesiones de fuentes profesionales, por lugar y nivel',
    'place': '¿Dónde vas a entrenar?',
    'level': 'Nivel',
    'empty': 'Todavía no hay sesión para esta elección.',
    'loadFailed': 'No se pudo abrir la biblioteca de entrenamientos.',
    'minutes': 'min',
    'equipment': 'Material',
    'benefit': 'Beneficio declarado por la fuente',
    'exercises': 'Ejercicios',
    'dose': 'Cuánto hacer',
    'advice': 'Recomendación de la fuente',
    'audience': 'Para quién',
    'source': 'Fuente',
    'openSource': 'Abrir la fuente',
    'noLoad': 'Sin peso extra',
    'safety':
        'Detente si sientes dolor, falta de aire, mareo o palpitaciones. Si tienes alguna condición de salud, habla con tu médico antes de empezar. TrainForge no prescribe ejercicios; el contenido es de las fuentes citadas.',
    'content':
        'Contenido de la sesión en portugués, tal como se registró de la fuente.',
  },
};

/// Place → level → sessions; everything offline from the bundled research asset.
class TrainingLibraryPage extends StatefulWidget {
  final Future<String> Function()? read;

  /// Preselected from the first answers; the person can still change both.
  final String? initialPlace, initialCell;
  const TrainingLibraryPage({
    super.key,
    this.read,
    this.initialPlace,
    this.initialCell,
  });
  @override
  State<TrainingLibraryPage> createState() => _TrainingLibraryPageState();
}

class _TrainingLibraryPageState extends State<TrainingLibraryPage> {
  late final Future<TrainingLibrary> library = TrainingLibrary.load(
    widget.read,
  );
  late String? place = widget.initialPlace, cell = widget.initialCell;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(trainingLabel(context, 'title'))),
    body: FutureBuilder<TrainingLibrary>(
      future: library,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(trainingLabel(context, 'loadFailed')));
        }
        final lib = snapshot.data;
        if (lib == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final selected = lib.places.firstWhere(
          (p) => p.id == place,
          orElse: () => lib.places.first,
        );
        final level = selected.cells.firstWhere(
          (c) => c.id == cell,
          orElse: () => selected.cells.first,
        );
        final sessions = lib.forCell(level.id);
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(trainingLabel(context, 'subtitle')),
            const SizedBox(height: 16),
            Text(
              trainingLabel(context, 'place'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in lib.places)
                  ChoiceChip(
                    label: Text(p.name),
                    selected: p.id == selected.id,
                    onSelected: (_) => setState(() {
                      place = p.id;
                      cell = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              trainingLabel(context, 'level'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in selected.cells)
                  ChoiceChip(
                    label: Text(_levelName(c)),
                    selected: c.id == level.id,
                    onSelected: (_) => setState(() => cell = c.id),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (sessions.isEmpty) Text(trainingLabel(context, 'empty')),
            for (final s in sessions)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(s.name),
                  subtitle: Text(
                    [
                      if (s.minutes != null)
                        '${s.minutes} ${trainingLabel(context, 'minutes')}',
                      if (s.equipment != null && s.equipment!.isNotEmpty)
                        s.equipment!,
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrainingSessionPage(session: s),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );

  /// "Casa — iniciante" → "iniciante" (the place is already chosen above).
  String _levelName(TrainingCell c) {
    final parts = c.name.split(' — ');
    final level = parts.length > 1 ? parts.sublist(1).join(' — ') : c.name;
    return level.isEmpty ? c.name : level[0].toUpperCase() + level.substring(1);
  }
}

class TrainingSessionPage extends StatelessWidget {
  final TrainingSession session;
  const TrainingSessionPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final s = session;
    final theme = Theme.of(context).textTheme;
    Widget section(String key, String? text) => text == null || text.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trainingLabel(context, key), style: theme.titleSmall),
                const SizedBox(height: 4),
                Text(text),
              ],
            ),
          );
    return Scaffold(
      appBar: AppBar(title: Text(s.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (s.minutes != null)
                Chip(
                  avatar: const Icon(Icons.timer_outlined, size: 18),
                  label: Text(
                    '${s.minutes} ${trainingLabel(context, 'minutes')}',
                  ),
                ),
              if (s.noLoad) Chip(label: Text(trainingLabel(context, 'noLoad'))),
            ],
          ),
          Card(
            margin: const EdgeInsets.only(top: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.health_and_safety_outlined),
                  const SizedBox(width: 10),
                  Expanded(child: Text(trainingLabel(context, 'safety'))),
                ],
              ),
            ),
          ),
          section('audience', s.audience),
          section('equipment', s.requiresEquipment ?? s.equipment),
          section('benefit', s.benefit),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              trainingLabel(context, 'exercises'),
              style: theme.titleSmall,
            ),
          ),
          for (final (i, e) in s.exercises.indexed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
              title: Text(e.name),
              subtitle: Text(
                [
                  if (e.dose != null) e.dose!,
                  if (e.benefit != null) e.benefit!,
                  if (e.source != null) e.source!,
                ].join('\n'),
              ),
              isThreeLine: e.dose != null && e.source != null,
            ),
          section('dose', s.dose),
          section('advice', s.sourceAdvice),
          section(
            'source',
            [
              s.source.name,
              if (s.source.responsible != null) s.source.responsible!,
              if (s.source.locator != null) s.source.locator!,
              if (s.source.license != null) s.source.license!,
            ].join('\n'),
          ),
          if (s.source.url != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(s.source.url!),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new),
                label: Text(trainingLabel(context, 'openSource')),
              ),
            ),
          const SizedBox(height: 8),
          Text(trainingLabel(context, 'content'), style: theme.bodySmall),
        ],
      ),
    );
  }
}
