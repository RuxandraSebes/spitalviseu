import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:spital_visu_upu/core/constants/api_constants.dart';
import 'package:spital_visu_upu/data/services/auth_service.dart';
import 'package:spital_visu_upu/i18n/translations.dart';
import 'package:spital_visu_upu/core/theme/app_colors.dart';
import 'package:spital_visu_upu/shared/widgets/program_emblem_background.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String name;

  const PdfViewerScreen({super.key, required this.url, required this.name});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  bool _loading = true;
  String? _error;
  int _pages = 0;
  int _currentPage = 0;

  String _tr(String key) => AppLocalizations.of(context).get(key);

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    final client = http.Client();
    try {
      final baseUrl = ApiConstants.serverUrl;
      final url = widget.url.startsWith('http')
          ? widget.url
          : '$baseUrl/${widget.url.replaceFirst(RegExp(r'^/'), '')}';

      final request = http.Request('GET', Uri.parse(url));
      // Documents are served only to logged-in users; never send the token elsewhere.
      if (ApiConstants.isApiServer(request.url)) {
        final token = await AuthService().getToken();
        if (token != null) request.headers['Authorization'] = 'Bearer $token';
      }
      final response =
          await client.send(request).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            _error = '${_tr('pdf_download_error')} (${response.statusCode})';
            _loading = false;
          });
        }
        return;
      }

      final bytes =
          await response.stream.toBytes().timeout(const Duration(seconds: 60));

      final dir = await getTemporaryDirectory();
      final safeFileName = widget.name.replaceAll(RegExp(r'[^\w\.]'), '_');
      final file = File('${dir.path}/$safeFileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        setState(() {
          _localPath = file.path;
          _loading = false;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _error = _tr('pdf_timeout_error');
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '${_tr('pdf_generic_error')}: $e';
          _loading = false;
        });
      }
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        foregroundColor: Colors.white,
        title: Text(widget.name, style: const TextStyle(fontSize: 15)),
        actions: [
          if (_pages > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text('$_currentPage / $_pages',
                    style: const TextStyle(color: Colors.white70)),
              ),
            ),
        ],
      ),
      body: ProgramEmblemBackground(
        child: _loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(_tr('downloading')),
                  ],
                ),
              )
            : _error != null
                ? Center(
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
                            });
                            _downloadPdf();
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(_tr('retry')),
                        ),
                      ],
                    ),
                  )
                : PDFView(
                    filePath: _localPath!,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: true,
                    pageFling: true,
                    onRender: (pages) => setState(() => _pages = pages ?? 0),
                    onPageChanged: (page, _) =>
                        setState(() => _currentPage = (page ?? 0) + 1),
                    onError: (e) => setState(() => _error = e.toString()),
                  ),
      ),
    );
  }
}
