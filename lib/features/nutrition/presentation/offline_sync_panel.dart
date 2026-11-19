import 'package:flutter/material.dart';

import '../data/offline_nutrition_repository.dart';
import '../domain/nutrition.dart';
import 'food_offline_labels.dart';

class OfflineSyncPanel extends StatelessWidget {
  final OfflineNutritionRepository repository;
  final Future<void> Function() reload;
  const OfflineSyncPanel({
    super.key,
    required this.repository,
    required this.reload,
  });
  Future<void> conflicts(BuildContext context) async {
    final values = await repository.conflicts();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(foodOfflineLabel(context, 'conflicts')),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(foodOfflineLabel(context, 'conflictNotice')),
                for (final value in values) ...[
                  const Divider(),
                  Text(
                    '${foodOfflineLabel(context, 'onDevice')}: '
                    '${object(value['body'])['name'] ?? object(value['body'])['title'] ?? ''} '
                    '${object(value['body'])['quantity'] ?? ''} ${object(value['body'])['unit'] ?? ''}',
                  ),
                  Text(foodOfflineLabel(context, 'reviewRequired')),
                  if (value['server'] is Map)
                    Text(
                      '${foodOfflineLabel(context, 'onServer')}: '
                      '${object(value['server'])['quantity'] ?? object(object(value['server'])['meal'] ?? {})['title'] ?? ''} '
                      '${object(value['server'])['unit'] ?? ''}',
                    ),
                  if (value['state'] == 'conflict' && value['server'] is Map)
                    OutlinedButton(
                      onPressed: () async {
                        try {
                          await repository.acceptServer(
                            value['operation_id'] as String,
                          );
                          if (context.mounted) Navigator.pop(context);
                          await reload();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  foodOfflineLabel(context, 'syncFailure'),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(foodOfflineLabel(context, 'serverVersion')),
                    ),
                  if (value['state'] == 'conflict' &&
                      value['server'] is Map &&
                      object(value['server'])['deletedAt'] == null &&
                      const {'entry', 'meal'}.contains(value['entity']))
                    OutlinedButton(
                      onPressed: () async {
                        try {
                          await repository.keepLocal(
                            value['operation_id'] as String,
                          );
                          if (context.mounted) Navigator.pop(context);
                          await reload();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  foodOfflineLabel(context, 'syncFailure'),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(foodOfflineLabel(context, 'keepLocal')),
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: repository,
    builder: (context, _) => Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                repository.syncBusy
                    ? foodOfflineLabel(context, 'syncing')
                    : '${foodOfflineLabel(context, 'offlineDiary')} · ${repository.pendingCount} ${foodOfflineLabel(context, 'pending')}',
              ),
            ),
            if (repository.syncFailure != null)
              Text(
                foodOfflineLabel(
                  context,
                  repository.syncFailure == 'authentication'
                      ? 'authFailure'
                      : 'syncFailure',
                ),
              ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: repository.syncBusy
                      ? null
                      : () async {
                          await repository.synchronize();
                          await reload();
                        },
                  icon: const Icon(Icons.sync),
                  label: Text(foodOfflineLabel(context, 'sync')),
                ),
                if (repository.conflictCount > 0)
                  TextButton(
                    onPressed: () => conflicts(context),
                    child: Text(foodOfflineLabel(context, 'conflicts')),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
