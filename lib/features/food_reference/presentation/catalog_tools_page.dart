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

/// Signed catalog packs published as GitHub Release assets. A pack is a
/// complete catalog that replaces the active one; the trust key stays in the APK.
/// Additive regional packs are planned in docs/planejamento/melhoria-pacotes-regionais.md.
class CatalogPack {
  final String id;
  final String titleKey;
  final int megabytes;
  const CatalogPack(this.id, this.titleKey, this.megabytes);
  String get file => 'trainforge-catalog-$id.zip';
}

// Only packs whose foods the server also knows can be offered: a recorded food
// must exist in the API catalog to synchronize. The server holds Brazil only.
const catalogPacks = [CatalogPack('br', 'packBrazil', 41)];

class CatalogToolsPage extends StatefulWidget {
  final CatalogInstaller installer;
  final Dio? downloader;
  const CatalogToolsPage({super.key, required this.installer, this.downloader});
  @override
  State<CatalogToolsPage> createState() => _CatalogToolsPageState();
}

class _CatalogToolsPageState extends State<CatalogToolsPage> {
  bool busy = false;
  String? message;
  String? activePack;
  String? installedPack;

  /// Download progress 0..1 for [activePack]; null while verifying/installing.
  double? progress;
  CancelToken? cancel;

  @override
  void initState() {
    super.initState();
    _readInstalled();
  }

  Future<void> _readInstalled() async {
    try {
      final manifest = await widget.installer.manifest();
      final pack = manifest['pack'];
      if (mounted) {
        setState(
          () => installedPack = pack is Map ? pack['id'] as String? : null,
        );
      }
    } catch (_) {
      // Unknown installation keeps every pack downloadable.
    }
  }

  Future<bool> _confirm(CatalogPack pack) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(foodOfflineLabel(context, 'downloadConfirmTitle')),
        content: Text(
          foodOfflineLabel(
            context,
            'downloadConfirmBody',
          ).replaceAll('{mb}', '${pack.megabytes}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(foodOfflineLabel(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(foodOfflineLabel(context, 'download')),
          ),
        ],
      ),
    );
    return accepted == true;
  }

  Future<void> install({CatalogPack? pack}) async {
    if (busy) return;
    if (pack != null && !await _confirm(pack)) return;
    setState(() {
      busy = true;
      message = null;
      activePack = pack?.id;
      progress = pack == null ? null : 0;
    });
    File? temporary;
    try {
      String? path;
      if (pack != null) {
        final directory = await getTemporaryDirectory();
        temporary = File(paths.join(directory.path, pack.file));
        cancel = CancelToken();
        // Public static file; the signed manifest inside is verified on import.
        await (widget.downloader ?? Dio()).download(
          Uri.parse(AppConfig.catalogPacksUrl).resolve(pack.file).toString(),
          temporary.path,
          cancelToken: cancel,
          options: Options(receiveTimeout: const Duration(minutes: 20)),
          onReceiveProgress: (received, total) {
            if (mounted && total > 0) {
              setState(() => progress = received / total);
            }
          },
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
      if (mounted) setState(() => progress = null);
      await widget.installer.importArchive(path);
      if (mounted) {
        setState(() => message = foodOfflineLabel(context, 'imported'));
      }
      await _readInstalled();
    } on DioException catch (error) {
      if (mounted) {
        setState(
          () => message = foodOfflineLabel(
            context,
            CancelToken.isCancel(error) ? 'downloadCanceled' : 'importFailure',
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => message = foodOfflineLabel(context, 'importFailure'));
      }
    } finally {
      cancel = null;
      if (temporary != null && await temporary.exists()) {
        await temporary.delete();
      }
      if (mounted) {
        setState(() {
          busy = false;
          activePack = null;
          progress = null;
        });
      }
    }
  }

  Widget _packAction(BuildContext context, CatalogPack pack) {
    if (activePack == pack.id) {
      final value = progress;
      final percent = value == null ? null : (value * 100).round();
      return Semantics(
        liveRegion: true,
        label: percent == null
            ? foodOfflineLabel(context, 'verifying')
            : '$percent%',
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(value: value),
              if (percent != null)
                Text('$percent', style: Theme.of(context).textTheme.labelSmall)
              else
                const SizedBox.shrink(),
              if (value != null)
                Positioned.fill(
                  child: IconButton(
                    tooltip: foodOfflineLabel(context, 'cancel'),
                    onPressed: () => cancel?.cancel(),
                    icon: const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    if (installedPack == pack.id) {
      return Chip(
        avatar: const Icon(Icons.check_circle, size: 18),
        label: Text(foodOfflineLabel(context, 'installed')),
      );
    }
    return IconButton(
      tooltip: foodOfflineLabel(context, 'download'),
      onPressed: busy ? null : () => install(pack: pack),
      icon: const Icon(Icons.download),
    );
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
            subtitle: Text(
              activePack == pack.id
                  ? foodOfflineLabel(
                      context,
                      progress == null ? 'verifying' : 'downloading',
                    )
                  : '${pack.megabytes} MB',
            ),
            trailing: _packAction(context, pack),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: busy ? null : () => install(),
          icon: const Icon(Icons.folder_open),
          label: Text(foodOfflineLabel(context, 'import')),
        ),
        if (busy && activePack == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Semantics(liveRegion: true, child: Text(message!)),
          ),
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: Text(context.l10n.back),
        ),
      ],
    ),
  );
}
