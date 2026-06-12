import 'package:flutter/material.dart';
import 'package:spital_visu_upu/app/my_app.dart';
import 'package:spital_visu_upu/i18n/language_provider.dart';

/// Application entry point.
void main() {
  runApp(
    const LanguageProvider(
      child: MyApp(),
    ),
  );
}
