import 'package:flutter/material.dart';

/// Brand palette: white, black, and primary red (#D13824).
abstract final class AppColors {
  static const Color primary = Color(0xFFD13824);
  static const Color primaryDark = Color(0xFFA82D1D);
  /// Darker red for app bars — improves contrast for flags and badges.
  static const Color appBar = Color(0xFF8B2218);

  /// Chat participant colors (legend + message role labels).
  static const Color chatDoctor = Color(0xFF1A5276);
  static const Color chatPatient = Color(0xFFD13824);
  static const Color chatCompanion = Color(0xFF4E342E);

  static const Color unreadBadgeBg = white;
  static const Color unreadBadgeText = black;
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF4A4A4A);
  static const Color textMuted = Color(0xFF757575);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F7F7);
  static const Color border = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFB02A1A);
  static const Color success = Color(0xFF000000);

  /// Role badges — monochrome + primary accents only.
  static const Color roleGlobalAdmin = primary;
  static const Color roleHospitalAdmin = Color(0xFF333333);
  static const Color roleDoctor = Color(0xFF1A1A1A);
  static const Color rolePatient = primary;
  static const Color roleCompanion = Color(0xFF666666);

  static Color primaryWithOpacity(double opacity) =>
      primary.withValues(alpha: opacity);
}
