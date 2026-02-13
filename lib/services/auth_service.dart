import 'package:event_finder/config/app_config.dart';
import 'package:event_finder/models/user_model.dart';
import 'package:event_finder/services/api_client.dart';
import 'package:event_finder/services/storage_service.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final StorageService _storage = StorageService();

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

      if (response['token'] != null && response['user'] != null) {
        await _storage.saveToken(response['token']);
        final user = User.fromJson(response['user']);
        await _storage.saveUser(user);
        await _storage.saveUserRole(user.role);

        return {
          'success': true,
          'user': user,
          'token': response['token'],
        };
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

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

      if (response['token'] != null && response['user'] != null) {
        await _storage.saveToken(response['token']);
        final user = User.fromJson(response['user']);
        await _storage.saveUser(user);
        await _storage.saveUserRole(user.role);

        return {
          'success': true,
          'user': user,
          'token': response['token'],
        };
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<User?> getCurrentUser() async {
    // Check if token exists first
    final token = await _storage.getToken();
    if (token == null) {
      return null;
    }
    // Only return user if valid token exists
    return await _storage.getUser();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null;
  }

  Future<String?> getUserRole() async {
    return await _storage.getUserRole();
  }
}