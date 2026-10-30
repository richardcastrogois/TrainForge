import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/flow_components.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/catalog_entry.dart';
import 'catalog_labels.dart';

Uri? safeCatalogLink(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri;
}

class CatalogSourceLink extends StatelessWidget {
  final String label;
  final String? value;
  const CatalogSourceLink({
    super.key,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) {
      return Text('$label: ${context.l10n.notInformed}');
    }
    final uri = safeCatalogLink(value!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: uri == null
              ? null
              : () async {
                  var opened = false;
                  try {
                    opened = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (_) {}
                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.linkFailed)),
                    );
                  }
                },
          icon: const Icon(Icons.open_in_new),
          label: Text(label),
        ),
        SelectableText(value!),
      ],
    );
  }
}

class CatalogDetailPage extends StatefulWidget {
  final CatalogEntry entry;
  final CatalogRepository repository;
  final bool evidenceMode;
  const CatalogDetailPage({
    super.key,
    required this.entry,
    required this.repository,
    this.evidenceMode = false,
  });
  @override
  State<CatalogDetailPage> createState() => _CatalogDetailPageState();
}

class _CatalogDetailPageState extends State<CatalogDetailPage>
    with WidgetsBindingObserver {
  late Future<CatalogEntry> pending;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    pending = widget.repository.detail(widget.entry);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() => pending = widget.repository.detail(widget.entry));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void retry() =>
      setState(() => pending = widget.repository.detail(widget.entry));
  @override
  Widget build(BuildContext context) => FigmaRouteFrame(
    body: SafeArea(
      child: FutureBuilder<CatalogEntry>(
        future: pending,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: FigmaBack(),
                ),
                AppLoading(label: context.l10n.loadingDetail),
              ],
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            final error = snapshot.error;
            final unavailable =
                error is DioException && error.response?.statusCode == 404;
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                FigmaPageHeading(
                  title: context.l10n.originAvailability,
                  subtitle: context.l10n.libraryUpper,
                ),
                FlowStatus(
                  title: unavailable
                      ? context.l10n.referenceUnavailable
                      : context.l10n.queryUnavailable,
                  message: unavailable
                      ? context.l10n.recordWithdrawn
                      : context.l10n.recordUnconfirmed,
                  actionLabel: unavailable
                      ? context.l10n.backLibrary
                      : context.l10n.retry,
                  onAction: unavailable
                      ? () => Navigator.maybePop(context)
                      : retry,
                ),
              ],
            );
          }
          final item = snapshot.data!;
          if (!widget.evidenceMode) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                FigmaPageHeading(
                  title: localizedCatalogTitle(context, item),
                  subtitle: context.l10n.exerciseDetails,
                ),
                FigmaSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.consultationOnlyShort,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(context.l10n.practiceUnavailableShort),
                    ],
                  ),
                ),
                if (item.equipment.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FigmaSection(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.equipment,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.equipment
                              .map((v) => localizedCatalogTerm(context, v))
                              .join(', '),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          }

          Widget section(String title, Widget content) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: FigmaSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  content,
                ],
              ),
            ),
          );
          String known(List<String>? values) => values == null || values.isEmpty
              ? context.l10n.notProvidedSource
              : values.join(', ');
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              FigmaPageHeading(
                title: context.l10n.originAvailability,
                subtitle: context.l10n.libraryReadOnlyUpper,
              ),
              Text(
                item.title ?? context.l10n.titleNotProvided,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                item.kind == 'movement'
                    ? context.l10n.referenceMovement
                    : item.kind == 'collection'
                    ? context.l10n.collection
                    : context.l10n.sourceProgram,
              ),
              const SizedBox(height: 8),
              Text(context.l10n.noPracticeContent),
              const SizedBox(height: 12),
              Text(context.l10n.contentOriginal),
              Text(context.l10n.translationsExplanation),
              const SizedBox(height: 24),
              section(
                context.l10n.authorship,
                Text(
                  '${context.l10n.authorsProvided}: ${known(item.authors)}\n${context.l10n.sourceCredits}: ${known(item.creators)}\n${context.l10n.attribution}: ${item.attribution ?? context.l10n.notInformed}',
                ),
              ),
              section(
                context.l10n.sourceLicense,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.sourceName),
                    CatalogSourceLink(
                      label: context.l10n.openOriginalSource,
                      value: item.sourceUrl,
                    ),
                    const SizedBox(height: 12),
                    Text(item.licenseLabel ?? context.l10n.licenseNotProvided),
                    CatalogSourceLink(
                      label: context.l10n.openLicense,
                      value: item.licenseUrl,
                    ),
                    const SizedBox(height: 12),
                    Text(item.warrantyNotice ?? context.l10n.noticeNotProvided),
                  ],
                ),
              ),
              section(
                context.l10n.availability,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...item.reasons
                        .take(2)
                        .map(
                          (reason) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(reason),
                          ),
                        ),
                  ],
                ),
              ),
              section(
                context.l10n.audienceSupport,
                Text(
                  '${context.l10n.audience}: ${known(item.populations)}\n${context.l10n.environment}: ${known(item.environments)}\n${context.l10n.support}: ${item.supportRequired == null
                      ? context.l10n.notProvidedSource
                      : item.supportRequired!
                      ? context.l10n.supportRequired
                      : context.l10n.supportNotRequired}${item.supportSource == null ? '' : '\n${context.l10n.supportReference}: ${item.supportSource!}'}',
                ),
              ),
              section(
                context.l10n.providedRequirements,
                Text(
                  '${context.l10n.category}: ${item.category ?? context.l10n.notInformed}\n${context.l10n.modality}: ${item.modality ?? context.l10n.notInformed}\n${context.l10n.equipment}: ${known(item.equipment)}',
                ),
              ),
              if (item.nameCreators.isNotEmpty)
                section(
                  context.l10n.titleCredits,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.nameCreators.join(', ')),
                      CatalogSourceLink(
                        label: context.l10n.titleLicense,
                        value: item.nameLicenseUrl,
                      ),
                    ],
                  ),
                ),
              section(
                context.l10n.declaredChanges,
                Text(item.changes ?? context.l10n.notInformed),
              ),
              section(
                context.l10n.deliveryConditions,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...item.deliveryConditions.map(
                      (condition) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(condition),
                      ),
                    ),
                  ],
                ),
              ),
              section(
                context.l10n.queriedVersion,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.versionHash),
                    SelectableText(item.versionId),
                    Text(
                      '${context.l10n.publishedVersion}: ${item.sourcePublishedVersion ?? context.l10n.notInformed}',
                    ),
                    Text(
                      '${context.l10n.originalLanguage}: ${item.locale ?? context.l10n.notInformed}',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
