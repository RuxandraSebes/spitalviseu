import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:spital_visu_upu/app/auth_gate.dart';
import 'package:spital_visu_upu/core/theme/app_theme.dart';
import 'package:spital_visu_upu/i18n/language_provider.dart';
import 'package:spital_visu_upu/i18n/translations.dart';

/// Root widget configuring locale, theme, and the auth gate.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = LanguageProvider.localeOf(context);

    return MaterialApp(
      title: 'Spital Vișeu UPU',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ro'),
        Locale('en'),
        Locale('hu'),
        Locale('uk'),
        Locale('sk'),
      ],
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}
