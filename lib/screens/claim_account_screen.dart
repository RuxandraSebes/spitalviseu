import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../i18n/translations.dart';
import '../theme/app_colors.dart';

/// Shown when a patient still has a placeholder account
/// (email ends with @hipocrate.internal) and logs in for the first time.
///
/// Allows them to update their name and set a real email.
class ClaimAccountScreen extends StatefulWidget {
  final UserModel user;

  const ClaimAccountScreen({super.key, required this.user});

  @override
  State<ClaimAccountScreen> createState() => _ClaimAccountScreenState();

  /// Returns true if this user has a placeholder account pending claim.
  static bool needsClaim(UserModel user) {
    return user.email.endsWith('@hipocrate.internal') ||
        user.name.startsWith('Pacient ');
  }
}

/// Form state for updating name and email on a placeholder account.
class _ClaimAccountScreenState extends State<ClaimAccountScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.user.name;
    if (!widget.user.email.endsWith('@hipocrate.internal')) {
      _emailCtrl.text = widget.user.email;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  /// Validates input and persists the updated profile via [AuthService].
  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (name.isEmpty) {
      _snack(l.get('enter_name_prompt'), isError: true);
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _snack(l.get('enter_valid_email'), isError: true);
      return;
    }

    setState(() => _loading = true);

    final result = await _auth.updateProfile(name: name, email: email);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      _snack(l.get('profile_updated'));
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context, true);
    } else {
      _snack(l.get((result['message'] ?? 'update_error').toString()),
          isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        foregroundColor: Colors.white,
        title: Text(l.get('complete_profile')),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.primaryWithOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryWithOpacity(0.2))),
              child: Column(children: [
                const Icon(Icons.info_outline,
                    color: AppColors.primary, size: 36),
                const SizedBox(height: 12),
                Text(
                  l.get('doc_received'),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l.get('claim_account_desc'),
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade700, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                if (widget.user.cnpPacient != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${l.get('cnp_identified')}: ${widget.user.cnpPacient}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    ),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 28),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  _field(_nameCtrl, l.get('name_full_required'),
                      Icons.person_outline),
                  const SizedBox(height: 16),
                  _field(
                      _emailCtrl, l.get('contact_email'), Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(l.get('save_continue'),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
