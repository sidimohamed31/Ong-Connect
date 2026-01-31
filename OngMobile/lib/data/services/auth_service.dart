import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/case_model.dart'; // Assuming Ong model is here or create a separate one

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _ongDataKey = 'ong_data';
  static const String _userRoleKey = 'user_role';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _token;
  Ong? _currentOng;
  String? _userRole; // 'admin' or 'ong'

  String? get token => _token;
  Ong? get currentOng => _currentOng;
  bool get isLoggedIn => _token != null;
  bool get isAdmin => _userRole == 'admin';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _userRole = prefs.getString(_userRoleKey);
    final ongData = prefs.getString(_ongDataKey);
    if (ongData != null) {
      try {
        _currentOng = Ong.fromJson(jsonDecode(ongData));
      } catch (e) {
        print('Error parsing stored ONG data: $e');
        await logout();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _token = data['token'];
          _userRole =
              data['role'] ?? 'ong'; // Default to 'ong' if not specified

          // Only parse ONG data if role is 'ong'
          if (_userRole == 'ong' && data['ong'] != null) {
            final ongData = data['ong'];
            _currentOng = Ong.fromJson(ongData);

            // Persist ONG data
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_ongDataKey, jsonEncode(ongData));
          }

          // Persist token and role
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, _token!);
          await prefs.setString(_userRoleKey, _userRole!);

          return true;
        }
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentOng = null;
    _userRole = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_ongDataKey);
    await prefs.remove(_userRoleKey);
  }
}
