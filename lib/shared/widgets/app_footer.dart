import 'package:flutter/material.dart';
import 'package:spital_visu_upu/i18n/language_provider.dart';
import 'package:spital_visu_upu/i18n/translations.dart';
import 'package:spital_visu_upu/features/legal/presentation/screens/about_us_screen.dart';
import 'package:spital_visu_upu/core/theme/app_colors.dart';

/// App-wide footer with programme logos and About Us link.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  static const _logoAcronymAsset = 'assets/logo_with acronym-01.png';
  static const _pictogramAsset = 'assets/pictograma P2_inverse.png';

  @override
  Widget build(BuildContext context) {
    final locale = LanguageProvider.localeOf(context);
    String tr(String key) => AppLocalizations(locale).get(key);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  _logoAcronymAsset,
                  height: 54,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AboutUsScreen()),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    tr('about_us'),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Image.asset(
                  _pictogramAsset,
                  height: 52,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
