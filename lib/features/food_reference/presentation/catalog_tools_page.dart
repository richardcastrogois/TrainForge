import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as paths;
import 'package:path_provider/path_provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/localized_context.dart';
import '../../nutrition/presentation/food_offline_labels.dart';
import '../data/catalog_installer.dart';

/// Signed regional packs published as GitHub Release assets. Each pack is a
/// complete catalog that replaces the active one; the trust key stays in the APK.
class CatalogPack {
  final String id;
  final String titleKey;
  final int megabytes;
  const CatalogPack(this.id, this.titleKey, this.megabytes);
  String get file => 'trainforge-catalog-$id.zip';
}

const catalogPacks = [
  CatalogPack('br', 'packBrazil', 41),
  CatalogPack('br-pt', 'packBrazilPortugal', 52),
];

class CatalogToolsPage extends StatefulWidget {
  final CatalogInstaller installer;
  const CatalogToolsPage({super.key, required this.installer});
  @override
  State<CatalogToolsPage> createState() => _CatalogToolsPageState();
}

class _CatalogToolsPageState extends State<CatalogToolsPage> {
  bool busy = false;
  String? message;
  Future<void> install({CatalogPack? pack}) async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    File? temporary;
    try {
      String? path;
      if (pack != null) {
        final directory = await getTemporaryDirectory();
        temporary = File(paths.join(directory.path, pack.file));
        // Public static file; the signed manifest inside is verified on import.
        await Dio().download(
          Uri.parse(AppConfig.catalogPacksUrl).resolve(pack.file).toString(),
          temporary.path,
          options: Options(receiveTimeout: const Duration(minutes: 20)),
        );
        path = temporary.path;
      } else {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['zip', 'tfcat'],
        );
        path = result.isEmpty ? null : result.single.path;
      }
      if (path == null) return;
      await widget.installer.importArchive(path);
      if (mounted) {
        setState(() => message = foodOfflineLabel(context, 'imported'));
      }
    } catch (_) {
      if (mounted) {
        setState(() => message = foodOfflineLabel(context, 'importFailure'));
      }
    } finally {
      if (temporary != null && await temporary.exists()) {
        await temporary.delete();
      }
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(foodOfflineLabel(context, 'catalog'))),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(foodOfflineLabel(context, 'catalogNotice')),
        const SizedBox(height: 12),
        Text(foodOfflineLabel(context, 'catalogSpace')),
        const SizedBox(height: 16),
        Text(
          foodOfflineLabel(context, 'packs'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final pack in catalogPacks)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(foodOfflineLabel(context, pack.titleKey)),
            subtitle: pack.megabytes > 0
                ? Text('${pack.megabytes} MB')
                : null,
            trailing: IconButton(
              tooltip: foodOfflineLabel(context, 'download'),
              onPressed: busy ? null : () => install(pack: pack),
              icon: const Icon(Icons.download),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: busy ? null : () => install(),
          icon: const Icon(Icons.folder_open),
          label: Text(foodOfflineLabel(context, 'import')),
        ),
        if (busy)
          const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
        if (message != null) Semantics(liveRegion: true, child: Text(message!)),
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: Text(context.l10n.back),
        ),
      ],
    ),
  );
}
