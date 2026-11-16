import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spital_visu_upu/core/constants/api_constants.dart';
import 'package:spital_visu_upu/core/network/api_headers.dart';
import 'package:spital_visu_upu/i18n/backend_message_mapper.dart';

/// Links the patient account to the hospital record, so UPU sheets reach the app.
class HisLinkService {
  static const String _base = '${ApiConstants.baseUrl}/his-link';

  /// Whether the account is already linked; null when the server is unreachable.
  Future<bool?> isLinked() async {
    try {
      final r = await http.get(Uri.parse(_base),
          headers: await ApiHeaders.bearer());
      if (r.statusCode != 200) return null;
      return json.decode(r.body)['linked'] == true;
    } catch (_) {
      return null;
    }
  }

  /// Asks the server to e-mail a code to the address the hospital has on file.
  /// The answer is the same whether or not a code was sent.
  Future<Map<String, dynamic>> requestCode() =>
      _post('$_base/request', null, okStatuses: const [200, 202]);

  /// Confirms the 6-digit code and links the account.
  Future<Map<String, dynamic>> confirm(String code) =>
      _post('$_base/confirm', {'code': code}, okStatuses: const [200]);

  Future<Map<String, dynamic>> _post(String url, Map<String, dynamic>? body,
      {required List<int> okStatuses}) async {
    try {
      final r = await http.post(
        Uri.parse(url),
        headers: await ApiHeaders.bearer(includeJsonContentType: true),
        body: body == null ? null : json.encode(body),
      );
      if (r.statusCode == 429) {
        return {'success': false, 'message': 'his_too_many_requests'};
      }
      final data = json.decode(r.body);
      return {
        'success': okStatuses.contains(r.statusCode),
        'linked': data['linked'] == true,
        'message': backendMessageKey(data['message'] ?? 'error'),
      };
    } catch (_) {
      return {'success': false, 'message': 'connection_error'};
    }
  }
}
