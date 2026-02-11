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
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String endpoint, {bool requiresAuth = true}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      
      final response = await http.get(url, headers: headers);
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

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
      );
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> delete(String endpoint, {bool requiresAuth = true}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      
      final response = await http.delete(url, headers: headers);
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      final errorBody = response.body.isNotEmpty 
          ? jsonDecode(response.body)
          : {'message': 'Unknown error occurred'};
      
      throw Exception(errorBody['message'] ?? 'Request failed');
    }
  }
}