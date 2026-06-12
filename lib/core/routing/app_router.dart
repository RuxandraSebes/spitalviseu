import 'package:flutter/material.dart';
import 'package:spital_visu_upu/data/models/user_model.dart';
import 'package:spital_visu_upu/features/admin/presentation/screens/global_admin_screen.dart';
import 'package:spital_visu_upu/features/admin/presentation/screens/hospital_admin_screen.dart';
import 'package:spital_visu_upu/features/auth/presentation/screens/claim_account_screen.dart';
import 'package:spital_visu_upu/features/doctor/presentation/screens/doctor_screen.dart';
import 'package:spital_visu_upu/features/patient/presentation/screens/home_screen.dart';

/// Navigates to the home screen matching [user]'s role after login or register.
Widget roleBasedHome(UserModel user) {
  if (ClaimAccountScreen.needsClaim(user)) {
    return ClaimAccountScreen(user: user);
  }

  switch (user.role) {
    case 'global_admin':
      return GlobalAdminScreen(user: user);
    case 'hospital_admin':
      return HospitalAdminScreen(user: user);
    case 'doctor':
      return DoctorScreen(user: user);
    case 'patient':
    case 'companion':
    default:
      return HomeScreen(user: user);
  }
}
