import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trainforge/core/l10n/feedback_localization.dart';
import 'package:trainforge/core/l10n/language_page.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/core/motion/app_motion.dart';
import 'package:trainforge/core/theme/brand_mark.dart';
import 'package:trainforge/core/theme/appearance_page.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/privacy/presentation/privacy_page.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/shared/widgets/auth_gate.dart';
import '../auth_controller.dart';
import '../widgets/entry_scene.dart';
import '../widgets/google_sign_in_button.dart';
import 'guest_page.dart';

/// Signed-out entry. On the first open of each launch it plays the brand
/// sequence on the same green canvas (grid wave, heartbeat, ECG) and then
/// settles into the entry: one decision (Google) and one escape (explore).
class AuthPage extends StatefulWidget {
  final AuthController? controller;
  const AuthPage({super.key, this.controller});

  /// Whether this launch already played the full sequence.
  static bool playedThisLaunch = false;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  late final AnimationController master = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: EntryTimeline.total.round()),
  );
  late final AnimationController beat = AnimationController(
    vsync: this,
    duration: EntryTimeline.beat,
  );
  late final AnimationController idle = AnimationController(
    vsync: this,
    duration: EntryTimeline.idleBeat,
  );
  late final AnimationController pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  final stackKey = GlobalKey(), ringsKey = GlobalKey(), wordKey = GlobalKey();
  Rect? ringsRect, wordRect;
  bool started = false, motion = false;

  /// Ring values the person sets by dragging; [lowered] is the ring last
  /// brought below its starting value (its guidance sentence is shown).
  final values = EntryRingsPainter.initialValues;
  int? lowered, dragging;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    motion = AppMotion.ambient && !AppMotion.reduced(context);
    final play = motion && !AuthPage.playedThisLaunch;
    if (!play) {
      master.value = 1;
      if (motion) idle.repeat();
      return;
    }
    AuthPage.playedThisLaunch = true;
    beat.repeat();
    master.forward().whenComplete(() {
      if (!mounted) return;
      beat.stop();
      idle.repeat();
    });
  }

  @override
  void dispose() {
    master.dispose();
    beat.dispose();
    idle.dispose();
    pulse.dispose();
    super.dispose();
  }

  void skip() {
    if (master.value < 1) master.value = 1;
  }

  void measure() {
    final stack = stackKey.currentContext?.findRenderObject() as RenderBox?;
    Rect? rectOf(GlobalKey key) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (stack == null || box == null || !box.hasSize) return null;
      return box.localToGlobal(Offset.zero, ancestor: stack) & box.size;
    }

    ringsRect = rectOf(ringsKey);
    wordRect = rectOf(wordKey);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (controller == null) return AuthGate();
    return Scaffold(
      backgroundColor: TrainForgeTheme.canvas,
      body: AnimatedBuilder(
        animation: Listenable.merge([master, beat, idle, pulse]),
        builder: (context, _) {
          final t = master.value * EntryTimeline.total;
          if (t < EntryTimeline.bigEnd) {
            WidgetsBinding.instance.addPostFrameCallback((_) => measure());
          }
          // The canvas runs behind a transparent navigation bar: no system
          // scrim over the splash, light icons on green, dark icons once the
          // login sheet (which already pads for the bar) covers the bottom.
          final sheetUp = EntryTimeline.span(t, 4750, 5450) > .5;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarContrastEnforced: false,
              systemNavigationBarIconBrightness: sheetUp
                  ? Brightness.dark
                  : Brightness.light,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: t < EntryTimeline.bigEnd ? skip : null,
              child: LayoutBuilder(
                builder: (context, box) => Stack(
                  key: stackKey,
                  children: [
                    ..._backdrop(t, box.biggest),
                    _content(context, controller, t),
                    ..._actors(context, t, box.biggest),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  RingGeometry? _geometry() {
    final box = ringsKey.currentContext?.findRenderObject() as RenderBox?;
    return box == null || !box.hasSize ? null : RingGeometry(box.size);
  }

  void _setRing(int i, double value) {
    final v = value.clamp(.05, 1.0);
    final prev = values[i];
    if (v == prev) return;
    if ((v * 10).floor() != (prev * 10).floor()) {
      HapticFeedback.selectionClick();
    }
    final start = EntryRingsPainter.initialValues[i];
    setState(() {
      values[i] = v;
      if (v < prev && v < start) {
        lowered = i;
      } else if (lowered == i && v >= start) {
        lowered = null;
      }
    });
  }

  void _drag(Offset p) {
    final g = _geometry(), i = dragging;
    if (g == null || i == null) return;
    final v = g.fraction(p);
    // Ignore the jump across 12 o'clock; the ring follows the finger.
    if ((v - values[i]).abs() > .5) return;
    _setRing(i, v);
  }

  void _tap(Offset p) {
    final g = _geometry();
    if (g == null) return;
    if (g.onTile(p)) return _pulse();
    final i = g.ringAt(p);
    if (i != null) _setRing(i, g.fraction(p));
  }

  void _pulse() {
    HapticFeedback.mediumImpact();
    if (motion || !AppMotion.reduced(context)) pulse.forward(from: 0);
  }

  Widget _rings(BuildContext context, double t) {
    final settled = t >= EntryTimeline.bigEnd;
    final names = [
      context.l10n.brandTraining,
      context.l10n.brandFood,
      context.l10n.brandProgress,
    ];
    String pct(double v) => '${(v.clamp(.05, 1.0) * 100).round()}%';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: settled ? (d) => _tap(d.localPosition) : null,
      onPanStart: settled
          ? (d) => dragging = _geometry()?.ringAt(d.localPosition)
          : null,
      onPanUpdate: settled ? (d) => _drag(d.localPosition) : null,
      onPanEnd: settled ? (_) => dragging = null : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            key: ringsKey,
            painter: EntryRingsPainter(
              t: t,
              idle: idle.value,
              pulse: pulse.value,
              values: values,
              showCenter: settled,
            ),
            child: const SizedBox(height: 140, width: double.infinity),
          ),
          for (var i = 0; i < values.length; i++)
            Positioned(
              left: 0,
              top: 0,
              width: 1,
              height: 1,
              child: Semantics(
                slider: true,
                label: names[i],
                value: pct(values[i]),
                increasedValue: pct(values[i] + .1),
                decreasedValue: pct(values[i] - .1),
                onIncrease: () => _setRing(i, values[i] + .1),
                onDecrease: () => _setRing(i, values[i] - .1),
                child: const SizedBox.shrink(),
              ),
            ),
          Positioned(
            left: 0,
            top: 0,
            width: 1,
            height: 1,
            child: Semantics(
              button: true,
              label: context.l10n.logoPulse,
              onTap: _pulse,
              child: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  /// Big mark position: screen centre during the splash, rings centre after.
  (Offset, double) _mark(double t, Size size) {
    final start = size.center(Offset.zero);
    final rings = ringsRect;
    if (rings == null) return (start, 124);
    final target = rings.center;
    final targetSize = 64 * (rings.shortestSide.clamp(0, 320) / 300);
    final m = EntryTimeline.span(
      t,
      4120,
      EntryTimeline.bigEnd,
      EntryTimeline.glide,
    );
    return (Offset.lerp(start, target, m)!, 124 + (targetSize - 124) * m);
  }

  List<Widget> _backdrop(double t, Size size) {
    if (t >= EntryTimeline.bigEnd + 100) return const [];
    final (center, markSize) = _mark(t, size);
    final grid =
        EntryTimeline.span(t, 0, 400) *
        (1 - EntryTimeline.span(t, EntryTimeline.settle, 4600));
    return [
      Positioned.fill(
        child: ExcludeSemantics(
          child: CustomPaint(
            painter: EntryBackdropPainter(
              t: t,
              beat: beat.value,
              gridOpacity: grid,
              markCenter: center,
              markSize: markSize,
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _actors(BuildContext context, double t, Size size) {
    if (t >= EntryTimeline.bigEnd) return const [];
    final (center, markSize) = _mark(t, size);
    final settling = EntryTimeline.span(
      t,
      EntryTimeline.settle,
      EntryTimeline.bigEnd,
    );
    final heart = settling > 0 ? 1.0 : heartScale((t - 200) / 2000 % 1);
    final wordIn = EntryTimeline.span(t, 2900, 3350);
    final wordMove = EntryTimeline.span(
      t,
      EntryTimeline.settle,
      4780,
      EntryTimeline.glide,
    );
    final tagIn =
        EntryTimeline.span(t, 3080, 3530) *
        (1 - EntryTimeline.span(t, EntryTimeline.settle, 4200));
    final wordStart = Offset(size.width / 2, size.height / 2 + 102);
    final word = wordRect;
    final wordAt = word == null
        ? wordStart
        : Offset.lerp(wordStart, word.center, wordMove)!;
    final wordScale = 1 - (1 - 23 / 30) * wordMove;
    final s = markSize * heart;
    return [
      Positioned(
        left: center.dx - s / 2,
        top: center.dy - s / 2,
        width: s,
        height: s,
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: TrainForgeTheme.deep,
              borderRadius: BorderRadius.circular(s * 38 / 124),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 30,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: CustomPaint(painter: TrainForgeMarkPainter()),
          ),
        ),
      ),
      if (t < EntryTimeline.headerIn)
        Positioned(
          left: 0,
          right: 0,
          top: wordAt.dy - 20,
          child: ExcludeSemantics(
            child: Transform.translate(
              offset: Offset(wordAt.dx - size.width / 2, (1 - wordIn) * 14),
              child: Transform.scale(
                scale: wordScale,
                child: Opacity(
                  opacity: wordIn,
                  child: const Text(
                    'TrainForge',
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 30,
                      height: 1.33,
                      fontWeight: FontWeight.w700,
                      color: TrainForgeTheme.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      Positioned(
        left: 16,
        right: 16,
        top: size.height / 2 + 128,
        child: ExcludeSemantics(
          child: Opacity(
            opacity: tagIn * .9,
            child: Text(
              context.l10n.brandPillars,
              textAlign: TextAlign.center,
              textScaler: TextScaler.noScaling,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -.1,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _content(BuildContext context, AuthController controller, double t) {
    final busy = controller.busy;
    double rise(int k) => EntryTimeline.span(t, 4500 + k * 110, 4920 + k * 110);
    Widget enter(int k, Widget child) {
      final v = rise(k);
      return Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 16),
          child: child,
        ),
      );
    }

    final header = EntryTimeline.span(
      t,
      EntryTimeline.headerIn,
      5200,
      const Cubic(.2, 1.4, .4, 1),
    );
    final sheet = EntryTimeline.span(t, 4750, 5450, EntryTimeline.glide);
    final revealed = t >= EntryTimeline.reveal;
    const mist = Color(0xe0f6f6f1); // ~5:1 on the canvas green (WCAG AA)
    return IgnorePointer(
      ignoring: !revealed,
      child: ExcludeSemantics(
        excluding: !revealed,
        child: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 18, 12, 0),
                            child: Row(
                              children: [
                                Semantics(
                                  label: 'TrainForge',
                                  child: Opacity(
                                    opacity: header.clamp(0.0, 1.0),
                                    child: Transform.scale(
                                      scale: .4 + .6 * header,
                                      child: const TrainForgeMark(
                                        size: 36,
                                        background: TrainForgeTheme.deep,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Opacity(
                                    opacity: t >= EntryTimeline.headerIn
                                        ? 1
                                        : 0,
                                    // One line always; shrinks on very narrow
                                    // screens or with large text instead of wrapping.
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'TrainForge',
                                        key: wordKey,
                                        maxLines: 1,
                                        softWrap: false,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 23,
                                          fontWeight: FontWeight.w700,
                                          color: TrainForgeTheme.accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                enter(
                                  0,
                                  IconButton(
                                    tooltip: context.l10n.moreOptions,
                                    onPressed: busy
                                        ? null
                                        : () => _showMoreOptions(context),
                                    icon: const Icon(
                                      Icons.more_horiz,
                                      color: TrainForgeTheme.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                            child: enter(
                              1,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      context.l10n.welcome,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    context.l10n.welcomeHint,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.35,
                                      color: mist,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                              child: _rings(context, t),
                            ),
                          ),
                          enter(
                            2,
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                              // Always two lines tall, top-aligned: a longer
                              // guidance sentence never pushes the rings up.
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight:
                                      MediaQuery.textScalerOf(
                                        context,
                                      ).scale(15) *
                                      1.35 *
                                      2,
                                ),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Semantics(
                                    liveRegion: true,
                                    child: AnimatedSwitcher(
                                      duration: motion
                                          ? AppMotion.duration
                                          : Duration.zero,
                                      layoutBuilder: (current, previous) =>
                                          Stack(
                                            alignment: Alignment.topCenter,
                                            children: [...previous, ?current],
                                          ),
                                      child: _caption(context),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          FractionalTranslation(
                            translation: Offset(0, 1.05 * (1 - sheet)),
                            child: _sheet(context, controller, busy),
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
      ),
    );
  }

  /// What the rings mean, or why the lowered pillar matters.
  Widget _caption(BuildContext context) {
    final i = lowered;
    if (i == null) {
      return Column(
        key: const ValueKey('tagline'),
        children: [
          Text(
            context.l10n.brandTagline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: Color(0xe6f6f6f1),
            ),
          ),
        ],
      );
    }
    final sentence = [
      context.l10n.ringTrainingLow,
      context.l10n.ringFoodLow,
      context.l10n.ringProgressLow,
    ][i];
    return Row(
      key: ValueKey('ring-$i'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: EntryRingsPainter.rings[i].$2,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            sentence,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: Color(0xf2f6f6f1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sheet(BuildContext context, AuthController controller, bool busy) =>
      Theme(
        data: TrainForgeTheme.light,
        child: Builder(
          builder: (context) => Container(
            decoration: const BoxDecoration(
              color: TrainForgeTheme.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 30,
                  offset: Offset(0, -12),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              22,
              24,
              12 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (controller.feedback != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      controller.feedback!.localized(context),
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: TrainForgeTheme.ink,
                      ),
                    ),
                  ),
                  if (controller.failedAction != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: busy ? null : controller.retry,
                        child: Text(context.l10n.retry),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
                if (busy) AppProgress(label: context.l10n.waitingGoogle),
                GoogleSignInButton(
                  label: busy
                      ? context.l10n.connecting
                      : context.l10n.signInGoogle,
                  onPressed: busy ? null : controller.login,
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: TrainForgeTheme.primary,
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    onPressed: busy
                        ? null
                        : () => _showFirstAccess(context, controller),
                    child: Text(context.l10n.firstAccessLink),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: TrainForgeTheme.primary,
                  ),
                  onPressed: busy
                      ? null
                      : () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GuestPage(controller: controller),
                          ),
                        ),
                  child: Text(context.l10n.exploreWithoutAccount),
                ),
              ],
            ),
          ),
        ),
      );

  /// "First time?" explainer: how the account is created, what is stored,
  /// and the option to look around without an account.
  void _showFirstAccess(BuildContext context, AuthController controller) {
    final steps = [
      (context.l10n.firstAccessStep1Title, context.l10n.firstAccessStep1Body),
      (context.l10n.firstAccessStep2Title, context.l10n.firstAccessStep2Body),
      (context.l10n.firstAccessStep3Title, context.l10n.firstAccessStep3Body),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: TrainForgeTheme.background,
      builder: (sheet) => Theme(
        data: TrainForgeTheme.light,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    context.l10n.firstAccessTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: TrainForgeTheme.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final (i, (title, body)) in steps.indexed) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: TrainForgeTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: TrainForgeTheme.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: TrainForgeTheme.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              body,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: TrainForgeTheme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                GoogleSignInButton(
                  label: context.l10n.signInGoogle,
                  onPressed: () {
                    Navigator.pop(sheet);
                    controller.login();
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: TrainForgeTheme.primary,
                  ),
                  onPressed: () {
                    Navigator.pop(sheet);
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GuestPage(controller: controller),
                      ),
                    );
                  },
                  child: Text(context.l10n.exploreWithoutAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    void open(Widget Function() page) {
      Navigator.pop(context);
      Navigator.push<void>(context, MaterialPageRoute(builder: (_) => page()));
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.contrast),
              title: Text(context.l10n.appearance),
              onTap: () => open(() => const AppearancePage()),
            ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: Text(context.l10n.language),
              onTap: () => open(() => const LanguagePage()),
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text(context.l10n.privacy),
              onTap: () => open(() => PrivacyPage()),
            ),
          ],
        ),
      ),
    );
  }
}
