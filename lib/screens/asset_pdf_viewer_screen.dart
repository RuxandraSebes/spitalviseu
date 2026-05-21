import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/language_provider.dart';
import '../i18n/translations.dart';
import '../theme/app_colors.dart';

/// Opens a PDF bundled in [assetPath].
class AssetPdfViewerScreen extends StatefulWidget {
  final String assetPath;
  final String titleKey;

  const AssetPdfViewerScreen({
    super.key,
    required this.assetPath,
    required this.titleKey,
  });

  @override
  State<AssetPdfViewerScreen> createState() => _AssetPdfViewerScreenState();
}

class _AssetPdfViewerScreenState extends State<AssetPdfViewerScreen> {
  String? _localPath;
  bool _loading = true;
  String? _error;
  bool _openedExternally = false;
  int _pages = 0;
  int _currentPage = 0;

  bool get _useInAppViewer =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  String _tr(String key) {
    final locale = LanguageProvider.localeOf(context);
    return AppLocalizations(locale).get(key);
  }

  String _safeFileName(String assetPath) {
    final base = assetPath.split('/').last;
    return base.replaceAll(RegExp(r'[^\w\.\-]'), '_');
  }

  @override
  void initState() {
    super.initState();
    _loadAsset();
  }

  Future<void> _loadAsset() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${_safeFileName(widget.assetPath)}');
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;

      if (_useInAppViewer) {
        setState(() {
          _localPath = file.path;
          _loading = false;
        });
        return;
      }

      final uri = Uri.file(file.path);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!mounted) return;
      setState(() {
        _localPath = file.path;
        _loading = false;
        _openedExternally = launched;
        if (!launched) {
          _error = _tr('pdf_open_external_failed');
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '${_tr('pdf_generic_error')}: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _openExternallyAgain() async {
    if (_localPath == null) return;
    final launched = await launchUrl(
      Uri.file(_localPath!),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('pdf_open_external_failed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.white,
        title: Text(_tr(widget.titleKey), style: const TextStyle(fontSize: 15)),
        actions: [
          if (_useInAppViewer && _pages > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '$_currentPage / $_pages',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          if (!_useInAppViewer && _localPath != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: _tr('open_externally'),
              onPressed: _openExternallyAgain,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(_tr('loading_document')),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: AppColors.primaryWithOpacity(0.5)),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                    _openedExternally = false;
                  });
                  _loadAsset();
                },
                icon: const Icon(Icons.refresh),
                label: Text(_tr('retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (_openedExternally) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                _tr('pdf_opened_externally'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _openExternallyAgain,
                icon: const Icon(Icons.open_in_new),
                label: Text(_tr('open_externally')),
              ),
            ],
          ),
        ),
      );
    }

    if (_localPath == null) {
      return const SizedBox.shrink();
    }

    return PDFView(
      filePath: _localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      onRender: (pages) => setState(() => _pages = pages ?? 0),
      onPageChanged: (page, _) =>
          setState(() => _currentPage = (page ?? 0) + 1),
      onError: (e) => setState(() => _error = e.toString()),
    );
  }
}
