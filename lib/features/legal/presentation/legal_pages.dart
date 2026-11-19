import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';
import '../legal_controller.dart';
import '../legal_documents.dart';
import 'legal_labels.dart';
import 'staggered_entrance.dart';

/// Screen 1 (first use) and 3 (new version): Terms and Privacy acceptance.
class LegalConsentPage extends StatefulWidget {
  final LegalController controller;
  final String accountId;
  final VoidCallback? onDeleteAccount;
  const LegalConsentPage({
    super.key,
    required this.controller,
    required this.accountId,
    this.onDeleteAccount,
  });
  @override
  State<LegalConsentPage> createState() => _LegalConsentPageState();
}

class _LegalConsentPageState extends State<LegalConsentPage> {
  bool documents = false, adult = false, leaving = false;
  late final bool update = widget.controller.isUpdate(widget.accountId);

  void accept() => setState(() => leaving = true);

  /// Runs after the exit animation. On failure the content comes back with a
  /// message instead of leaving an empty screen.
  Future<void> finish() async {
    try {
      await widget.controller.acceptTerms(widget.accountId);
    } catch (_) {
      if (!mounted) return;
      setState(() => leaving = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(legalLabel(context, 'saveError'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = documents && (update || adult);
    final children = <Widget>[
      if (update) ...[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _Tag(legalLabel(context, 'update')),
        ),
        const SizedBox(height: 8),
      ],
      Text(
        legalLabel(context, update ? 'changedTitle' : 'beforeStart'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text(legalLabel(context, update ? 'changedBody' : 'beforeStartBody')),
      const SizedBox(height: 16),
      for (final document in legalDocuments) ...[
        _DocumentLink(document: document, controller: widget.controller),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 8),
      _Check(
        key: const ValueKey('legal-accept-documents'),
        value: documents,
        label: legalLabel(context, update ? 'acceptNew' : 'acceptDocs'),
        onChanged: (v) => setState(() => documents = v),
      ),
      if (!update) ...[
        const SizedBox(height: 8),
        _Check(
          key: const ValueKey('legal-accept-adult'),
          value: adult,
          label: legalLabel(context, 'adult'),
          onChanged: (v) => setState(() => adult = v),
        ),
      ],
      const SizedBox(height: 20),
      FilledButton(
        key: const ValueKey('legal-continue'),
        onPressed: ready && !widget.controller.busy && !leaving ? accept : null,
        child: Text(
          legalLabel(context, update ? 'acceptContinue' : 'continue'),
        ),
      ),
      if (widget.onDeleteAccount != null)
        TextButton(
          key: const ValueKey('legal-decline'),
          onPressed: leaving ? null : widget.onDeleteAccount,
          child: Text(legalLabel(context, 'decline')),
        ),
      const SizedBox(height: 12),
      Text(
        legalLabel(context, 'notMedical'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: StaggeredEntrance(
                leaving: leaving,
                onLeft: finish,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen 2: separate, specific consent for health-related records (LGPD art. 11).
class HealthConsentPage extends StatefulWidget {
  final LegalController controller;
  final String accountId;
  const HealthConsentPage({
    super.key,
    required this.controller,
    required this.accountId,
  });
  @override
  State<HealthConsentPage> createState() => _HealthConsentPageState();
}

class _HealthConsentPageState extends State<HealthConsentPage> {
  bool checked = false, leaving = false;
  bool? decision;

  void decide(bool granted) => setState(() {
    decision = granted;
    leaving = true;
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: StaggeredEntrance(
              leaving: leaving,
              onLeft: () async {
                try {
                  await widget.controller.decideHealth(
                    widget.accountId,
                    granted: decision == true,
                  );
                } catch (_) {
                  if (mounted) setState(() => leaving = false);
                }
              },
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  legalLabel(context, 'healthTitle'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(legalLabel(context, 'healthBody')),
                const SizedBox(height: 16),
                _Check(
                  key: const ValueKey('health-check'),
                  value: checked,
                  label: legalLabel(context, 'healthCheck'),
                  onChanged: (v) => setState(() => checked = v),
                ),
                const SizedBox(height: 12),
                Text(
                  legalLabel(context, 'healthHint'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('health-authorize'),
                  onPressed: checked && !leaving ? () => decide(true) : null,
                  child: Text(legalLabel(context, 'authorize')),
                ),
                TextButton(
                  key: const ValueKey('health-not-now'),
                  onPressed: leaving ? null : () => decide(false),
                  child: Text(legalLabel(context, 'notNow')),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Screen 4: what was accepted and when, with health-data control.
class LegalSettingsPage extends StatelessWidget {
  final LegalController controller;
  final String? accountId;
  const LegalSettingsPage({
    super.key,
    required this.controller,
    this.accountId,
  });

  String _date(BuildContext context, String? iso) {
    final value = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    if (value == null) return '';
    final material = MaterialLocalizations.of(context);
    return '${material.formatShortDate(value)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(value))}';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final granted = accountId == null
          ? null
          : controller.healthGranted(accountId!);
      return Scaffold(
        appBar: AppBar(title: Text(legalLabel(context, 'legalSettings'))),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            StaggeredEntrance(
              children: [
                for (final document in legalDocuments) ...[
                  _DocumentLink(
                    document: document,
                    controller: controller,
                    badge:
                        accountId == null ||
                            controller.acceptedVersion(
                                  accountId!,
                                  document.id,
                                ) ==
                                null
                        ? null
                        : legalLabel(context, 'acceptedVersion').replaceAll(
                            '{v}',
                            controller.acceptedVersion(
                              accountId!,
                              document.id,
                            )!,
                          ),
                  ),
                  if (accountId != null &&
                      controller.acceptedAt(accountId!, document.id) != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        4,
                        4,
                        4,
                        12,
                      ),
                      child: Text(
                        legalLabel(context, 'acceptedOn').replaceAll(
                          '{date}',
                          _date(
                            context,
                            controller.acceptedAt(accountId!, document.id),
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
                if (accountId != null)
                  Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: ListTile(
                      leading: const Icon(Icons.health_and_safety_outlined),
                      title: Text(legalLabel(context, 'healthData')),
                      subtitle: Text(
                        legalLabel(
                          context,
                          granted == true ? 'granted' : 'notGranted',
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: () => controller.decideHealth(
                          accountId!,
                          granted: granted != true,
                        ),
                        child: Text(
                          legalLabel(
                            context,
                            granted == true ? 'revoke' : 'grant',
                          ),
                        ),
                      ),
                    ),
                  ),
                Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(legalLabel(context, 'licenses')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'TrainForge',
                      applicationVersion: legalAppVersion,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class LegalDocumentPage extends StatelessWidget {
  final LegalDocument document;
  final LegalController controller;
  const LegalDocumentPage({
    super.key,
    required this.document,
    required this.controller,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(legalLabel(context, document.titleKey))),
    body: FutureBuilder<String>(
      future: controller.texts.text(document),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(legalLabel(context, 'readError')));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return AppAppear(
          child: SelectionArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                for (final line in snapshot.data!.split('\n'))
                  _MarkdownLine(line),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Minimal reader for the bundled documents: headings, bullets and tables as text.
class _MarkdownLine extends StatelessWidget {
  final String line;
  const _MarkdownLine(this.line);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(line.substring(2), style: theme.headlineSmall),
      );
    }
    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Text(line.substring(3), style: theme.titleMedium),
      );
    }
    if (RegExp(r'^\|[-| ]+\|$').hasMatch(line)) return const SizedBox.shrink();
    final text = line
        .replaceAll('**', '')
        .replaceFirst(RegExp(r'^- '), '•  ')
        .replaceAll(RegExp(r'^\| | \|$'), '')
        .replaceAll(' | ', ' · ');
    if (text.trim().isEmpty) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: theme.bodyMedium),
    );
  }
}

class _DocumentLink extends StatelessWidget {
  final LegalDocument document;
  final LegalController controller;
  final String? badge;
  const _DocumentLink({
    required this.document,
    required this.controller,
    this.badge,
  });
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: ListTile(
      title: Text(
        '${legalLabel(context, document.titleKey)} v${document.version}',
      ),
      trailing: badge == null
          ? Icon(Icons.open_in_new, semanticLabel: legalLabel(context, 'open'))
          : _Tag(badge!),
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              LegalDocumentPage(document: document, controller: controller),
        ),
      ),
    ),
  );
}

class _Check extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;
  const _Check({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(label),
    ),
  );
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: scheme.onPrimaryContainer),
        ),
      ),
    );
  }
}
