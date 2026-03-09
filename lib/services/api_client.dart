import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:event_finder/config/app_config.dart';
import 'package:event_finder/services/storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final StorageService _storage = StorageService();

  // ── Build headers ─────────────────────────────────────
  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept':       'application/json',
    };

    if (requiresAuth) {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print(' Token attached: Bearer ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      } else {
        print(' No token found — request will be unauthenticated');
      }
    }

    return headers;
  }

  // ── GET ───────────────────────────────────────────────
  Future<dynamic> get(
    String endpoint, {
    bool requiresAuth = true,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      String urlString = '${AppConfig.baseUrl}$endpoint';
      if (queryParams != null && queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        urlString += urlString.contains('?') ? '&$queryString' : '?$queryString';
      }

      final url = Uri.parse(urlString);
      print(' GET → $url');

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      print('📥 GET ${response.statusCode} ← $url');
      return _handleResponse(response);
    } catch (e) {
      print(' GET Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ── POST ──────────────────────────────────────────────
  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final url     = Uri.parse('${AppConfig.baseUrl}$endpoint');

      print(' POST → $url');
      print(' Body → ${jsonEncode(body)}');

      final response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      print(' POST ${response.statusCode} ← $url');
      print(' Response body → ${response.body}');
      return _handleResponse(response);
    } catch (e) {
      print(' POST Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ── PUT ───────────────────────────────────────────────
  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final url     = Uri.parse('${AppConfig.baseUrl}$endpoint');

      print(' PUT → $url');

      final response = await http
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      print(' PUT ${response.statusCode} ← $url');
      return _handleResponse(response);
    } catch (e) {
      print(' PUT Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ── PATCH ─────────────────────────────────────────────
  Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final url     = Uri.parse('${AppConfig.baseUrl}$endpoint');

      print(' PATCH → $url');

      final response = await http
          .patch(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      print(' PATCH ${response.statusCode} ← $url');
      return _handleResponse(response);
    } catch (e) {
      print(' PATCH Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ── DELETE ────────────────────────────────────────────
  Future<dynamic> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final url     = Uri.parse('${AppConfig.baseUrl}$endpoint');

      print(' DELETE → $url');

      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      print(' DELETE ${response.statusCode} ← $url');
      // some backends return 404 if the resource was already removed; from
      // the client's point of view the booking is gone so treat it as success
      if (response.statusCode == 404) {
        print(' DELETE 404 received – treating as success');
        return {'success': true};
      }
      return _handleResponse(response);
    } catch (e) {
      print(' DELETE Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ── MULTIPART POST ────────────────────────────────────
  // ✅ NEW: Sends form fields + optional image file as multipart/form-data
  // Used by CreateEventScreen to upload event image to Cloudinary via backend
  //
  // Usage example:
  //   final result = await _apiClient.postMultipart(
  //     AppConfig.organizerEventsEndpoint,
  //     fields: {
  //       'title': 'My Event',
  //       'category': 'Music',
  //       'date': DateTime.now().toIso8601String(),
  //       // ... all other text fields as strings
  //     },
  //     imageFile: _imageFile,   // File? picked from gallery/camera
  //   );
  Future<dynamic> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    File? imageFile,                      
    String fileFieldName = 'image',       
    bool requiresAuth = true,
  }) async {
    try {
      final token = requiresAuth ? await _storage.getToken() : null;
      final url   = Uri.parse('${AppConfig.baseUrl}$endpoint');

      final request = http.MultipartRequest('POST', url);

      // Auth header
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
        print('Token attached to multipart request');
      }

      // Text form fields (all values must be String)
      request.fields.addAll(fields);
      print(' Multipart fields: $fields');

      // Image file (optional)
      if (imageFile != null) {
        final ext      = imageFile.path.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
        request.files.add(await http.MultipartFile.fromPath(
          fileFieldName,
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ));
        print('📎 Image attached: ${imageFile.path} ($mimeType)');
      }

      print(' MULTIPART POST → $url');
      final streamed = await request.send()
          .timeout(const Duration(seconds: 60)); // 60s for image uploads
      final response = await http.Response.fromStream(streamed);
      print(' MULTIPART ${response.statusCode} ← $url');
      print(' Response body → ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print(' MULTIPART Error: $e');
      throw Exception('Upload error: $e');
    }
  }

  // ── Handle response ───────────────────────────────────
  dynamic _handleResponse(http.Response response) {
    print(' Status: ${response.statusCode}');
    print(' Body:   ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    }

    Map<String, dynamic> errorBody = {};
    try {
      errorBody = jsonDecode(response.body);
    } catch (_) {
      errorBody = {'message': 'Server error: ${response.statusCode}'};
    }

    final message = errorBody['message'] ??
        errorBody['error'] ??
        'Request failed with status ${response.statusCode}';

    print(' API Error ${response.statusCode}: $message');
    throw Exception('Server error: $message');
  }
}