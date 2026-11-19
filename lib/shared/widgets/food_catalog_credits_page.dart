import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/localized_context.dart';
import '../../features/food_reference/data/catalog_installer.dart';

/// Credits are read from the signed bundled manifest, without installing the DB.
class FoodCatalogCreditsPage extends StatefulWidget {
  final Future<Map<String, dynamic>> Function()? loadManifest;
  const FoodCatalogCreditsPage({super.key, this.loadManifest});

  @override
  State<FoodCatalogCreditsPage> createState() => _FoodCatalogCreditsPageState();
}

class _FoodCatalogCreditsPageState extends State<FoodCatalogCreditsPage> {
  late final Future<Map<String, dynamic>> manifest =
      widget.loadManifest?.call() ?? _load();

  Future<Map<String, dynamic>> _load() async => CatalogInstaller().verifyEnvelope(
    await rootBundle.loadString('assets/food_catalog/manifest.json'),
  );

  String label(String pt, String en, String es) =>
      switch (Localizations.localeOf(context).languageCode) {
        'pt' => pt,
        'es' => es,
        _ => en,
      };

  Future<void> download(String artifact, String filename) async {
    try {
      AppConfig.validate();
      final uri = Uri.parse(AppConfig.apiBaseUrl).resolve(
        '/api/v1/food-catalog/exports/${Uri.encodeComponent(artifact)}/${Uri.encodeComponent(filename)}',
      );
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // No request bodies, identity or credentials are passed to the browser.
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(label('Não foi possível abrir o download.',
              'The download could not be opened.',
              'No se pudo abrir la descarga.')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.sourceCredits)),
    body: FutureBuilder<Map<String, dynamic>>(
      future: manifest,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: snapshot.hasError
                ? Text(label('Créditos indisponíveis nesta instalação.',
                    'Credits unavailable in this installation.',
                    'Créditos no disponibles en esta instalación.'))
                : const CircularProgressIndicator(),
          );
        }
        final data = snapshot.data!;
        final sources = (data['sources'] as List? ?? const []).cast<Map>();
        final exports = (data['exports'] as List? ?? const []).cast<Map>();
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(label(
              'Contém informações do Open Food Facts, disponíveis sob a Open Database License (ODbL). © Open Food Facts contributors. As fontes e os avisos completos estão abaixo.',
              'Contains information from Open Food Facts, made available under the Open Database License (ODbL). © Open Food Facts contributors. Sources and full notices appear below.',
              'Contiene información de Open Food Facts, disponible bajo la Open Database License (ODbL). © Open Food Facts contributors. Las fuentes y los avisos completos aparecen abajo.',
            )),
            const SizedBox(height: 16),
            Text(label(
              'A base derivada do Open Food Facts é oferecida em formato legível por máquina sob ODbL 1.0. Os downloads por fonte correspondem à versão incluída no aplicativo e precisam de conexão. Seus registros pessoais não fazem parte desses arquivos.',
              'The database derived from Open Food Facts is offered in machine-readable form under ODbL 1.0. Source downloads match the version bundled with the app and require a connection. Your personal records are not included in these files.',
              'La base derivada de Open Food Facts se ofrece en formato legible por máquina bajo ODbL 1.0. Las descargas por fuente corresponden a la versión incluida en la aplicación y necesitan conexión. Sus registros personales no están incluidos.',
            )),
            const SizedBox(height: 16),
            for (final source in sources)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(source['name'] as String? ?? ''),
                subtitle: Text(source['licenseLabel'] as String? ?? ''),
                childrenPadding: const EdgeInsets.only(bottom: 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(source['attribution'] as String? ?? ''),
                  SelectableText(source['url'] as String? ?? ''),
                  SelectableText(source['licenseUrl'] as String? ?? ''),
                  Text('${context.l10n.sourceVersion}: ${source['version'] ?? ''}'),
                  for (final condition in source['conditions'] as List? ?? const [])
                    Text(condition.toString()),
                  for (final export in exports.where(
                    (e) => e['sourceId'] == source['sourceId'],
                  ))
                    TextButton.icon(
                      onPressed: () => download(data['sha256'] as String, export['file'] as String),
                      icon: const Icon(Icons.download),
                      label: Text('${label('Baixar dados', 'Download data', 'Descargar datos')} '
                          '(${((export['bytes'] as num) / (1 << 20)).toStringAsFixed(1)} MB)'),
                    ),
                ],
              ),
          ],
        );
      },
    ),
  );
}
