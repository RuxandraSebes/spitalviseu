import 'package:flutter/material.dart';
import 'package:spital_visu_upu/data/services/auth_service.dart';
import 'package:spital_visu_upu/features/auth/presentation/screens/login_screen.dart';

/// Logs out and navigates to [LoginScreen], clearing the navigation stack.
Future<void> logoutAndNavigateToLogin(BuildContext context) async {
  await AuthService().logout();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}
