import 'package:flutter/material.dart';
import 'package:spital_visu_upu/core/routing/app_router.dart';
import 'package:spital_visu_upu/core/theme/app_colors.dart';
import 'package:spital_visu_upu/data/models/user_model.dart';
import 'package:spital_visu_upu/data/services/auth_service.dart';
import 'package:spital_visu_upu/features/auth/presentation/screens/claim_account_screen.dart';
import 'package:spital_visu_upu/features/auth/presentation/screens/login_screen.dart';

/// Checks local token and routes to the correct screen.
/// Also detects Hipocrate auto-created patients and shows the claim screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isLoggedIn(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)));
        }
        if (snap.data == true) {
          return FutureBuilder<UserModel?>(
            future: AuthService().getCachedUser(),
            builder: (context, userSnap) {
              if (!userSnap.hasData) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }
              final user = userSnap.data;
              if (user == null) return const LoginScreen();

              if (ClaimAccountScreen.needsClaim(user)) {
                return ClaimAccountScreen(user: user);
              }

              return roleBasedHome(user);
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}
