import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/l10n/localized_context.dart';
import '../data/offline_nutrition_repository.dart';
import '../domain/nutrition.dart';
import 'food_offline_labels.dart';

Future<void> inviteFoodContribution(
  BuildContext context,
  OfflineNutritionRepository repository,
  Json food,
) async {
  if (!await repository.contributionInvitesEnabled() || !context.mounted) {
    return;
  }
  var suppress = false;
  final review = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(foodOfflineLabel(context, 'helpCatalog')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(foodOfflineLabel(context, 'invite')),
              CheckboxListTile(
                value: suppress,
                onChanged: (value) => setState(() => suppress = value == true),
                title: Text(foodOfflineLabel(context, 'suppressInvites')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(foodOfflineLabel(context, 'later')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(foodOfflineLabel(context, 'review')),
          ),
        ],
      ),
    ),
  );
  if (suppress) await repository.setContributionInvites(false);
  if (review != true || !context.mounted) return;
  await Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => FoodContributionPage(repository: repository, food: food),
    ),
  );
}

class FoodContributionPage extends StatefulWidget {
  final OfflineNutritionRepository repository;
  final Json food;
  const FoodContributionPage({
    super.key,
    required this.repository,
    required this.food,
  });
  @override
  State<FoodContributionPage> createState() => _FoodContributionPageState();
}

class _FoodContributionPageState extends State<FoodContributionPage> {
  bool consent = false, busy = false;
  final photos = <String>[];
  String? error;
  Future<void> addPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );
    if (image != null && mounted) setState(() => photos.add(image.path));
  }

  Future<void> send() async {
    if (!consent || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repository.contribute(widget.food, photoPaths: photos);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(foodOfflineLabel(context, 'queued'))),
      );
      Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => error = context.l10n.nutritionCheckFields);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(foodOfflineLabel(context, 'review'))),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(foodOfflineLabel(context, 'contributionNotice')),
        const SizedBox(height: 16),
        Text(
          widget.food['name'] as String,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (widget.food['brand'] != null) Text(widget.food['brand'] as String),
        Text(
          '${object(widget.food['basis'])['quantity'] ?? '—'} ${object(widget.food['basis'])['unit'] ?? ''}',
        ),
        for (final n in objects(widget.food['nutrients']))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(n['name'] as String),
            trailing: Text('${n['value'] ?? '—'} ${n['unit']}'),
          ),
        if (widget.food['barcodes'] is List)
          Text((widget.food['barcodes'] as List).join(', ')),
        for (final portion in objects(widget.food['portions'] ?? const []))
          ListTile(
            title: Text(portion['label'] as String),
            subtitle: Text(
              '${portion['quantity']} ${portion['unit']} · ${portion['condition'] ?? ''}',
            ),
          ),
        for (var i = 0; i < photos.length; i++)
          ListTile(
            leading: Image.file(
              File(photos[i]),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              semanticLabel: '${foodOfflineLabel(context, 'photo')} ${i + 1}',
            ),
            title: Text('${foodOfflineLabel(context, 'photo')} ${i + 1}'),
            trailing: IconButton(
              tooltip: foodOfflineLabel(context, 'removePhoto'),
              icon: const Icon(Icons.close),
              onPressed: busy ? null : () => setState(() => photos.removeAt(i)),
            ),
          ),
        if (photos.length < 2)
          OutlinedButton.icon(
            onPressed: busy ? null : addPhoto,
            icon: const Icon(Icons.add_photo_alternate),
            label: Text(foodOfflineLabel(context, 'photo')),
          ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: consent,
          onChanged: busy ? null : (v) => setState(() => consent = v == true),
          title: Text(foodOfflineLabel(context, 'consent')),
        ),
        if (error != null) Semantics(liveRegion: true, child: Text(error!)),
        FilledButton(
          onPressed: consent && !busy ? send : null,
          child: Text(
            busy
                ? context.l10n.loading
                : foodOfflineLabel(context, 'contribute'),
          ),
        ),
      ],
    ),
  );
}

class FoodContributionsPage extends StatefulWidget {
  final OfflineNutritionRepository repository;
  const FoodContributionsPage({super.key, required this.repository});
  @override
  State<FoodContributionsPage> createState() => _FoodContributionsPageState();
}

class _FoodContributionsPageState extends State<FoodContributionsPage> {
  late Future<List<Json>> items;
  String? error;
  @override
  void initState() {
    super.initState();
    items = widget.repository.store.resources('contribution');
  }

  Future<void> cancel(String id) async {
    try {
      await widget.repository.cancelContribution(id);
      if (mounted) {
        setState(
          () => items = widget.repository.store.resources('contribution'),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = foodOfflineLabel(context, 'syncFailure'));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(foodOfflineLabel(context, 'contributions'))),
    body: FutureBuilder<List<Json>>(
      future: items,
      builder: (context, snapshot) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextButton(
            onPressed: () async {
              await widget.repository.setContributionInvites(true);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(foodOfflineLabel(context, 'invitesEnabled')),
                  ),
                );
              }
            },
            child: Text(foodOfflineLabel(context, 'enableInvites')),
          ),
          if (error != null) Text(error!),
          if (!snapshot.hasData) const LinearProgressIndicator(),
          for (final item in snapshot.data ?? <Json>[])
            ListTile(
              title: Text(object(item['food'])['name'] as String),
              subtitle: Text(
                foodOfflineLabel(context, item['status'] as String),
              ),
              trailing: const {'queued', 'submitted'}.contains(item['status'])
                  ? IconButton(
                      tooltip: foodOfflineLabel(context, 'cancelContribution'),
                      icon: const Icon(Icons.cancel_outlined),
                      onPressed: () =>
                          cancel(item['localResourceId'] as String),
                    )
                  : null,
            ),
        ],
      ),
    ),
  );
}
