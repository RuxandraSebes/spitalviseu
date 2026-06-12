import 'package:flutter/material.dart';
import 'package:spital_visu_upu/data/services/access_code_service.dart';
import 'package:spital_visu_upu/data/services/auth_service.dart';
import 'package:spital_visu_upu/i18n/translations.dart';
import 'package:spital_visu_upu/features/auth/presentation/screens/register_screen.dart';
import 'package:spital_visu_upu/features/auth/presentation/screens/login_screen.dart';
import 'package:spital_visu_upu/core/theme/app_colors.dart';
import 'package:spital_visu_upu/core/routing/app_router.dart';
import 'package:spital_visu_upu/shared/widgets/program_emblem_background.dart';

/// Shown when the app is opened via the email invite deep-link:
///   spitalapp://invite/<token>
/// or when the companion manually pastes a token.
///
/// Flow:
///   1. Check if user is logged in
///      - Yes → redeem token immediately → navigate to home
///      - No  → show Login / Register options, then redeem after auth
class InviteTokenScreen extends StatefulWidget {
  final String token;

  const InviteTokenScreen({super.key, required this.token});

  @override
  State<InviteTokenScreen> createState() => _InviteTokenScreenState();
}

class _InviteTokenScreenState extends State<InviteTokenScreen> {
  final _service = AccessCodeService();
  final _auth = AuthService();

  bool _loading = true;
  bool _isLoggedIn = false;
  bool _redeeming = false;
  bool _success = false;
  String? _patientName;
  String? _error;

  String _tr(String key) => AppLocalizations.of(context).get(key);

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await _auth.isLoggedIn();
    if (!mounted) return;
    setState(() {
      _isLoggedIn = loggedIn;
      _loading = false;
    });

    if (loggedIn) {
      // Check role — only companions should redeem
      final user = await _auth.getCachedUser();
      if (user != null && user.isCompanion) {
        _redeemNow();
      } else if (user != null && !user.isCompanion) {
        setState(() => _error = _tr('companion_only_error'));
      }
    }
  }

  Future<void> _redeemNow() async {
    setState(() {
      _redeeming = true;
      _error = null;
    });

    final result = await _service.redeemEmailInvite(widget.token);
    if (!mounted) return;
    setState(() => _redeeming = false);

    if (result['success'] == true) {
      setState(() {
        _success = true;
        _patientName = result['patient']?['name'] as String?;
      });
    } else {
      setState(() =>
          _error = _tr((result['message'] as String?) ?? 'token_invalid'));
    }
  }

  void _goHome() async {
    final user = await _auth.getCachedUser();
    if (!mounted) return;
    if (user == null) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
      return;
    }
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => roleBasedHome(user)), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        foregroundColor: Colors.white,
        title: Text(_tr('access_invitation')),
      ),
      body: ProgramEmblemBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _success
                    ? _successView()
                    : _isLoggedIn
                        ? _redeemView()
                        : _authChoiceView(),
          ),
        ),
      ),
    );
  }

  // ── Success view ────────────────────────────────────────────────────────────

  Widget _successView() {
    return Center(
      child: Column(children: [
        const SizedBox(height: 40),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
              color: AppColors.primaryWithOpacity(0.08), shape: BoxShape.circle),
          child: Icon(Icons.check_circle_outline,
              size: 60, color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        Text(_tr('association_success'),
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
        const SizedBox(height: 12),
        Text(
          '${_tr('invite_success_desc_prefix')}${_patientName != null ? '\n$_patientName' : ''}.\n'
          '${_tr('invite_success_desc_suffix')}',
          style:
              TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _goHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(_tr('go_to_documents'),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  // ── Redeem view (logged in companion) ──────────────────────────────────────

  Widget _redeemView() {
    return Center(
      child: Column(children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mail_outline,
              size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text(_tr('invite_received'),
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
        const SizedBox(height: 12),
        Text(
          _tr('invite_patient_desc'),
          style:
              TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
          textAlign: TextAlign.center,
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppColors.primaryWithOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error)),
            child: Row(children: [
              Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(_error!,
                      style: TextStyle(color: AppColors.error))),
            ]),
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _redeeming ? null : _redeemNow,
            icon: _redeeming
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.link),
            label: Text(
              _redeeming ? _tr('verifying') : _tr('accept_invite'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Auth choice view (not logged in) ───────────────────────────────────────

  Widget _authChoiceView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.primary.withOpacity(0.15))),
          child: Column(children: [
            const Icon(Icons.mail_outline, size: 40, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(_tr('invite_medical_access'),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
            const SizedBox(height: 8),
            Text(
              _tr('invite_auth_desc'),
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
              if (!mounted) return;
              final loggedIn = await _auth.isLoggedIn();
              if (loggedIn) {
                setState(() => _isLoggedIn = true);
                _redeemNow();
              }
            },
            icon: const Icon(Icons.login),
            label: Text(_tr('already_have_account_login'),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => RegisterScreen(
                            preselectedRole: 'companion',
                            inviteToken: widget.token,
                          )));
              if (!mounted) return;
              final loggedIn = await _auth.isLoggedIn();
              if (loggedIn) {
                setState(() => _isLoggedIn = true);
                _redeemNow();
              }
            },
            icon: const Icon(Icons.person_add_outlined),
            label: Text(_tr('invite_new_companion_account'),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppColors.primaryWithOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryWithOpacity(0.3))),
          child: Row(children: [
            Icon(Icons.timer_outlined, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text(_tr('invite_valid_notice'),
                    style:
                        TextStyle(color: AppColors.primaryDark, fontSize: 12))),
          ]),
        ),
      ],
    );
  }
}
