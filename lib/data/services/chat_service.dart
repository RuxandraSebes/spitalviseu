import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spital_visu_upu/core/constants/api_constants.dart';
import 'package:spital_visu_upu/core/network/api_headers.dart';
import 'package:spital_visu_upu/data/services/auth_service.dart';
import 'package:spital_visu_upu/i18n/backend_message_mapper.dart';

/// Handles chat conversation and message API calls.
class ChatService {
  static const String _base = AuthService.baseUrl;

  /// Lists conversations for the current user.
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final r = await http.get(
        Uri.parse('$_base/chat/conversations'),
        headers: await ApiHeaders.bearer(includeJsonContentType: true),
      );
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        return List<Map<String, dynamic>>.from(data['conversations']);
      }
    } catch (_) {}
    return [];
  }

  /// Returns messages for the conversation identified by [patientId].
  Future<List<Map<String, dynamic>>> getMessages(int patientId) async {
    try {
      final r = await http.get(
        Uri.parse('$_base/chat/messages?patient_id=$patientId'),
        headers: await ApiHeaders.bearer(includeJsonContentType: true),
      );
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        return List<Map<String, dynamic>>.from(data['messages']);
      }
    } catch (_) {}
    return [];
  }

  /// Marks all messages in the conversation for [patientId] as seen.
  Future<Map<String, dynamic>> markSeen(int patientId) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/conversations/seen'),
      headers: await ApiHeaders.bearer(includeJsonContentType: true),
      body: {
        'patient_id': patientId.toString(),
      },
    );

    if (response.statusCode == 200) {
      return {'success': true};
    }

    return {'success': false};
  }

  /// Sends [message] in the conversation for [patientId].
  Future<Map<String, dynamic>> sendMessage(
      int patientId, String message) async {
    try {
      final r = await http.post(
        Uri.parse('$_base/chat/messages'),
        headers: await ApiHeaders.bearer(includeJsonContentType: true),
        body: json.encode({'patient_id': patientId, 'message': message}),
      );
      final data = json.decode(r.body);
      if (r.statusCode == 201) {
        return {'success': true, 'message': backendMessageKey(data['message'])};
      }
      return {
        'success': false,
        'error': backendMessageKey(data['message'] ?? 'error')
      };
    } catch (_) {
      return {'success': false, 'error': 'connection_error'};
    }
  }
}
