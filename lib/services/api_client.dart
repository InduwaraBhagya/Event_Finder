import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:event_finder/config/app_config.dart';
import 'package:event_finder/services/storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final StorageService _storage = StorageService();

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ✅ GET request - requiresAuth param works correctly
  Future<dynamic> get(
    String endpoint, {
    bool requiresAuth = true, // ✅ Default true but can be set to false
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      // Build URL
      String urlString = '${AppConfig.baseUrl}$endpoint';

      // Add query params if provided separately
      if (queryParams != null && queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        urlString += urlString.contains('?') ? '&$queryString' : '?$queryString';
      }

      final url = Uri.parse(urlString);
      print('🌐 API GET: $url');
      print('🔐 Auth: $requiresAuth | Headers: ${headers.keys.toList()}');

      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      return _handleResponse(response);
    } catch (e) {
      print('❌ GET Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ✅ POST request
  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');

      print('🌐 API POST: $url');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      print('📥 POST Status: ${response.statusCode}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ POST Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ✅ PUT request
  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ✅ DELETE request
  Future<dynamic> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');

      final response = await http.delete(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ✅ Handle response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else {
      print('❌ Response Error: ${response.statusCode} - ${response.body}');
      Map<String, dynamic> errorBody = {};
      try {
        errorBody = jsonDecode(response.body);
      } catch (_) {
        errorBody = {'message': 'Server error: ${response.statusCode}'};
      }
      throw Exception(errorBody['message'] ?? 'Request failed with status ${response.statusCode}');
    }
  }
}