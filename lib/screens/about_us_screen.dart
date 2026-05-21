import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/language_provider.dart';
import '../i18n/translations.dart';
import '../theme/app_colors.dart';
import '../widgets/app_footer.dart';
import 'asset_pdf_viewer_screen.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const _logoAcronymAsset = 'assets/logo_with acronym-01.png';
  static const _pictogramAsset = 'assets/pictograma P2_inverse.png';
  static const _sloganAsset = 'assets/slogan-01.png';
  static const _programmeLogoAsset =
      'assets/emblemaHUSKROUA ENI logo_final_grey_20-01.png';
  static const _disclaimerPdfAsset = 'assets/disclaimer huskroua.pdf';

  Future<void> _openUrl(BuildContext context, String url) async {
    final locale = LanguageProvider.localeOf(context);
    String tr(String key) => AppLocalizations(locale).get(key);
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('link_open_failed'))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('link_open_failed'))),
        );
      }
    }
  }

  void _openDisclaimer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AssetPdfViewerScreen(
          assetPath: _disclaimerPdfAsset,
          titleKey: 'about_disclaimer',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = LanguageProvider.localeOf(context);
    String tr(String key) => AppLocalizations(locale).get(key);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.white,
        title: Text(tr('about_us')),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Image.asset(
                          _logoAcronymAsset,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Image.asset(
                          _pictogramAsset,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    tr('about_project_title'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('about_project_subtitle'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr('about_project_description'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.text,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _infoCard(
                    icon: Icons.calendar_today_outlined,
                    label: tr('about_period_label'),
                    value: tr('about_period_value'),
                  ),
                  const SizedBox(height: 12),
                  _infoCard(
                    icon: Icons.euro_outlined,
                    label: tr('about_eu_contribution_label'),
                    value: tr('about_eu_contribution_value'),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Image.asset(
                      _programmeLogoAsset,
                      height: 64,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr('about_partners_label'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _partnerTile(tr('about_partner_leader'), isLeader: true),
                  _partnerTile(tr('about_partner_ua')),
                  _partnerTile(tr('about_partner_hu')),
                  _partnerTile(tr('about_partner_sk')),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => _openUrl(
                        context, 'https://next.huskroua-cbc.eu/'),
                    icon: const Icon(Icons.language_outlined),
                    label: Text(tr('about_program_website')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _openDisclaimer(context),
                    icon: const Icon(Icons.description_outlined),
                    label: Text(tr('about_disclaimer')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Image.asset(
                    _sloganAsset,
                    width: double.infinity,
                    height: 500,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _partnerTile(String name, {bool isLeader = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isLeader
              ? AppColors.primaryWithOpacity(0.08)
              : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isLeader ? AppColors.primary : AppColors.border,
            width: isLeader ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isLeader ? Icons.star_outline : Icons.local_hospital_outlined,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isLeader ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
