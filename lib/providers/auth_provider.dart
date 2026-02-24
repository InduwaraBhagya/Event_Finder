import 'package:flutter/material.dart';
import 'package:event_finder/models/user_model.dart';
import 'package:event_finder/services/auth_service.dart';


class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  bool get isAuthenticated => _user != null; 
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isOrganizer => _user?.isOrganizer ?? false;
  bool get isUser => _user?.isUser ?? false;

  /// Initialize provider - check if user is already logged in
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.getCurrentUser();
    } catch (e) {
      _errorMessage = e.toString();
      print(' Init Error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);

      print(' Login Result: $result'); // Debug log

      if (result['success'] == true) {
        _user = result['user'];
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Login failed';
        _user = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _user = null;
      _isLoading = false;
      notifyListeners();
      print(' Login Provider Error: $_errorMessage');
      return false;
    }
  }

  /// Register
  Future<bool> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(name, email, password, role);

      print(' Register Result: $result'); 

      if (result['success'] == true) {
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      print('❌ Register Provider Error: $_errorMessage');
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      print(' Logout Error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Update user data
  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }
}