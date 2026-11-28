import 'package:flutter/material.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';

/// "Água" from the bundled catalog (same food the photo and voice use).
/// The diary keeps grams, its source basis; on screen 1 g of water ≈ 1 ml.
const waterFoodId =
    'food:4ecb104ae98ff16f4204ed8d0c6cfbaa86b7ec9e87a8003d99760fd8dd319bbb';
const waterFoodVersion =
    '52d114284f9d721495a8668b72f768e0163f6989bd65ffbe9616f4089fb4e72f';

String _label(BuildContext context, String key) {
  final language = context.l10n.localeName.split('_').first;
  return (_labels[language] ?? _labels['pt']!)[key]!;
}

const _labels = {
  'pt': {
    'title': 'Água de hoje',
    'glass': '+ 1 copo',
    'bottle': '+ 1 garrafa',
    'added': 'Água registrada',
    'undo': 'Desfazer',
    'failed': 'Não foi possível registrar agora. Tente de novo.',
  },
  'en': {
    'title': 'Water today',
    'glass': '+ 1 glass',
    'bottle': '+ 1 bottle',
    'added': 'Water recorded',
    'undo': 'Undo',
    'failed': 'Could not record now. Try again.',
  },
  'es': {
    'title': 'Agua de hoy',
    'glass': '+ 1 vaso',
    'bottle': '+ 1 botella',
    'added': 'Agua registrada',
    'undo': 'Deshacer',
    'failed': 'No se pudo registrar ahora. Inténtalo de nuevo.',
  },
};

/// One-tap water: total of the day and two big buttons (200 ml and 500 ml,
/// the volume is written on the button). Each tap is an ordinary diary
/// entry, so it syncs, exports and deletes like any other.
class HydrationCard extends StatefulWidget {
  final NutritionRepository repository;
  final DateTime Function() now;

  /// Called after a change so the day summary reloads.
  final VoidCallback? changed;

  /// Food page layout: total, eight drops (each 1/8 of [goalMl]) and the
  /// two buttons, in a white card.
  final bool compact;
  final int? goalMl;

  /// Gets the day's total whenever it is read again.
  final ValueChanged<int>? onTotal;
  const HydrationCard({
    super.key,
    required this.repository,
    this.now = DateTime.now,
    this.changed,
    this.compact = false,
    this.goalMl,
    this.onTotal,
  });
  @override
  State<HydrationCard> createState() => _HydrationCardState();
}

class _HydrationCardState extends State<HydrationCard> {
  int? total;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final now = widget.now();
    var sum = 0.0;
    String? cursor;
    try {
      do {
        final page = await widget.repository.entries(
          localDay(now),
          offsetZone(now),
          cursor: cursor,
        );
        for (final item in page.items) {
          if (item['foodId'] == waterFoodId && item['deletedAt'] == null) {
            sum += double.tryParse('${item['quantity']}') ?? 0;
          }
        }
        cursor = page.cursor;
      } while (cursor != null);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() => total = sum.round());
    widget.onTotal?.call(total!);
  }

  Future<void> add(int ml) async {
    if (busy) return;
    setState(() => busy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final when = widget.now();
    try {
      final saved = await widget.repository.saveEntry({
        'foodId': waterFoodId,
        'foodVersion': waterFoodVersion,
        'quantity': '$ml',
        'unit': 'g',
        'preparation': '',
        'occurredAt': when.toUtc().toIso8601String(),
        'timezone': offsetZone(when),
        'quantityEvidence': 'estimated',
        'revision': 0,
      }, mutationKey());
      await load();
      widget.changed?.call();
      if (!mounted) return;
      final id = saved['id'] as String?;
      final revision = (saved['calculation'] as Map?)?['revision'] as int?;
      // "Desfazer" always refers to the last tap.
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(
        SnackBar(
          content: Text('${_label(context, 'added')}: $ml ml'),
          action: id == null || revision == null
              ? null
              : SnackBarAction(
                  label: _label(context, 'undo'),
                  onPressed: () async {
                    await widget.repository.deleteEntry(
                      id,
                      revision,
                      mutationKey(),
                    );
                    await load();
                    widget.changed?.call();
                  },
                ),
        ),
      );
    } catch (_) {
      if (mounted) {
        messenger?.showSnackBar(
          SnackBar(content: Text(_label(context, 'failed'))),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String l(String k) => _label(context, k);
    if (widget.compact) return _compact(context, l);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tf.blue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop, color: TrainForgeTheme.ink),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l('title'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: TrainForgeTheme.ink,
                  ),
                ),
              ),
              Semantics(
                liveRegion: true,
                child: Text(
                  total == null ? '—' : '$total ml',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: TrainForgeTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _button(l('glass'), '200 ml', 200)),
              const SizedBox(width: 10),
              Expanded(child: _button(l('bottle'), '500 ml', 500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _button(String title, String volume, int ml) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: busy ? null : () => add(ml),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: TrainForgeTheme.ink,
                ),
              ),
              Text(
                volume,
                style: const TextStyle(
                  fontSize: 14,
                  color: TrainForgeTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

const _drop = Color(0xff2f7fcf);

extension on _HydrationCardState {
  /// Eight drops light up as the day's water reaches each eighth of the goal
  /// (without a goal, each drop is a glass of 200 ml).
  Widget _compact(BuildContext context, String Function(String) l) {
    final goal = widget.goalMl;
    final step = goal == null ? 200 : goal / 8;
    final lit = ((total ?? 0) / step).floor().clamp(0, 8);
    Widget chip(String label, int ml) => Material(
      color: context.tf.soft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: busy ? null : () => add(ml),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 34),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: context.tf.ink),
              ),
            ),
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  l('title'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                total == null
                    ? '—'
                    : goal == null
                    ? '$total ml'
                    : '$total / $goal',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ExcludeSemantics(
          child: Column(
            children: [
              for (final row in [0, 4])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (var i = row; i < row + 4; i++)
                        Icon(
                          i < lit
                              ? Icons.water_drop
                              : Icons.water_drop_outlined,
                          size: 18,
                          color: _drop.withValues(alpha: i < lit ? 1 : .45),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: '${l('glass')}, 200 ml',
          excludeSemantics: true,
          child: chip(l('glass'), 200),
        ),
        const SizedBox(height: 5),
        Semantics(
          button: true,
          label: '${l('bottle')}, 500 ml',
          excludeSemantics: true,
          child: chip(l('bottle'), 500),
        ),
      ],
    );
  }
}
