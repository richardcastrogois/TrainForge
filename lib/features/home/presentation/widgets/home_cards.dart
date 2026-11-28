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
import 'package:trainforge/shared/widgets/shell_labels.dart';

String homeLabel(BuildContext context, String key) {
  final language = Localizations.localeOf(context).languageCode;
  return (_labels[language] ?? _labels['en']!)[key] ?? _labels['en']![key]!;
}

const _labels = <String, Map<String, String>>{
  'pt': {
    'tagline': 'Mais forte e saudável, todo dia',
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
    'nextPlace': 'Mostrar o próximo lugar',
    'seeWorkouts': 'Ver treinos',
  },
  'en': {
    'tagline': 'Stronger and healthier, every day',
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
    'nextPlace': 'Show the next place',
    'seeWorkouts': 'See workouts',
  },
  'es': {
    'tagline': 'Más fuerte y saludable, cada día',
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
    'nextPlace': 'Mostrar el siguiente lugar',
    'seeWorkouts': 'Ver entrenos',
  },
};

/// Top card: the places the person chose, crossfading when there is more than
/// one (still on reduced motion; a tap shows the next place instead).
class TrainingHeroCard extends StatefulWidget {
  final OnboardingProfile? profile;
  final Future<TrainingLibrary> Function() library;

  /// First use: a taller card with one big "Começar" (or "Responder 2
  /// perguntas" while answers are missing) instead of the small pill.
  final bool first;
  final VoidCallback? completeAnswers;
  const TrainingHeroCard({
    super.key,
    required this.profile,
    this.library = TrainingLibrary.load,
    this.first = false,
    this.completeAnswers,
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
        const shadow = [Shadow(color: Colors.black54, blurRadius: 8)];
        final missing =
            widget.completeAnswers != null &&
            (profile == null ||
                profile.places.isEmpty ||
                profile.confidence == null);
        final first = widget.first;
        final action = shellLabel(context, missing ? 'answerFirst' : 'start');
        return Semantics(
          button: true,
          label: first
              ? '$action. $title. $detail'
              : '${l('tagline')}. $title. $detail',
          onLongPressHint: list.length > 1 ? l('nextPlace') : null,
          child: Material(
            color: TrainForgeTheme.primary,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: missing ? widget.completeAnswers : () => open(place),
              onLongPress: list.length > 1 ? nextPlace : null,
              child: ExcludeSemantics(
                child: SizedBox(
                  // First use: the card fills most of the free space above
                  // the week, sized by the screen so nothing scrolls.
                  height: first
                      ? (MediaQuery.sizeOf(context).height * .44).clamp(
                          280.0,
                          430.0,
                        )
                      : 172,
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
                      // Dark at the bottom so the text stays readable.
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [.25, 1],
                            colors: [Colors.transparent, Color(0xd0102a25)],
                          ),
                        ),
                      ),
                      if (first)
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 14,
                          height: 58,
                          // Looks like a button; the whole card is the tap target.
                          child: GlassSurface(
                            borderRadius: BorderRadius.circular(18),
                            tint: TrainForgeTheme.highlight.withValues(
                              alpha: .92,
                            ),
                            blur: 10,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              // Large text sizes shrink to fit one line.
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      action,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: TrainForgeTheme.ink,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward,
                                      size: 24,
                                      color: TrainForgeTheme.ink,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (!first)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GlassSurface(
                            borderRadius: BorderRadius.circular(20),
                            tint: Colors.black.withValues(alpha: .28),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l('seeWorkouts'),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: first ? 86 : 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l('tagline').toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .4,
                                color: TrainForgeTheme.accent,
                                shadows: shadow,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedSwitcher(
                              duration: Duration(
                                milliseconds: reduced ? 0 : 400,
                              ),
                              child: Text(
                                title,
                                key: ValueKey(title),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  shadows: shadow,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    detail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      shadows: shadow,
                                    ),
                                  ),
                                ),
                                for (var i = 0; i < list.length; i++)
                                  if (list.length > 1)
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      width: list[i] == place ? 16 : 7,
                                      height: 7,
                                      margin: const EdgeInsets.only(left: 5),
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
                        ),
                      ),
                    ],
                  ),
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
