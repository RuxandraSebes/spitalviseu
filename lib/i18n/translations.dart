import 'package:flutter/material.dart';
import 'ro.dart';
import 'en.dart';
import 'hu.dart';
import 'uk.dart';
import 'sk.dart';
import 'legal_texts.dart';

/// Resolves localized strings for the active [locale].
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  /// Returns localizations for [context], defaulting to Romanian.
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('ro'));
  }

  /// Looks up [key] in legal texts first, then the locale translation map.
  String get(String key) {
    final code = locale.languageCode;
    final legal = legalTextsByLocale[code] ?? legalTextsByLocale['ro']!;
    if (legal.containsKey(key)) return legal[key]!;
    final map = _translationsMap[code] ?? translationsRo;
    return map[key] ?? key;
  }

  static const Map<String, Map<String, String>> _translationsMap = {
    'ro': translationsRo,
    'en': translationsEn,
    'hu': translationsHu,
    'uk': translationsUk,
    'sk': translationsSk,
  };
}

/// Loads [AppLocalizations] for supported locales.
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ro', 'en', 'hu', 'uk', 'sk'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_) => false;
}
