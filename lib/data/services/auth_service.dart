import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:spital_visu_upu/core/constants/api_constants.dart';
import 'package:spital_visu_upu/data/models/user_model.dart';
import 'package:spital_visu_upu/i18n/backend_message_mapper.dart';

/// Handles authentication, token storage, and profile API calls.
class AuthService {
  static const String baseUrl = ApiConstants.baseUrl;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  final _storage = const FlutterSecureStorage();

  /// Returns the stored bearer token, or null if not logged in.
  Future<String?> getToken() => _storage.read(key: _tokenKey);

  /// Returns true when a non-empty auth token is stored locally.
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Returns the cached user from secure storage, or null if missing or invalid.
  Future<UserModel?> getCachedUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(json.decode(raw));
    } catch (_) {
      return null;
    }
  }

  /// Persists user JSON to secure storage after login or profile update.
  Future<void> _saveUser(Map<String, dynamic> userJson) async {
    await _storage.write(key: _userKey, value: json.encode(userJson));
  }

  /// Returns HTTP headers with the current bearer token.
  Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  /// Fetches the public hospital list for the register screen picker.
  Future<List<Map<String, dynamic>>> getHospitals() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hospitals/public'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['hospitals']);
      }
    } catch (_) {}
    return [];
  }

  /// Authenticates with email and password; stores token and user on success.
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await _storage.write(key: _tokenKey, value: data['token']);
        await _saveUser(data['user']);
        return {'success': true, 'user': UserModel.fromJson(data['user'])};
      }

      return {
        'success': false,
        'message':
            backendMessageKey(data['message'] ?? 'error_invalid_credentials')
      };
    } catch (e) {
      return {'success': false, 'message': 'connection_error'};
    }
  }

  /// Registers a new user. Patient/companion accounts require email verification.
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? cnp,
    String role = 'patient',
    int? hospitalId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
          'role': role,
          if (cnp != null && cnp.isNotEmpty) 'cnp_pacient': cnp,
          if (hospitalId != null) 'hospital_id': hospitalId,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'user_id': data['user_id'] as int,
          'email': data['email'] as String,
          'needs_verification': data['needs_verification'] ?? false,
        };
      }

      String message = data['message'] ?? 'error_register';
      if (data['errors'] != null) {
        final errors = data['errors'] as Map<String, dynamic>;
        message = (errors.values.first as List).first.toString();
      } else {
        message = backendMessageKey(message);
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'connection_error'};
    }
  }

  /// Verifies a 6-digit email code and stores the auth token on success.
  Future<Map<String, dynamic>> verifyEmail({
    required int userId,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': userId, 'code': code}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await _storage.write(key: _tokenKey, value: data['token'] as String);
        await _saveUser(data['user'] as Map<String, dynamic>);
        return {'success': true, 'user': UserModel.fromJson(data['user'])};
      }

      return {'success': false, 'message': data['message'] ?? 'error'};
    } catch (e) {
      return {'success': false, 'message': 'connection_error'};
    }
  }

  /// Requests a new verification code for [userId].
  Future<Map<String, dynamic>> resendVerification({
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-verification'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': userId}),
      );

      final data = json.decode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'error',
      };
    } catch (e) {
      return {'success': false, 'message': 'connection_error'};
    }
  }

  /// Updates the authenticated user's name and email.
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      final headers = await authHeaders();
      headers['Content-Type'] = 'application/json';

      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
        body: jsonEncode({'name': name, 'email': email}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        await _saveUser(data['user']);
        return {'success': true, 'user': UserModel.fromJson(data['user'])};
      }
      return {
        'success': false,
        'message': backendMessageKey(data['message'] ?? 'update_error')
      };
    } catch (e) {
      return {'success': false, 'message': 'connection_error'};
    }
  }

  /// Fetches the current user from `/me` and refreshes the local cache.
  Future<UserModel?> fetchMe() async {
    try {
      final headers = await authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveUser(data);
        return UserModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// Revokes the token on the server and clears local auth storage.
  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: await authHeaders(),
        );
      }
    } catch (_) {
    } finally {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    }
  }
}
