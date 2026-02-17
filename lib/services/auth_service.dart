import 'package:event_finder/config/app_config.dart';
import 'package:event_finder/models/user_model.dart';
import 'package:event_finder/services/api_client.dart';
import 'package:event_finder/services/storage_service.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final StorageService _storage = StorageService();

  /// Login - Matches backend response structure
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        AppConfig.loginEndpoint,
        {
          'email': email,
          'password': password,
        },
        requiresAuth: false,
      );

      print('📥 Backend Response: $response'); // Debug log

      // ✅ Backend returns: { message, status, data: { id, name, email, role, token } }
      if (response['status'] == 200 && response['data'] != null) {
        final userData = response['data'];
        
        // Save token first
        if (userData['token'] != null) {
          await _storage.saveToken(userData['token']);
        }

        // Create user object
        final user = User.fromJson(userData);
        await _storage.saveUser(user);
        await _storage.saveUserRole(user.role);

        return {
          'success': true,
          'message': response['message'],
          'user': user,
        };
      } else {
        // Handle error response
        return {
          'success': false,
          'message': response['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('❌ Login Error: $e'); // Debug log
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  /// Register - Matches backend response structure
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    try {
      final response = await _apiClient.post(
        AppConfig.registerEndpoint,
        {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
        requiresAuth: false,
      );

      print('📥 Register Response: $response'); // Debug log

      // ✅ Backend returns: { message, status, data: { id, name, email, role, token } }
      if (response['status'] == 201 && response['data'] != null) {
        final userData = response['data'];
        
        // Save token
        if (userData['token'] != null) {
          await _storage.saveToken(userData['token']);
        }

        // Create user object
        final user = User.fromJson(userData);
        await _storage.saveUser(user);
        await _storage.saveUserRole(user.role);

        return {
          'success': true,
          'message': response['message'],
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      print('❌ Register Error: $e'); // Debug log
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _storage.clearAll();
    } catch (e) {
      print('❌ Logout Error: $e');
      await _storage.clearAll();
    }
  }

  /// Get current user from storage
  Future<User?> getCurrentUser() async {
    return await _storage.getUser();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Get user role
  Future<String?> getUserRole() async {
    return await _storage.getUserRole();
  }
}