import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spital_visu_upu/data/services/auth_service.dart';
import 'package:spital_visu_upu/data/models/user_model.dart';
import 'package:spital_visu_upu/i18n/language_provider.dart';
import 'package:spital_visu_upu/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:spital_visu_upu/core/theme/app_colors.dart';
import 'package:spital_visu_upu/shared/widgets/app_footer.dart';
import 'package:spital_visu_upu/features/legal/presentation/widgets/legal_text_dialog.dart';
import 'package:spital_visu_upu/core/routing/app_router.dart';
import 'package:spital_visu_upu/features/legal/presentation/screens/asset_pdf_viewer_screen.dart';

/// Registration form for patient and companion accounts.
class RegisterScreen extends StatefulWidget {
  final String? preselectedRole;
  final String? inviteToken;

  const RegisterScreen({
    super.key,
    this.preselectedRole,
    this.inviteToken,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cnpController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _loadingHospitals = true;
  bool _obscurePassword = true;

  late String _selectedRole;
  List<Map<String, dynamic>> _hospitals = [];
  int? _selectedHospitalId;

  String? _inlineError;

  String? _cnpError;
  bool _cnpValid = false;

  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _acceptedDisclaimer = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.preselectedRole ?? 'patient';
    _loadHospitals();
    _cnpController.addListener(_validateCnpRealTime);
  }

  /// Validates CNP length and digit format as the user types.
  void _validateCnpRealTime() {
    final cnp = _cnpController.text.trim();
    if (cnp.isEmpty) {
      setState(() {
        _cnpError = null;
        _cnpValid = false;
      });
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(cnp)) {
      setState(() {
        _cnpError = _tr('cnp_invalid');
        _cnpValid = false;
      });
      return;
    }
    if (cnp.length < 13) {
      setState(() {
        _cnpError = '${cnp.length}/13 cifre';
        _cnpValid = false;
      });
      return;
    }
    if (cnp.length == 13) {
      setState(() {
        _cnpError = null;
        _cnpValid = true;
      });
    } else {
      setState(() {
        _cnpError = _tr('cnp_invalid');
        _cnpValid = false;
      });
    }
  }

  String _tr(String key) => LanguageProvider.of(context)?.tr(key) ?? key;

  /// Loads the hospital picker options from the public API.
  Future<void> _loadHospitals() async {
    final list = await _authService.getHospitals();
    if (mounted) {
      setState(() {
        _hospitals = list;
        _loadingHospitals = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cnpController.removeListener(_validateCnpRealTime);
    _cnpController.dispose();
    super.dispose();
  }

  void _setError(String msg) => setState(() => _inlineError = msg);
  void _clearError() {
    if (_inlineError != null) setState(() => _inlineError = null);
  }

  /// Returns an error message when one or more required legal consents are missing.
  String? _legalValidationError() {
    final missing = <String>[];
    if (!_acceptedTerms) missing.add('terms');
    if (!_acceptedPrivacy) missing.add('privacy');
    if (!_acceptedDisclaimer) missing.add('disclaimer');

    if (missing.isEmpty) {
      return null;
    }

    if (missing.length > 1) {
      return _tr('error_accept_legal_all');
    }

    switch (missing.single) {
      case 'terms':
        return _tr('error_accept_terms');
      case 'privacy':
        return _tr('error_accept_privacy');
      case 'disclaimer':
        return _tr('error_accept_disclaimer');
    }

    return _tr('error_accept_legal_all');
  }

  void _showPrivacyPolicy() {
    showLegalTextDialog(
      context,
      titleKey: 'legal_privacy_title',
      bodyKey: 'legal_privacy_body',
    );
  }

  void _showTermsAndConditions() {
    showLegalTextDialog(
      context,
      titleKey: 'legal_terms_title',
      bodyKey: 'legal_terms_body',
    );
  }

  /// Opens the project disclaimer PDF bundled with the app.
  void _showDisclaimer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AssetPdfViewerScreen(
          assetPath: 'assets/disclaimer huskroua.pdf',
          titleKey: 'about_disclaimer',
        ),
      ),
    );
  }

  /// Validates the form and submits registration to the backend.
  Future<void> _handleRegister() async {
    _clearError();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final cnp = _cnpController.text.trim();

    if (name.isEmpty) {
      _setError(_tr('enter_name'));
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _setError(_tr('invalid_email'));
      return;
    }
    if (password.length < 6) {
      _setError(_tr('password_short'));
      return;
    }
    if (cnp.isEmpty) {
      _setError(_tr('cnp_required'));
      return;
    }
    if (cnp.length != 13 || !RegExp(r'^\d{13}$').hasMatch(cnp)) {
      _setError(_tr('cnp_invalid'));
      return;
    }
    final legalError = _legalValidationError();
    if (legalError != null) {
      _setError(legalError);
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
      cnp: cnp,
      role: _selectedRole,
      hospitalId: _selectedHospitalId,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (result['needs_verification'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(
              userId: result['user_id'] as int,
              email: result['email'] as String,
            ),
          ),
        );
      } else {
        final user = result['user'] as UserModel;
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => roleBasedHome(user)),
            (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
        actions: const [LanguageDropdown()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_tr('create_account'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              const SizedBox(height: 6),
              Text(_tr('register_subtitle'),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey.shade600)),
              const SizedBox(height: 24),

              Row(children: [
                _roleChip(
                    label: _tr('patient'),
                    icon: Icons.personal_injury_outlined,
                    value: 'patient'),
                const SizedBox(width: 12),
                _roleChip(
                    label: _tr('companion'),
                    icon: Icons.people_alt_outlined,
                    value: 'companion'),
              ]),
              const SizedBox(height: 8),
              Text(
                _selectedRole == 'patient'
                    ? _tr('patient_desc')
                    : _tr('companion_desc'),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 20),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    _buildField(
                        controller: _nameController,
                        label: '${_tr('name')} *',
                        icon: Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildField(
                        controller: _emailController,
                        label: '${_tr('email')} *',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _buildField(
                        controller: _passwordController,
                        label: _tr('password_min'),
                        icon: Icons.lock_outline,
                        obscure: _obscurePassword,
                        suffix: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        )),
                    const SizedBox(height: 16),

                    _buildCnpField(),

                    const SizedBox(height: 16),
                    _buildHospitalPicker(),

                    const SizedBox(height: 20),
                    _legalCheckbox(
                      value: _acceptedTerms,
                      required: true,
                      onChanged: (v) =>
                          setState(() => _acceptedTerms = v ?? false),
                      prefix: _tr('accept_terms_prefix'),
                      linkLabel: _tr('terms_and_conditions'),
                      onLinkTap: _showTermsAndConditions,
                    ),
                    const SizedBox(height: 8),
                    _legalCheckbox(
                      value: _acceptedPrivacy,
                      required: true,
                      onChanged: (v) =>
                          setState(() => _acceptedPrivacy = v ?? false),
                      prefix: _tr('accept_privacy_prefix'),
                      linkLabel: _tr('privacy_policy'),
                      onLinkTap: _showPrivacyPolicy,
                    ),
                    const SizedBox(height: 8),
                    _legalCheckbox(
                      value: _acceptedDisclaimer,
                      required: true,
                      onChanged: (v) =>
                          setState(() => _acceptedDisclaimer = v ?? false),
                      prefix: _tr('accept_disclaimer_prefix'),
                      linkLabel: _tr('about_disclaimer'),
                      onLinkTap: _showDisclaimer,
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(_tr('create_account'),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),

                    if (_inlineError != null) ...[
                      const SizedBox(height: 16),
                      _inlineErrorWidget(_inlineError!),
                    ],
                  ]),
                ),
              ),

              if (_selectedRole == 'companion') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _tr('companion_info_note'),
                        style: const TextStyle(
                            fontSize: 13, color: Colors.deepOrange),
                      ),
                    ),
                  ]),
                ),
              ],

              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_tr('have_account'),
                      style: const TextStyle(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 16),
                ],
              ),
            ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _legalCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String prefix,
    required String linkLabel,
    required VoidCallback onLinkTap,
    bool required = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.text,
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: prefix),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: onLinkTap,
                      child: Text(
                        linkLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCnpField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _cnpController,
          keyboardType: TextInputType.number,
          maxLength: 13,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _clearError(),
          decoration: InputDecoration(
            labelText: _tr('cnp_field'),
            helperText: _selectedRole == 'patient'
                ? _tr('cnp_hipocrate')
                : _tr('cnp_companion_hint'),
            helperMaxLines: 2,
            counterText: '',
            prefixIcon: Icon(
              Icons.badge_outlined,
              color: _cnpValid
                  ? AppColors.primary
                  : _cnpError != null
                      ? AppColors.error
                      : AppColors.primary,
            ),
            suffixIcon: _cnpController.text.isNotEmpty
                ? Icon(
                    _cnpValid ? Icons.check_circle : Icons.error_outline,
                    color:
                        _cnpValid ? AppColors.primary : AppColors.error,
                    size: 20,
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _cnpValid
                    ? AppColors.primaryWithOpacity(0.5)
                    : _cnpError != null
                        ? AppColors.primaryWithOpacity(0.5)
                        : Colors.grey.shade300,
                width: _cnpValid || _cnpError != null ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    _cnpValid ? AppColors.primary : AppColors.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: _cnpValid
                ? AppColors.primaryWithOpacity(0.08)
                : _cnpError != null
                    ? AppColors.primaryWithOpacity(0.08)
                    : Colors.grey.shade50,
          ),
        ),
        if (_cnpController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_cnpController.text.trim().length / 13).clamp(0, 1),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      _cnpValid
                          ? AppColors.primary
                          : _cnpController.text.trim().length < 8
                              ? AppColors.primaryWithOpacity(0.5)
                              : AppColors.primaryWithOpacity(0.5),
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _cnpValid
                    ? _tr('valid_status')
                    : _cnpError ?? '${_cnpController.text.trim().length}/13',
                style: TextStyle(
                  fontSize: 11,
                  color:
                      _cnpValid ? AppColors.primary : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
      ],
    );
  }

  Widget _buildHospitalPicker() {
    if (_loadingHospitals) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primary),
        ),
      );
    }
    if (_hospitals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryWithOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Icon(Icons.warning_amber_outlined,
              color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
            _tr('hospital_load_error'),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          )),
        ]),
      );
    }
    return DropdownButtonFormField<int?>(
      value: _selectedHospitalId,
      decoration: InputDecoration(
        labelText: _tr('hospital_optional'),
        prefixIcon:
            const Icon(Icons.local_hospital_outlined, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        filled: true,
        fillColor: Colors.grey.shade50,
        helperText: _tr('select_hospital'),
      ),
      items: [
        DropdownMenuItem<int?>(value: null, child: Text(_tr('no_hospital'))),
        ..._hospitals.map((h) => DropdownMenuItem<int?>(
              value: h['id'] as int,
              child: Text('${h['name']} — ${h['city']}',
                  overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: (v) => setState(() => _selectedHospitalId = v),
    );
  }

  Widget _roleChip(
      {required String label, required IconData icon, required String value}) {
    final selected = _selectedRole == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _clearError();
          setState(() => _selectedRole = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(children: [
            Icon(icon,
                color: selected ? Colors.white : Colors.grey.shade500,
                size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: selected ? Colors.white : Colors.grey.shade700,
                )),
          ]),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? helperText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      onChanged: (_) => _clearError(),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperMaxLines: 2,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _inlineErrorWidget(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryWithOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error, width: 1.5),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.error_outline, color: AppColors.error, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(message,
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center)),
      ]),
    );
  }
}
