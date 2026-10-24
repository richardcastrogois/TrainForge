import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/flow_components.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/catalog_entry.dart';

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
    if (value == null || value!.isEmpty) return Text('$label: não informado');
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
                      const SnackBar(
                        content: Text(
                          'Não foi possível abrir o link. Você pode copiar a URL abaixo.',
                        ),
                      ),
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
  const CatalogDetailPage({
    super.key,
    required this.entry,
    required this.repository,
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
                const AppLoading(label: 'Consultando detalhe'),
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
                const FigmaPageHeading(
                  title: 'Origem e disponibilidade',
                  subtitle: 'BIBLIOTECA',
                ),
                FlowStatus(
                  title: unavailable
                      ? 'Referência indisponível'
                      : 'Consulta indisponível',
                  message: unavailable
                      ? 'Este registro não está disponível ou foi retirado. Volte à biblioteca.'
                      : 'Não foi possível confirmar este registro. Tente novamente conectado.',
                  actionLabel: unavailable
                      ? 'Voltar à biblioteca'
                      : 'Tentar novamente',
                  onAction: unavailable
                      ? () => Navigator.maybePop(context)
                      : retry,
                ),
              ],
            );
          }
          final item = snapshot.data!;
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
              ? 'Não informado pela fonte'
              : values.join(', ');
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              const FigmaPageHeading(
                title: 'Origem e disponibilidade',
                subtitle: 'BIBLIOTECA · SOMENTE CONSULTA',
              ),
              Text(
                item.title ?? 'Título não informado',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                item.kind == 'movement'
                    ? 'Movimento de referência'
                    : item.kind == 'collection'
                    ? 'Coleção modular'
                    : 'Programa da fonte',
              ),
              const SizedBox(height: 8),
              const Text(
                'Somente consulta. Instrução, dose e mídia não estão liberadas para uso no app.',
              ),
              const SizedBox(height: 24),
              section(
                'Autoria e contribuição',
                Text(
                  'Autores informados: ${known(item.authors)}\nCréditos da fonte: ${known(item.creators)}\nAtribuição: ${item.attribution ?? 'Não informada'}',
                ),
              ),
              section(
                'Fonte e licença',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.sourceName),
                    CatalogSourceLink(
                      label: 'Abrir fonte original',
                      value: item.sourceUrl,
                    ),
                    const SizedBox(height: 12),
                    Text(item.licenseLabel ?? 'Licença não informada'),
                    CatalogSourceLink(
                      label: 'Abrir licença',
                      value: item.licenseUrl,
                    ),
                    const SizedBox(height: 12),
                    Text(item.warrantyNotice ?? 'Aviso não informado'),
                  ],
                ),
              ),
              section(
                'Disponibilidade',
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
                'Público, ambiente e apoio',
                Text(
                  'Público: ${known(item.populations)}\nAmbiente: ${known(item.environments)}\nApoio: ${item.supportRequired == null
                      ? 'Não informado pela fonte'
                      : item.supportRequired!
                      ? 'Exigido pela fonte'
                      : 'Não exigido conforme a fonte'}${item.supportSource == null ? '' : '\nReferência de apoio: ${item.supportSource!}'}',
                ),
              ),
              section(
                'Requisitos informados',
                Text(
                  'Categoria: ${item.category ?? 'Não informada'}\nModalidade: ${item.modality ?? 'Não informada'}\nEquipamento: ${known(item.equipment)}',
                ),
              ),
              if (item.nameCreators.isNotEmpty)
                section(
                  'Créditos do título original',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.nameCreators.join(', ')),
                      CatalogSourceLink(
                        label: 'Licença do título',
                        value: item.nameLicenseUrl,
                      ),
                    ],
                  ),
                ),
              section(
                'Alterações declaradas',
                Text(item.changes ?? 'Não informadas'),
              ),
              section(
                'Condições de entrega',
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
                'Versão consultada',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hash da versão importada:'),
                    SelectableText(item.versionId),
                    Text(
                      'Versão publicada pela fonte: ${item.sourcePublishedVersion ?? 'Não informada'}',
                    ),
                    Text('Idioma original: ${item.locale ?? 'Não informado'}'),
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
