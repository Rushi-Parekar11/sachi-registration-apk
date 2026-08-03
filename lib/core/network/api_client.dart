import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  static Map<String, String> get _defaultHeaders {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (dotenv.env['MOCK_GATEWAY_AUTH'] == 'true') {
      headers['x-gateway-authenticated'] = 'true';
      headers['x-user-id'] = dotenv.env['MOCK_USER_ID'] ?? 'admin';
      headers['x-tenant-id'] = dotenv.env['DEV_TENANT_ID'] ?? '';
      headers['x-permissions'] = 'sachi:dashboard:read,sachi:patient:read';
    }

    return headers;
  }

  static Future<http.Response> get(String url) async {
    return http.get(Uri.parse(url), headers: _defaultHeaders);
  }

  static Future<http.Response> post(String url, {Object? body}) async {
    return http.post(Uri.parse(url), headers: _defaultHeaders, body: body);
  }

  static Future<http.Response> put(String url, {Object? body}) async {
    return http.put(Uri.parse(url), headers: _defaultHeaders, body: body);
  }

  static Future<http.Response> delete(String url) async {
    return http.delete(Uri.parse(url), headers: _defaultHeaders);
  }
}
