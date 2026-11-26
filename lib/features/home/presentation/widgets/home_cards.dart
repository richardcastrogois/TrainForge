import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trainforge/core/motion/app_motion.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/onboarding/onboarding_page.dart';
import 'package:trainforge/features/onboarding/onboarding_profile.dart';
import 'package:trainforge/features/onboarding/place_photos.dart';
import 'package:trainforge/features/training_library/data/training_library.dart';
import 'package:trainforge/features/training_library/presentation/training_library_page.dart';
import 'package:trainforge/shared/widgets/glass_surface.dart';

String homeLabel(BuildContext context, String key) {
  final language = Localizations.localeOf(context).languageCode;
  return (_labels[language] ?? _labels['en']!)[key] ?? _labels['en']![key]!;
}

const _labels = <String, Map<String, String>>{
  'pt': {
    'tagline': 'Um pouco mais forte e saudável, todos os dias',
    'casa': 'Treino em casa',
    'praca': 'Treino na praça',
    'academia': 'Treino na academia',
    'pausa': 'Treinos rápidos',
    'any': 'O seu treino',
    'sessions': '{n} treinos',
    'minutes': '{a}–{b} min',
    'sentado': 'Começando sentado',
    'iniciante': 'Iniciante',
    'intermediario': 'Intermediário',
    'avancado': 'Avançado',
    'chooseLevel': 'Escolha como começar',
    'buildTitle': 'Montar meu treino',
    'buildHint': 'Toque aqui e escolha o treino de hoje.',
    'buildMissing':
        'Responda duas perguntas rápidas para sugerirmos o treino certo.',
    'nextPlace': 'Mostrar o próximo lugar',
    'seeWorkouts': 'Ver treinos',
  },
  'en': {
    'tagline': 'A little stronger and healthier, every day',
    'casa': 'Workout at home',
    'praca': 'Workout in the park',
    'academia': 'Workout at the gym',
    'pausa': 'Quick workouts',
    'any': 'Your workout',
    'sessions': '{n} workouts',
    'minutes': '{a}–{b} min',
    'sentado': 'Starting seated',
    'iniciante': 'Beginner',
    'intermediario': 'Intermediate',
    'avancado': 'Advanced',
    'chooseLevel': 'Choose how to start',
    'buildTitle': 'Build my workout',
    'buildHint': 'Tap here and choose today’s workout.',
    'buildMissing':
        'Answer two quick questions so we can suggest the right workout.',
    'nextPlace': 'Show the next place',
    'seeWorkouts': 'See workouts',
  },
  'es': {
    'tagline': 'Un poco más fuerte y saludable, todos los días',
    'casa': 'Entreno en casa',
    'praca': 'Entreno en el parque',
    'academia': 'Entreno en el gimnasio',
    'pausa': 'Entrenos rápidos',
    'any': 'Tu entreno',
    'sessions': '{n} entrenos',
    'minutes': '{a}–{b} min',
    'sentado': 'Empezando sentado',
    'iniciante': 'Principiante',
    'intermediario': 'Intermedio',
    'avancado': 'Avanzado',
    'chooseLevel': 'Elige cómo empezar',
    'buildTitle': 'Armar mi entreno',
    'buildHint': 'Toca aquí y elige el entreno de hoy.',
    'buildMissing':
        'Responde dos preguntas rápidas para sugerirte el entreno adecuado.',
    'nextPlace': 'Mostrar el siguiente lugar',
    'seeWorkouts': 'Ver entrenos',
  },
};

/// Top card: the places the person chose, crossfading when there is more than
/// one (still on reduced motion; a tap shows the next place instead).
class TrainingHeroCard extends StatefulWidget {
  final OnboardingProfile? profile;
  final Future<TrainingLibrary> Function() library;
  const TrainingHeroCard({
    super.key,
    required this.profile,
    this.library = TrainingLibrary.load,
  });
  @override
  State<TrainingHeroCard> createState() => _TrainingHeroCardState();
}

class _TrainingHeroCardState extends State<TrainingHeroCard> {
  late final Future<TrainingLibrary> library = widget.library();
  Timer? timer;
  int shown = 0;

  List<String> get places {
    final chosen = widget.profile?.places ?? const <String>{};
    return [
      for (final p in OnboardingProfile.placeIds)
        if (chosen.contains(p)) p,
    ];
  }

  /// (place, photo) pairs shown in turn: a few photos of each chosen place, or
  /// one of every place while nothing was chosen.
  List<(String?, String?)> get slides {
    final gender = widget.profile?.gender, chosen = places;
    if (chosen.isEmpty) {
      return [
        for (final p in OnboardingProfile.placeIds)
          (null, placePhotos(p, gender).firstOrNull),
      ];
    }
    final each = chosen.length == 1 ? 4 : 2;
    final out = <(String?, String?)>[
      for (final p in chosen)
        for (final photo in placePhotos(p, gender).take(each)) (p, photo),
    ];
    return out.isEmpty ? [for (final p in chosen) (p, null)] : out;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    timer?.cancel();
    if (AppMotion.ambient && !AppMotion.reduced(context)) {
      timer = Timer.periodic(const Duration(seconds: 5), (_) {
        final all = slides;
        if (!mounted || all.length < 2) return;
        setState(() => shown = (shown + 1) % all.length);
        final next = all[(shown + 1) % all.length].$2;
        if (next != null) precacheImage(AssetImage(next), context);
      });
    }
  }

  /// Long press: first photo of the next chosen place.
  void nextPlace() {
    final all = slides, now = all[shown % all.length].$1;
    for (var i = 1; i <= all.length; i++) {
      final j = (shown + i) % all.length;
      if (all[j].$1 != now) {
        setState(() => shown = j);
        return;
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void open(String? place) {
    final profile = widget.profile;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingLibraryPage(
          initialPlace: place,
          initialCell: place == null || profile == null
              ? null
              : profile.cellFor(place),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = places, all = slides;
    final (place, photo) = all[shown % all.length];
    final reduced = AppMotion.reduced(context);
    String l(String k) => homeLabel(context, k);
    return FutureBuilder<TrainingLibrary>(
      future: library,
      builder: (context, snapshot) {
        final lib = snapshot.data;
        final profile = widget.profile;
        String detail = l('chooseLevel');
        if (lib != null && place != null && profile?.confidence != null) {
          final sessions = lib.forCell(profile!.cellFor(place));
          final minutes = [
            for (final s in sessions)
              if (s.minutes != null) s.minutes!,
          ]..sort();
          detail = [
            l(profile.confidence!),
            if (minutes.isNotEmpty)
              minutes.first == minutes.last
                  ? '${minutes.first} min'
                  : l('minutes')
                        .replaceFirst('{a}', '${minutes.first}')
                        .replaceFirst('{b}', '${minutes.last}'),
            l('sessions').replaceFirst('{n}', '${sessions.length}'),
          ].join(' · ');
        }
        final title = place == null ? l('any') : l(place);
        return Semantics(
          button: true,
          label: '${l('tagline')}. $title. $detail',
          onLongPressHint: list.length > 1 ? l('nextPlace') : null,
          child: Material(
            color: TrainForgeTheme.primary,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => open(place),
              onLongPress: list.length > 1 ? nextPlace : null,
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 200,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedSwitcher(
                            duration: Duration(milliseconds: reduced ? 0 : 900),
                            child: _PlaceArt(
                              key: ValueKey('$place/$photo'),
                              place: place,
                              photo: photo,
                            ),
                          ),
                          Positioned(
                            left: 14,
                            bottom: 14,
                            child: GlassSurface(
                              borderRadius: BorderRadius.circular(24),
                              tint: Colors.black.withValues(alpha: .28),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l('seeWorkouts'),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.arrow_forward,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l('tagline').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .3,
                              color: TrainForgeTheme.accent,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedSwitcher(
                            duration: Duration(milliseconds: reduced ? 0 : 400),
                            child: Text(
                              title,
                              key: ValueKey(title),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            detail,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          if (list.length > 1) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                for (var i = 0; i < list.length; i++)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: list[i] == place ? 18 : 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: list[i] == place
                                          ? TrainForgeTheme.accent
                                          : Colors.white54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                              ],
                            ),
                          ],
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
}

class _PlaceArt extends StatelessWidget {
  final String? place, photo;
  const _PlaceArt({super.key, required this.place, required this.photo});
  @override
  Widget build(BuildContext context) {
    final colors =
        placeColors[place] ?? const [Color(0xff2f7a6a), Color(0xffd8eb90)];
    final illustration = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          placeIcons[place] ?? Icons.favorite_outline,
          size: 84,
          color: Colors.white.withValues(alpha: .9),
        ),
      ),
    );
    final file = photo;
    if (file == null) return SizedBox.expand(child: illustration);
    final image = Image.asset(
      file,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth:
          (MediaQuery.sizeOf(context).width *
                  MediaQuery.devicePixelRatioOf(context))
              .round()
              .clamp(64, 1080),
      errorBuilder: (_, _, _) => illustration,
    );
    // Slow zoom while the photo is on screen; still with reduced motion.
    return SizedBox.expand(
      child: ClipRect(
        child: !AppMotion.ambient || AppMotion.reduced(context)
            ? image
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 1, end: 1.1),
                duration: const Duration(seconds: 6),
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: image,
              ),
      ),
    );
  }
}

/// Empty state: one big "+" that leads to the workout, or to the missing answers.
class BuildWorkoutCard extends StatelessWidget {
  final OnboardingProfile? profile;
  final VoidCallback completeAnswers;
  const BuildWorkoutCard({
    super.key,
    required this.profile,
    required this.completeAnswers,
  });

  bool get missing =>
      profile == null || profile!.places.isEmpty || profile!.confidence == null;

  @override
  Widget build(BuildContext context) {
    String l(String k) => homeLabel(context, k);
    final place = profile?.places.isEmpty ?? true
        ? null
        : OnboardingProfile.placeIds.firstWhere(
            (p) => profile!.places.contains(p),
          );
    return Semantics(
      button: true,
      label:
          '${l('buildTitle')}. ${missing ? l('buildMissing') : l('buildHint')}',
      child: Material(
        color: TrainForgeTheme.accent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: missing
              ? completeAnswers
              : () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrainingLibraryPage(
                      initialPlace: place,
                      initialCell: place == null
                          ? null
                          : profile!.cellFor(place),
                    ),
                  ),
                ),
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: TrainForgeTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 44, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l('buildTitle'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: TrainForgeTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          missing ? l('buildMissing') : l('buildHint'),
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.35,
                            color: TrainForgeTheme.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
