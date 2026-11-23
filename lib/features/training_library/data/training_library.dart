import 'dart:convert';

import 'package:flutter/services.dart';

/// Ready sessions from the training research (`tools/gerar_treinos_app.py` builds the asset).
/// Content stays as recorded by the research: Portuguese text, dose and source per exercise.
class TrainingExercise {
  final String name;
  final String? dose, source, benefit;
  const TrainingExercise(this.name, this.dose, this.source, this.benefit);
}

class TrainingSource {
  final String name;
  final String? responsible, url, license, locator;
  const TrainingSource(
    this.name,
    this.responsible,
    this.url,
    this.license,
    this.locator,
  );
}

class TrainingSession {
  final String id, name;
  final List<String> cells;
  final int? minutes;
  final String? equipment,
      benefit,
      dose,
      schedule,
      sourceAdvice,
      audience,
      requiresEquipment;
  final bool noLoad;
  final List<TrainingExercise> exercises;
  final TrainingSource source;
  const TrainingSession({
    required this.id,
    required this.name,
    required this.cells,
    required this.minutes,
    required this.equipment,
    required this.benefit,
    required this.dose,
    required this.schedule,
    required this.sourceAdvice,
    required this.audience,
    required this.requiresEquipment,
    required this.noLoad,
    required this.exercises,
    required this.source,
  });
}

class TrainingCell {
  final String id, name;
  const TrainingCell(this.id, this.name);
}

class TrainingPlace {
  final String id, name;
  final List<TrainingCell> cells;
  const TrainingPlace(this.id, this.name, this.cells);
}

class TrainingLibrary {
  static const asset = 'assets/training/sessions.json';
  final List<TrainingPlace> places;
  final List<TrainingSession> sessions;
  const TrainingLibrary(this.places, this.sessions);

  List<TrainingSession> forCell(String cell) => [
    for (final s in sessions)
      if (s.cells.contains(cell)) s,
  ];

  static Future<TrainingLibrary> load([
    Future<String> Function()? read,
  ]) async => parse(await (read ?? () => rootBundle.loadString(asset))());

  static TrainingLibrary parse(String text) {
    final data = jsonDecode(text) as Map<String, dynamic>;
    if (data['contract'] != 'trainforge.training-library/1') {
      throw const FormatException('Unknown training library');
    }
    String? opt(Map m, String k) => m[k] as String?;
    return TrainingLibrary(
      [
        for (final p in data['places'] as List)
          TrainingPlace(p['id'] as String, p['name'] as String, [
            for (final c in p['cells'] as List)
              TrainingCell(c['id'] as String, c['name'] as String),
          ]),
      ],
      [
        for (final s in data['sessions'] as List)
          TrainingSession(
            id: s['id'] as String,
            name: s['name'] as String,
            cells: [for (final c in s['cells'] as List) c as String],
            minutes: (s['minutes'] as num?)?.round(),
            equipment: opt(s, 'equipment'),
            benefit: opt(s, 'benefit'),
            dose: opt(s, 'dose'),
            schedule: opt(s, 'schedule'),
            sourceAdvice: opt(s, 'sourceAdvice'),
            audience: opt(s, 'audience'),
            requiresEquipment: opt(s, 'requiresEquipment'),
            noLoad: s['noLoad'] == true,
            exercises: [
              for (final e in s['exercises'] as List)
                TrainingExercise(
                  e['name'] as String,
                  opt(e, 'dose'),
                  opt(e, 'source'),
                  opt(e, 'benefit'),
                ),
            ],
            source: TrainingSource(
              s['source']['name'] as String,
              opt(s['source'], 'responsible'),
              opt(s['source'], 'url'),
              opt(s['source'], 'license'),
              opt(s['source'], 'locator'),
            ),
          ),
      ],
    );
  }
}
