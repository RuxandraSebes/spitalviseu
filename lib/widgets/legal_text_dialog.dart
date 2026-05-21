import 'package:flutter/material.dart';

import '../i18n/language_provider.dart';
import '../i18n/translations.dart';
import '../theme/app_colors.dart';

/// Scrollable modal with legal text (terms / privacy) in the current language.
Future<void> showLegalTextDialog(
  BuildContext context, {
  required String titleKey,
  required String bodyKey,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _LegalTextDialog(
      titleKey: titleKey,
      bodyKey: bodyKey,
    ),
  );
}

class _LegalTextDialog extends StatelessWidget {
  final String titleKey;
  final String bodyKey;

  const _LegalTextDialog({
    required this.titleKey,
    required this.bodyKey,
  });

  @override
  Widget build(BuildContext context) {
    final locale = LanguageProvider.localeOf(context);
    String tr(String key) => AppLocalizations(locale).get(key);
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
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tr(titleKey),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: tr('close'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: SelectableText(
                  tr(bodyKey),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: AppColors.text,
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
