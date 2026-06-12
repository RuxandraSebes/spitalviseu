import 'package:flutter/material.dart';
import 'package:spital_visu_upu/core/theme/app_colors.dart';

/// Shows a success or error snackbar using app theme colors.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ),
  );
}
