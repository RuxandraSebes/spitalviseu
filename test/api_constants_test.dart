import 'package:flutter_test/flutter_test.dart';
import 'package:spital_visu_upu/core/constants/api_constants.dart';

void main() {
  test('production API is the default base URL', () {
    expect(ApiConstants.baseUrl, 'https://api.spitalviseu.ro/api');
  });

  test('server URL strips only the trailing /api', () {
    expect(ApiConstants.serverUrlFor('https://api.spitalviseu.ro/api'),
        'https://api.spitalviseu.ro');
    expect(ApiConstants.serverUrlFor('http://192.168.0.237:8000/api/'),
        'http://192.168.0.237:8000');
  });

  test('only our API server is trusted with the token', () {
    final api = Uri.parse('https://api.spitalviseu.ro/api');
    expect(
        ApiConstants.isSameServer(
            Uri.parse('https://api.spitalviseu.ro/api/documents/3/file'), api),
        isTrue);
    expect(
        ApiConstants.isSameServer(
            Uri.parse('https://api.spitalviseu.ro.evil.com/x.pdf'), api),
        isFalse);
    expect(
        ApiConstants.isSameServer(
            Uri.parse('http://api.spitalviseu.ro/api/documents/3/file'), api),
        isFalse);
  });
}
