import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:trainforge/features/food_reference/domain/food_reference.dart';
import 'package:trainforge/features/food_reference/presentation/food_labels.dart';

import 'food_offline_labels.dart';

/// Listens with the phone's own speech recognizer and returns what was said, or null.
/// Nothing is recorded by the app: the recognizer runs only while this dialog is open.
Future<String?> listenForMeal(
  BuildContext context, {
  List<String> vocabulary = const [],
}) => showDialog<String>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _VoiceListenDialog(vocabulary: vocabulary),
);

class _VoiceListenDialog extends StatefulWidget {
  final List<String> vocabulary;
  const _VoiceListenDialog({required this.vocabulary});
  @override
  State<_VoiceListenDialog> createState() => _VoiceListenDialogState();
}

class _VoiceListenDialogState extends State<_VoiceListenDialog> {
  final speech = SpeechToText();
  String heard = '';
  String? problem;
  bool closed = false;

  @override
  void initState() {
    super.initState();
    unawaited(start());
  }

  void finish([String? text]) {
    if (closed || !mounted) return;
    closed = true;
    Navigator.pop(
      context,
      (text ?? heard).trim().isEmpty ? null : (text ?? heard),
    );
  }

  Future<void> start() async {
    final language = Localizations.localeOf(context).languageCode;
    try {
      final ok = await speech.initialize(
        onError: (e) {
          if (mounted && heard.isEmpty) {
            setState(
              () => problem = e.errorMsg.contains('permission')
                  ? 'voicePermission'
                  : 'voiceNone',
            );
          }
        },
        onStatus: (status) {
          if (status == SpeechToText.doneStatus && heard.isNotEmpty) finish();
        },
      );
      if (!mounted) return;
      if (!ok) {
        setState(() => problem = 'voiceUnavailable');
        return;
      }
      await speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() => heard = result.recognizedWords);
          if (result.finalResult) finish(result.recognizedWords);
        },
        listenOptions: SpeechListenOptions(
          localeId: switch (language) {
            'en' => 'en_US',
            'es' => 'es_ES',
            _ => 'pt_BR',
          },
          listenFor: const Duration(seconds: 40),
          pauseFor: const Duration(seconds: 4),
          listenMode: ListenMode.dictation,
          partialResults: true,
          contextualPhrases: widget.vocabulary,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => problem = 'voiceUnavailable');
    }
  }

  @override
  void dispose() {
    unawaited(speech.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: Icon(problem == null ? Icons.mic : Icons.mic_off),
    title: Text(foodOfflineLabel(context, problem ?? 'voiceListening')),
    content: Text(
      heard.isEmpty ? foodOfflineLabel(context, 'voiceExample') : heard,
      key: const Key('voice-heard'),
    ),
    actions: [
      TextButton(
        onPressed: () {
          closed = true;
          Navigator.pop(context);
        },
        child: Text(foodOfflineLabel(context, 'voiceCancel')),
      ),
      if (problem == null)
        FilledButton(
          onPressed: () async {
            await speech.stop();
            finish();
          },
          child: Text(foodOfflineLabel(context, 'voiceStop')),
        ),
    ],
  );
}

/// One food heard and the catalog foods it may be.
class VoiceMealItem {
  final String heard;
  final List<FoodReference> options;
  const VoiceMealItem(this.heard, this.options);
}

/// What was heard, item by item; the person picks the right food and confirms the quantity.
class VoiceMealPage extends StatefulWidget {
  final String sentence;
  final List<VoiceMealItem> items;

  /// Opens the entry form; true when the intake was saved.
  final Future<bool> Function(FoodReference food) record;
  final VoidCallback searchByName;
  const VoiceMealPage({
    super.key,
    required this.sentence,
    required this.items,
    required this.record,
    required this.searchByName,
  });
  @override
  State<VoiceMealPage> createState() => _VoiceMealPageState();
}

class _VoiceMealPageState extends State<VoiceMealPage> {
  final saved = <int, FoodReference>{};

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(foodOfflineLabel(context, 'voice'))),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text(
          '${foodOfflineLabel(context, 'voiceHeard')} “${widget.sentence}”',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(foodOfflineLabel(context, 'voiceHint')),
        const SizedBox(height: 16),
        if (widget.items.isEmpty) Text(foodOfflineLabel(context, 'voiceNone')),
        for (final (i, item) in widget.items.indexed)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(item.heard),
                    trailing: saved.containsKey(i)
                        ? Chip(
                            label: Text(foodOfflineLabel(context, 'voiceDone')),
                          )
                        : null,
                  ),
                  if (item.options.isEmpty)
                    ListTile(
                      dense: true,
                      title: Text(foodOfflineLabel(context, 'voiceNoMatch')),
                    ),
                  for (final food in item.options)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        saved[i] == food
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                      ),
                      title: Text(food.localizedName(context)),
                      onTap: () async {
                        if (await widget.record(food) && mounted) {
                          setState(() => saved[i] = food);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: widget.searchByName,
          icon: const Icon(Icons.search),
          label: Text(foodOfflineLabel(context, 'voiceSearch')),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(foodOfflineLabel(context, 'voiceFinish')),
        ),
      ],
    ),
  );
}
