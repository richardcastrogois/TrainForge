import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as paths;
import 'package:path_provider/path_provider.dart';

import '../../../core/http/app_dio.dart';
import '../../../core/l10n/localized_context.dart';
import '../../nutrition/presentation/food_offline_labels.dart';
import '../data/catalog_installer.dart';

class CatalogToolsPage extends StatefulWidget {
  final CatalogInstaller installer;
  const CatalogToolsPage({super.key, required this.installer});
  @override
  State<CatalogToolsPage> createState() => _CatalogToolsPageState();
}

class _CatalogToolsPageState extends State<CatalogToolsPage> {
  bool busy = false;
  String? message;
  Future<void> install({required bool download}) async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    File? temporary;
    try {
      String? path;
      if (download) {
        final directory = await getTemporaryDirectory();
        temporary = File(
          paths.join(directory.path, 'trainforge-catalog-update.zip'),
        );
        await AppDio.instance.download(
          '/api/v1/food-catalog/archive',
          temporary.path,
          options: Options(
            extra: {'publicAuth': true},
            receiveTimeout: const Duration(minutes: 20),
          ),
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
        FilledButton.icon(
          onPressed: busy ? null : () => install(download: true),
          icon: const Icon(Icons.download),
          label: Text(foodOfflineLabel(context, 'update')),
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : () => install(download: false),
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
