import 'package:spital_visu_upu/data/services/auth_service.dart';

/// Builds authenticated HTTP headers for API requests.
class ApiHeaders {
  ApiHeaders._();

  /// Returns bearer token headers. Set [includeJsonContentType] for JSON POST/PUT bodies.
  static Future<Map<String, String>> bearer({
    bool includeJsonContentType = false,
  }) async {
    final token = await AuthService().getToken();
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
    if (includeJsonContentType) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }
}
