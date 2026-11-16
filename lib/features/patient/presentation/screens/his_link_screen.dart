import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spital_visu_upu/core/theme/app_colors.dart';
import 'package:spital_visu_upu/data/services/his_link_service.dart';
import 'package:spital_visu_upu/i18n/translations.dart';
import 'package:spital_visu_upu/shared/widgets/program_emblem_background.dart';

/// Lets a patient link their account to the hospital record by confirming a code
/// sent to the e-mail address the hospital has on file. Pops `true` once linked.
class HisLinkScreen extends StatefulWidget {
  const HisLinkScreen({super.key});

  @override
  State<HisLinkScreen> createState() => _HisLinkScreenState();
}

class _HisLinkScreenState extends State<HisLinkScreen> {
  final _service = HisLinkService();
  final _codeController = TextEditingController();

  bool _loading = true;
  bool? _linked;
  bool _codeRequested = false;
  bool _sending = false;
  bool _confirming = false;
  String? _error;

  String _tr(String key) => AppLocalizations.of(context).get(key);

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final linked = await _service.isLinked();
    if (!mounted) return;
    setState(() {
      _linked = linked;
      _loading = false;
      _error = linked == null ? 'connection_error' : null;
    });
  }

  Future<void> _requestCode() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    final result = await _service.requestCode();
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (result['linked'] == true) {
        _linked = true;
      } else if (result['success'] == true) {
        _codeRequested = true;
        _codeController.clear();
      } else {
        _error = result['message'];
      }
    });
  }

  Future<void> _confirm() async {
    final code = _codeController.text;
    if (code.length != 6) {
      setState(() => _error = 'enter_full_code');
      return;
    }
    setState(() {
      _confirming = true;
      _error = null;
    });
    final result = await _service.confirm(code);
    if (!mounted) return;
    setState(() => _confirming = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_tr('his_linked')),
        backgroundColor: AppColors.success,
      ));
      Navigator.pop(context, true);
    } else {
      setState(() => _error = result['message']);
      _codeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        foregroundColor: Colors.white,
        title: Text(_tr('his_link_title')),
      ),
      body: ProgramEmblemBackground(
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _linked == true
                        ? _linkedContent()
                        : _linkContent(),
                  ),
                ),
        ),
      ),
    );
  }

  List<Widget> _linkedContent() => [
        const SizedBox(height: 24),
        _icon(Icons.verified_user_outlined),
        const SizedBox(height: 20),
        _title(_tr('his_linked_title')),
        const SizedBox(height: 12),
        _body(_tr('his_linked_desc')),
      ];

  List<Widget> _linkContent() => [
        const SizedBox(height: 8),
        _icon(Icons.local_hospital_outlined),
        const SizedBox(height: 20),
        _title(_tr('his_link_title')),
        const SizedBox(height: 12),
        _body(_tr('his_link_intro')),
        const SizedBox(height: 28),
        if (!_codeRequested) ...[
          _primaryButton(
            label: _tr('his_link_send_code'),
            busy: _sending,
            onPressed: _requestCode,
          ),
          if (_error != null) ...[
            const SizedBox(height: 20),
            _errorBox(_tr(_error!)),
          ],
        ] else ...[
          _infoBox(_tr('his_link_code_sent_if_found')),
          const SizedBox(height: 20),
          _codeField(),
          // Right under the field, so it stays visible above the keyboard.
          if (_error != null) ...[
            const SizedBox(height: 12),
            _errorBox(_tr(_error!)),
          ],
          const SizedBox(height: 20),
          _primaryButton(
            label: _tr('his_link_confirm'),
            busy: _confirming,
            onPressed: _confirm,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _sending ? null : _requestCode,
            icon: _sending
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh, size: 18),
            label: Text(_tr('resend_code')),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          const SizedBox(height: 8),
          _body(_tr('his_link_no_code_help'), small: true),
        ],
      ];

  Widget _icon(IconData icon) => Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 40, color: AppColors.primary),
        ),
      );

  Widget _title(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
      );

  Widget _body(String text, {bool small = false}) => Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: small ? 13 : 15,
          height: 1.45,
        ),
      );

  Widget _codeField() => TextField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        textAlign: TextAlign.center,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) {
          if (_error != null) setState(() => _error = null);
          if (v.length == 6 && !_confirming) _confirm();
        },
        style: const TextStyle(
          fontSize: 28,
          letterSpacing: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
        decoration: InputDecoration(
          labelText: _tr('his_link_code_label'),
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      );

  Widget _primaryButton({
    required String label,
    required bool busy,
    required VoidCallback onPressed,
  }) =>
      SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: busy ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _infoBox(String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.mark_email_unread_outlined,
              color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.text, fontSize: 14, height: 1.4)),
          ),
        ]),
      );

  Widget _errorBox(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primaryWithOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error, width: 1.5),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}
