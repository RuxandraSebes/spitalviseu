/// Central API configuration used by all HTTP services.
///
/// Builds target the production API by default. For local development pass
/// another server at build time, e.g.
/// `flutter run --dart-define=API_BASE_URL=http://192.168.0.237:8000/api`.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.spitalviseu.ro/api',
  );

  /// Server root without the trailing `/api`, for resolving relative file URLs.
  static String get serverUrl => serverUrlFor(baseUrl);

  static String serverUrlFor(String apiBaseUrl) =>
      apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
}
