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

/// Modal dialog that shows a bundled PDF (same content as full-screen viewer).
Future<void> showLegalPdfDialog(
  BuildContext context, {
  required String assetPath,
  required String titleKey,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _LegalPdfDialog(
      assetPath: assetPath,
      titleKey: titleKey,
    ),
  );
}

class _LegalPdfDialog extends StatefulWidget {
  final String assetPath;
  final String titleKey;

  const _LegalPdfDialog({
    required this.assetPath,
    required this.titleKey,
  });

  @override
  State<_LegalPdfDialog> createState() => _LegalPdfDialogState();
}

class _LegalPdfDialogState extends State<_LegalPdfDialog> {
  String? _localPath;
  bool _loading = true;
  String? _error;

  bool get _useInAppViewer =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  String _tr(String key) {
    final locale = LanguageProvider.localeOf(context);
    return AppLocalizations(locale).get(key);
  }

  String _safeFileName(String assetPath) =>
      assetPath.split('/').last.replaceAll(RegExp(r'[^\w\.\-]'), '_');

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

      if (!_useInAppViewer) {
        final launched = await launchUrl(
          Uri.file(file.path),
          mode: LaunchMode.externalApplication,
        );
        if (mounted) {
          Navigator.of(context).pop();
          if (!launched) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_tr('pdf_open_external_failed'))),
            );
          }
        }
        return;
      }

      setState(() {
        _localPath = file.path;
        _loading = false;
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

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.78;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH, maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _tr(widget.titleKey),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: _tr('close'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: _loading
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                              color: AppColors.primary),
                          const SizedBox(height: 16),
                          Text(_tr('loading_document')),
                        ],
                      ),
                    )
                  : _error != null
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.error)),
                        )
                      : ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16)),
                          child: SizedBox(
                            height: maxH - 72,
                            child: PDFView(
                              filePath: _localPath!,
                              enableSwipe: true,
                              swipeHorizontal: false,
                              autoSpacing: true,
                              pageFling: true,
                              onError: (e) =>
                                  setState(() => _error = e.toString()),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
