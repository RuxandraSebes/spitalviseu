import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:spital_visu_upu/core/constants/api_constants.dart';
import 'package:spital_visu_upu/core/network/api_headers.dart';
import 'package:spital_visu_upu/data/services/auth_service.dart';
import 'package:spital_visu_upu/i18n/backend_message_mapper.dart';

/// Handles document listing, upload, and deletion API calls.
class DocumentService {
  static const String baseUrl = AuthService.baseUrl;
  final AuthService _auth = AuthService();

  /// Fetches documents. Pass [patientId] to filter by a specific patient.
  Future<List<Map<String, dynamic>>> getDocuments({int? patientId}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/documents').replace(
          queryParameters:
              patientId != null ? {'patient_id': patientId.toString()} : null);
      final response =
          await http.get(uri, headers: await ApiHeaders.bearer());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['documents']);
      }
    } catch (e) {
      print('getDocuments error: $e');
    }
    return [];
  }

  /// Uploads a PDF. Pass [patientId] when uploading on behalf of a patient.
  Future<Map<String, dynamic>> uploadDocument(
    Uint8List bytes,
    String name, {
    int? patientId,
  }) async {
    try {
      final token = await _auth.getToken();
      final uri = Uri.parse('${ApiConstants.baseUrl}/documents');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..fields['name'] = name
        ..files
            .add(http.MultipartFile.fromBytes('file', bytes, filename: name));

      if (patientId != null) {
        request.fields['patient_id'] = patientId.toString();
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'document': data['document']};
      }
      return {
        'success': false,
        'message': backendMessageKey(data['message'] ?? 'upload_error')
      };
    } catch (e) {
      return {'success': false, 'message': 'connection_error'};
    }
  }

  /// Deletes a document by [id].
  Future<bool> deleteDocument(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/documents/$id'),
        headers: await ApiHeaders.bearer(),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
