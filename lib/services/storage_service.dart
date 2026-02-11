import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:event_finder/config/app_config.dart';
import 'package:event_finder/models/user_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token Management
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConfig.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: AppConfig.tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: AppConfig.tokenKey);
  }

  // User Management
  Future<void> saveUser(User user) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(AppConfig.userKey, jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    _prefs ??= await SharedPreferences.getInstance();
    final userString = _prefs!.getString(AppConfig.userKey);
    if (userString != null) {
      return User.fromJson(jsonDecode(userString));
    }
    return null;
  }

  Future<void> deleteUser() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(AppConfig.userKey);
  }

  // User Role
  Future<void> saveUserRole(String role) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(AppConfig.userRoleKey, role);
  }

  Future<String?> getUserRole() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getString(AppConfig.userRoleKey);
  }

  // Clear All Data
  Future<void> clearAll() async {
    await deleteToken();
    await deleteUser();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.clear();
  }

  // Generic String Storage
  Future<void> saveString(String key, String value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(key, value);
  }

  Future<String?> getString(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getString(key);
  }

  // Generic Bool Storage
  Future<void> saveBool(String key, bool value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getBool(key);
  }
}