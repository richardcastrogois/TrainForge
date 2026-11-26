import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trainforge/core/motion/app_motion.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';

import 'onboarding_profile.dart';
import 'place_photos.dart';
import 'welcome_animation.dart';

String onboardingLabel(BuildContext context, String key) {
  final language = Localizations.localeOf(context).languageCode;
  return (_labels[language] ?? _labels['en']!)[key] ?? _labels['en']![key]!;
}

const _labels = <String, Map<String, String>>{
  'pt': {
    'back': 'Voltar',
    'next': 'Continuar',
    'finish': 'Começar',
    'skip': 'Pular',
    'step': 'Passo {n} de {t}',
    'genderTitle': 'Como você se identifica?',
    'genderHint': 'Opcional. Ajuda a deixar o app com a sua cara.',
    'woman': 'Mulher',
    'man': 'Homem',
    'nonbinary': 'Não binário',
    'other': 'Outra',
    'undisclosed': 'Prefiro não dizer',
    'heightTitle': 'Qual é a sua altura?',
    'weightTitle': 'Qual é o seu peso?',
    'bodyHint':
        'Opcional. Fica guardado só neste celular, e você pode apagar quando quiser.',
    'less': 'Diminuir',
    'more': 'Aumentar',
    'placesTitle': 'Onde você pensa em se exercitar?',
    'placesHint': 'Pode escolher mais de um lugar.',
    'casa': 'Em casa',
    'casaHint': 'Com o que tiver em casa',
    'praca': 'Na praça ou no parque',
    'pracaHint': 'Ao ar livre',
    'academia': 'Na academia',
    'academiaHint': 'Com aparelhos',
    'pausa': 'Treinos rápidos',
    'pausaHint': 'Poucos minutos, em qualquer lugar',
    'confidenceTitle': 'Como você se sente para se exercitar?',
    'confidenceHint':
        'É só um ponto de partida. Você pode mudar quando quiser.',
    'sentado': 'Prefiro começar sentado',
    'sentadoHint': 'Preciso de apoio ou canso rápido em pé',
    'iniciante': 'Estou começando agora',
    'inicianteHint': 'Ou voltando depois de um tempo parado',
    'intermediario': 'Já me exercito às vezes',
    'intermediarioHint': 'Algumas vezes por semana',
    'avancado': 'Me exercito com frequência',
    'avancadoHint': 'Treino quase todos os dias',
    'welcomeTitle': 'Vamos preparar o app para você',
    'welcomeHint':
        'São só algumas perguntas rápidas. Nenhuma é obrigatória e dá para mudar tudo depois.',
    'welcomeStart': 'Vamos lá',
    'noteTitle': 'Meu treino de hoje',
    'note1': 'Caminhar',
    'note2': 'Agachar na cadeira',
    'note3': 'Alongar',
    'redoTitle': 'Refazer perguntas iniciais',
    'redoHint': 'Lugar, nível e dados do corpo. Ficam só neste celular.',
  },
  'en': {
    'back': 'Back',
    'next': 'Continue',
    'finish': 'Start',
    'skip': 'Skip',
    'step': 'Step {n} of {t}',
    'genderTitle': 'How do you identify?',
    'genderHint': 'Optional. It helps make the app feel like yours.',
    'woman': 'Woman',
    'man': 'Man',
    'nonbinary': 'Non-binary',
    'other': 'Other',
    'undisclosed': 'Prefer not to say',
    'heightTitle': 'What is your height?',
    'weightTitle': 'What is your weight?',
    'bodyHint':
        'Optional. Stored only on this phone, and you can delete it anytime.',
    'less': 'Decrease',
    'more': 'Increase',
    'placesTitle': 'Where do you plan to exercise?',
    'placesHint': 'You can choose more than one place.',
    'casa': 'At home',
    'casaHint': 'With what you have at home',
    'praca': 'In a square or park',
    'pracaHint': 'Outdoors',
    'academia': 'At the gym',
    'academiaHint': 'With machines',
    'pausa': 'Quick workouts',
    'pausaHint': 'A few minutes, anywhere',
    'confidenceTitle': 'How do you feel about exercising?',
    'confidenceHint': 'Just a starting point. You can change it anytime.',
    'sentado': 'I prefer to start seated',
    'sentadoHint': 'I need support or tire quickly standing',
    'iniciante': 'I am just starting',
    'inicianteHint': 'Or coming back after a break',
    'intermediario': 'I exercise sometimes',
    'intermediarioHint': 'A few times a week',
    'avancado': 'I exercise often',
    'avancadoHint': 'Almost every day',
    'welcomeTitle': 'Let’s set the app up for you',
    'welcomeHint':
        'Just a few quick questions. None is required and you can change everything later.',
    'welcomeStart': 'Let’s go',
    'noteTitle': 'My workout today',
    'note1': 'Walk',
    'note2': 'Chair squats',
    'note3': 'Stretch',
    'redoTitle': 'Redo the first questions',
    'redoHint': 'Place, level and body data. Kept only on this phone.',
  },
  'es': {
    'back': 'Volver',
    'next': 'Continuar',
    'finish': 'Empezar',
    'skip': 'Omitir',
    'step': 'Paso {n} de {t}',
    'genderTitle': '¿Cómo te identificas?',
    'genderHint': 'Opcional. Ayuda a que la app se parezca a ti.',
    'woman': 'Mujer',
    'man': 'Hombre',
    'nonbinary': 'No binario',
    'other': 'Otra',
    'undisclosed': 'Prefiero no decirlo',
    'heightTitle': '¿Cuál es tu estatura?',
    'weightTitle': '¿Cuál es tu peso?',
    'bodyHint':
        'Opcional. Se guarda solo en este teléfono y puedes borrarlo cuando quieras.',
    'less': 'Disminuir',
    'more': 'Aumentar',
    'placesTitle': '¿Dónde piensas hacer ejercicio?',
    'placesHint': 'Puedes elegir más de un lugar.',
    'casa': 'En casa',
    'casaHint': 'Con lo que tengas en casa',
    'praca': 'En la plaza o el parque',
    'pracaHint': 'Al aire libre',
    'academia': 'En el gimnasio',
    'academiaHint': 'Con máquinas',
    'pausa': 'Entrenos rápidos',
    'pausaHint': 'Pocos minutos, en cualquier lugar',
    'confidenceTitle': '¿Cómo te sientes para hacer ejercicio?',
    'confidenceHint':
        'Es solo un punto de partida. Puedes cambiarlo cuando quieras.',
    'sentado': 'Prefiero empezar sentado',
    'sentadoHint': 'Necesito apoyo o me canso rápido de pie',
    'iniciante': 'Estoy empezando',
    'inicianteHint': 'O volviendo después de un tiempo',
    'intermediario': 'Hago ejercicio a veces',
    'intermediarioHint': 'Algunas veces por semana',
    'avancado': 'Hago ejercicio a menudo',
    'avancadoHint': 'Casi todos los días',
    'welcomeTitle': 'Vamos a preparar la app para ti',
    'welcomeHint':
        'Son solo unas preguntas rápidas. Ninguna es obligatoria y puedes cambiar todo después.',
    'welcomeStart': 'Vamos',
    'noteTitle': 'Mi entreno de hoy',
    'note1': 'Caminar',
    'note2': 'Sentadillas en la silla',
    'note3': 'Estirar',
    'redoTitle': 'Rehacer las preguntas iniciales',
    'redoHint': 'Lugar, nivel y datos del cuerpo. Solo en este teléfono.',
  },
};

const placeColors = {
  // Dark enough at both ends for white text (contrast at least 4.5:1).
  'casa': [Color(0xff215e52), Color(0xff3f8a76)],
  'praca': [Color(0xff2f6a2c), Color(0xff4e8a3e)],
  'academia': [Color(0xff24445e), Color(0xff3e6788)],
  'pausa': [Color(0xff7a4b12), Color(0xff9a6424)],
};

const placeIcons = {
  'casa': Icons.home_outlined,
  'praca': Icons.park_outlined,
  'academia': Icons.fitness_center,
  'pausa': Icons.timer_outlined,
};

/// First questions after the health-data decision, one per screen, big targets.
class OnboardingPage extends StatefulWidget {
  final OnboardingProfile? initial;

  /// Height and weight are asked only when health data was granted.
  final bool askBody;
  final ValueChanged<OnboardingProfile> onDone;
  const OnboardingPage({
    super.key,
    this.initial,
    required this.askBody,
    required this.onDone,
  });
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late OnboardingProfile answers = widget.initial ?? const OnboardingProfile();
  late final steps = [
    'welcome',
    'gender',
    if (widget.askBody) ...['height', 'weight'],
    'places',
    'confidence',
  ];
  int index = 0;
  late int height = answers.heightCm ?? 165, weight = answers.weightKg ?? 70;

  String get step => steps[index];
  bool get last => index == steps.length - 1;

  void go(int delta) {
    if (step == 'height') answers = answers.copyWith(heightCm: height);
    if (step == 'weight') answers = answers.copyWith(weightKg: weight);
    if (delta > 0 && last) {
      widget.onDone(answers.copyWith(completedAt: DateTime.now()));
      return;
    }
    setState(() => index = (index + delta).clamp(0, steps.length - 1));
  }

  void skip() {
    if (step == 'height') answers = answers.copyWith(clearHeight: true);
    if (step == 'weight') answers = answers.copyWith(clearWeight: true);
    if (last) {
      widget.onDone(answers.copyWith(completedAt: DateTime.now()));
      return;
    }
    setState(() => index++);
  }

  @override
  Widget build(BuildContext context) {
    String l(String k) => onboardingLabel(context, k);
    final reduced = AppMotion.reduced(context);
    final questions = steps.length - 1;
    return Scaffold(
      backgroundColor: context.tf.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (step != 'welcome')
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: l('step')
                            .replaceFirst('{n}', '$index')
                            .replaceFirst('{t}', '$questions'),
                        child: ExcludeSemantics(
                          child: Row(
                            children: [
                              for (var i = 1; i <= questions; i++)
                                Expanded(
                                  child: Container(
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: i <= index
                                          ? TrainForgeTheme.primary
                                          : context.tf.muted.withValues(
                                              alpha: .25,
                                            ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    TextButton(onPressed: skip, child: Text(l('skip'))),
                  ],
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: reduced ? 0 : 250),
                  child: KeyedSubtree(key: ValueKey(step), child: _content(l)),
                ),
              ),
              if (step == 'welcome')
                FilledButton(
                  style: _big,
                  onPressed: () => go(1),
                  child: Text(l('welcomeStart')),
                )
              else
                Row(
                  children: [
                    SizedBox.square(
                      dimension: 60,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () => go(-1),
                        child: Icon(Icons.arrow_back, semanticLabel: l('back')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('onboarding-next'),
                        style: _big,
                        onPressed: () => go(1),
                        child: Text(last ? l('finish') : l('next')),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static final _big = FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(60),
    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  );

  Widget _title(String title, String hint) => Column(
    children: [
      const SizedBox(height: 28),
      Semantics(
        header: true,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        hint,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, height: 1.4, color: context.tf.muted),
      ),
      const SizedBox(height: 24),
    ],
  );

  Widget _content(String Function(String) l) => switch (step) {
    'welcome' => _Centered(
      header: const SizedBox.shrink(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WelcomeAnimation(
            title: l('noteTitle'),
            lines: [l('note1'), l('note2'), l('note3')],
          ),
          _title(l('welcomeTitle'), l('welcomeHint')),
        ],
      ),
    ),
    'gender' => ListView(
      children: [
        _title(l('genderTitle'), l('genderHint')),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final g in OnboardingProfile.genders)
              _ChoiceBubble(
                label: l(g),
                icon: switch (g) {
                  'woman' => Icons.female,
                  'man' => Icons.male,
                  'nonbinary' => Icons.transgender,
                  'other' => Icons.diversity_3_outlined,
                  _ => Icons.lock_outline,
                },
                selected: answers.gender == g,
                onTap: () =>
                    setState(() => answers = answers.copyWith(gender: g)),
              ),
          ],
        ),
      ],
    ),
    'height' => _Centered(
      header: _title(l('heightTitle'), l('bodyHint')),
      child: _Ruler(
        value: height,
        min: 100,
        max: 220,
        unit: 'cm',
        color: TrainForgeTheme.primary.withValues(alpha: .06),
        less: l('less'),
        more: l('more'),
        onChanged: (v) => setState(() => height = v),
      ),
    ),
    'weight' => _Centered(
      header: _title(l('weightTitle'), l('bodyHint')),
      child: _Ruler(
        value: weight,
        min: 30,
        max: 200,
        unit: 'kg',
        color: TrainForgeTheme.primary.withValues(alpha: .06),
        less: l('less'),
        more: l('more'),
        onChanged: (v) => setState(() => weight = v),
      ),
    ),
    'places' => _Centered(
      header: _title(l('placesTitle'), l('placesHint')),
      child: Column(
        children: [
          for (final row in const [
            ['casa', 'praca'],
            ['academia', 'pausa'],
          ]) ...[
            Row(
              children: [
                for (final p in row) ...[
                  if (p != row.first) const SizedBox(width: 14),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: .82,
                      child: _PlaceTile(
                        place: p,
                        title: l(p),
                        hint: l('${p}Hint'),
                        gender: answers.gender,
                        selected: answers.places.contains(p),
                        onTap: () => setState(() {
                          final next = {...answers.places};
                          next.contains(p) ? next.remove(p) : next.add(p);
                          answers = answers.copyWith(places: next);
                        }),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (row.first == 'casa') const SizedBox(height: 14),
          ],
        ],
      ),
    ),
    _ => ListView(
      children: [
        _title(l('confidenceTitle'), l('confidenceHint')),
        _LevelMeter(selected: answers.confidence),
        const SizedBox(height: 20),
        for (final (i, c) in OnboardingProfile.confidences.indexed)
          _LevelOption(
            index: i,
            icon: _levelIcons[c]!,
            title: l(c),
            hint: l('${c}Hint'),
            selected: answers.confidence == c,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => answers = answers.copyWith(confidence: c));
            },
          ),
      ],
    ),
  };
}

/// Header on top and the content centred in the remaining height; scrolls when
/// the text is large or the screen is short.
class _Centered extends StatelessWidget {
  final Widget header, child;
  const _Centered({required this.header, required this.child});
  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(child: header),
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Center(child: child),
        ),
      ),
    ],
  );
}

class _PlaceTile extends StatelessWidget {
  final String place, title, hint;
  final String? gender;
  final bool selected;
  final VoidCallback onTap;
  const _PlaceTile({
    required this.place,
    required this.title,
    required this.hint,
    required this.gender,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final colors = placeColors[place]!;
    final reduced = AppMotion.reduced(context);
    final photos = placePhotos(place, gender);
    final width = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $hint',
      child: AnimatedScale(
        scale: selected ? 1.0 : .95,
        duration: Duration(milliseconds: reduced ? 0 : 180),
        curve: Curves.easeOutBack,
        child: Material(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(
              color: selected ? TrainForgeTheme.accent : Colors.transparent,
              width: 5,
            ),
          ),
          child: ExcludeSemantics(
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                  ),
                ),
                if (photos.isNotEmpty)
                  AnimatedScale(
                    scale: selected && !reduced ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    child: Image.asset(
                      photos.first,
                      fit: BoxFit.cover,
                      cacheWidth: (width / 2 * dpr).round().clamp(64, 1080),
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                // Scrim: keeps the white text readable on any photo.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, .35, 1],
                      colors: [
                        Colors.black.withValues(alpha: .35),
                        Colors.black.withValues(alpha: .05),
                        Colors.black.withValues(alpha: .8),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(placeIcons[place], size: 34, color: Colors.white),
                      const Spacer(),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 19,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hint,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: reduced ? 0 : 180),
                    transitionBuilder: (c, a) =>
                        ScaleTransition(scale: a, child: c),
                    child: selected
                        ? Container(
                            key: const ValueKey('on'),
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: TrainForgeTheme.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: TrainForgeTheme.primary,
                            ),
                          )
                        : Container(
                            key: const ValueKey('off'),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                  ),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceBubble extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceBubble({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    inMutuallyExclusiveGroup: true,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 128,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? TrainForgeTheme.accent : context.tf.surface,
                border: Border.all(
                  color: selected
                      ? TrainForgeTheme.primary
                      : context.tf.muted.withValues(alpha: .35),
                  width: selected ? 3 : 1.5,
                ),
              ),
              child: ExcludeSemantics(
                child: Icon(icon, size: 44, color: TrainForgeTheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            ExcludeSemantics(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

const _levelIcons = {
  'sentado': Icons.chair_alt_outlined,
  'iniciante': Icons.directions_walk,
  'intermediario': Icons.directions_run,
  'avancado': Icons.bolt,
};

/// Big badge plus rising bars that follow the chosen level.
class _LevelMeter extends StatelessWidget {
  final String? selected;
  const _LevelMeter({required this.selected});
  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final level = selected == null
        ? 0
        : OnboardingProfile.confidences.indexOf(selected!) + 1;
    final ms = Duration(milliseconds: reduced ? 0 : 450);
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedContainer(
            duration: ms,
            curve: Curves.easeOutBack,
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: level == 0
                  ? context.tf.muted.withValues(alpha: .15)
                  : TrainForgeTheme.accent,
            ),
            child: AnimatedSwitcher(
              duration: ms,
              transitionBuilder: (child, a) => RotationTransition(
                turns: Tween(begin: -.15, end: 0.0).animate(a),
                child: ScaleTransition(scale: a, child: child),
              ),
              child: Icon(
                _levelIcons[selected] ?? Icons.emoji_people,
                key: ValueKey(selected),
                size: 56,
                color: TrainForgeTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 20),
          for (var i = 1; i <= 4; i++)
            AnimatedContainer(
              duration: ms,
              curve: Curves.easeOutBack,
              margin: const EdgeInsets.only(left: 6),
              width: 16,
              height: i <= level ? 24.0 + i * 18 : 16,
              decoration: BoxDecoration(
                color: i <= level
                    ? TrainForgeTheme.primary
                    : context.tf.muted.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        ],
      ),
    );
  }
}

/// One level: slides in on entry; the chosen one fills with the brand color.
class _LevelOption extends StatelessWidget {
  final int index;
  final IconData icon;
  final String title, hint;
  final bool selected;
  final VoidCallback onTap;
  const _LevelOption({
    required this.index,
    required this.icon,
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final ms = Duration(milliseconds: reduced ? 0 : 280);
    final fg = selected ? Colors.white : TrainForgeTheme.ink;
    final card = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        label: '$title. $hint',
        child: AnimatedScale(
          scale: selected ? 1.0 : .97,
          duration: ms,
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: ms,
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: selected ? TrainForgeTheme.primary : context.tf.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected
                    ? TrainForgeTheme.primary
                    : context.tf.muted.withValues(alpha: .25),
                width: 1.5,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: TrainForgeTheme.primary.withValues(alpha: .3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onTap,
                child: ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: ms,
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: selected
                                ? TrainForgeTheme.accent
                                : TrainForgeTheme.primary.withValues(
                                    alpha: .08,
                                  ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            icon,
                            size: 30,
                            color: TrainForgeTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: ms,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: fg,
                                ),
                                child: Text(title),
                              ),
                              const SizedBox(height: 2),
                              AnimatedDefaultTextStyle(
                                duration: ms,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.3,
                                  color: selected
                                      ? Colors.white
                                      : context.tf.muted,
                                ),
                                child: Text(hint),
                              ),
                            ],
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: ms,
                          transitionBuilder: (c, a) =>
                              ScaleTransition(scale: a, child: c),
                          child: selected
                              ? const Icon(
                                  Icons.check_circle,
                                  key: ValueKey('on'),
                                  size: 28,
                                  color: TrainForgeTheme.accent,
                                )
                              : const SizedBox(key: ValueKey('off'), width: 28),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (reduced) return card;
    // Staggered entry: each option slides up a little later than the one above.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 110),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 40),
          child: child,
        ),
      ),
      child: card,
    );
  }
}

/// Big number with a draggable ruler and +/- buttons (easier for shaky hands).
class _Ruler extends StatefulWidget {
  final int value, min, max;
  final String unit, less, more;
  final Color color;
  final ValueChanged<int> onChanged;
  const _Ruler({
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.color,
    required this.less,
    required this.more,
    required this.onChanged,
  });
  @override
  State<_Ruler> createState() => _RulerState();
}

class _RulerState extends State<_Ruler> {
  static const tick = 14.0;
  late final controller = ScrollController(
    initialScrollOffset: (widget.value - widget.min) * tick,
  );

  @override
  void didUpdateWidget(covariant _Ruler old) {
    super.didUpdateWidget(old);
    final target = (widget.value - widget.min) * tick;
    if (controller.hasClients &&
        (controller.offset - target).abs() > tick / 2) {
      controller.jumpTo(target);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void set(int v) {
    final next = v.clamp(widget.min, widget.max);
    if (next != widget.value) {
      HapticFeedback.selectionClick();
      widget.onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 24),
    decoration: BoxDecoration(
      color: widget.color,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: TrainForgeTheme.primary.withValues(alpha: .12)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          slider: true,
          value: '${widget.value} ${widget.unit}',
          increasedValue:
              '${(widget.value + 1).clamp(widget.min, widget.max)} ${widget.unit}',
          decreasedValue:
              '${(widget.value - 1).clamp(widget.min, widget.max)} ${widget.unit}',
          onIncrease: () => set(widget.value + 1),
          onDecrease: () => set(widget.value - 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                iconSize: 30,
                onPressed: () => set(widget.value - 1),
                icon: Icon(Icons.remove, semanticLabel: widget.less),
              ),
              const SizedBox(width: 16),
              ExcludeSemantics(
                child: Text.rich(
                  TextSpan(
                    text: '${widget.value}',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      color: TrainForgeTheme.ink,
                    ),
                    children: [
                      TextSpan(
                        text: ' ${widget.unit}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton.filledTonal(
                iconSize: 30,
                onPressed: () => set(widget.value + 1),
                icon: Icon(Icons.add, semanticLabel: widget.more),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ExcludeSemantics(
          child: SizedBox(
            height: 70,
            child: LayoutBuilder(
              builder: (context, box) {
                final pad = box.maxWidth / 2 - tick / 2;
                return Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    NotificationListener<ScrollEndNotification>(
                      onNotification: (_) {
                        final snapped =
                            widget.min + (controller.offset / tick).round();
                        set(snapped);
                        controller.animateTo(
                          (snapped.clamp(widget.min, widget.max) - widget.min) *
                              tick,
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                        );
                        return false;
                      },
                      child: NotificationListener<ScrollUpdateNotification>(
                        onNotification: (_) {
                          set(widget.min + (controller.offset / tick).round());
                          return false;
                        },
                        child: ListView.builder(
                          controller: controller,
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: pad),
                          itemExtent: tick,
                          itemCount: widget.max - widget.min + 1,
                          itemBuilder: (context, i) {
                            final v = widget.min + i;
                            final major = v % 10 == 0;
                            return Column(
                              children: [
                                Container(
                                  width: 2,
                                  height: major ? 34 : (v % 5 == 0 ? 24 : 14),
                                  color: TrainForgeTheme.ink.withValues(
                                    alpha: major ? .9 : .45,
                                  ),
                                ),
                                if (major)
                                  SizedBox(
                                    height: 20,
                                    child: OverflowBox(
                                      maxWidth: 40,
                                      child: Text(
                                        '$v',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: TrainForgeTheme.ink,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    Container(
                      width: 3,
                      height: 44,
                      color: TrainForgeTheme.primary,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}
