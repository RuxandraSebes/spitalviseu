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
}
