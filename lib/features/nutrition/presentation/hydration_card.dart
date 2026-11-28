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
    'title': 'Água',
    'glass': '+ 1 copo',
    'bottle': '+ 1 garrafa',
    'added': 'Água registrada',
    'undo': 'Desfazer',
    'failed': 'Não foi possível registrar agora. Tente de novo.',
  },
  'en': {
    'title': 'Water',
    'glass': '+ 1 glass',
    'bottle': '+ 1 bottle',
    'added': 'Water recorded',
    'undo': 'Undo',
    'failed': 'Could not record now. Try again.',
  },
  'es': {
    'title': 'Agua',
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

  /// Lays the water out elsewhere (the food page's day card): gets the
  /// day's total and `add` (null while a record is being saved).
  final Widget Function(
    BuildContext context,
    int? total,
    ValueChanged<int>? add,
  )?
  builder;

  /// Gets the day's total whenever it is read again.
  final ValueChanged<int>? onTotal;
  const HydrationCard({
    super.key,
    required this.repository,
    this.now = DateTime.now,
    this.changed,
    this.builder,
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
    if (widget.builder != null) {
      return widget.builder!(context, total, busy ? null : add);
    }
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
