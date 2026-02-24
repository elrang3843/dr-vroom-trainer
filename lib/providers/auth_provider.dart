/// Auth Provider for Trainer App
/// Manages authentication state and server connection
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  String _serverUrl = AppConstants.defaultServerUrl;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  String? _token;
  String? _userId;
  String? _username;
  String _role = 'trainer';

  String get serverUrl => _serverUrl;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  String? get userId => _userId;
  String? get username => _username;
  String get role => _role;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString(AppConstants.serverUrlKey) ?? AppConstants.defaultServerUrl;
    _token = prefs.getString('auth_token');
    _userId = prefs.getString('user_id');
    _username = prefs.getString('username');
    _role = prefs.getString('user_role') ?? 'trainer';
    _isLoggedIn = _token != null;
    notifyListeners();
  }

  Future<void> updateServerUrl(String url) async {
    _serverUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.serverUrlKey, _serverUrl);
    notifyListeners();
  }

  Future<bool> checkServerConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_serverUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveSession(data);
        _isLoggedIn = true;
        return {'success': true};
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['detail'] ?? '로그인 실패';
        return {'success': false, 'error': _errorMessage};
      }
    } catch (e) {
      _errorMessage = '서버 연결 오류: $e';
      return {'success': false, 'error': _errorMessage};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> register(
      String username, String email, String password, String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/api/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveSession(data);
        _isLoggedIn = true;
        return {'success': true};
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['detail'] ?? '등록 실패';
        return {'success': false, 'error': _errorMessage};
      }
    } catch (e) {
      _errorMessage = '서버 연결 오류: $e';
      return {'success': false, 'error': _errorMessage};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    _token = data['access_token'];
    _role = data['role'];
    _userId = data['user_id'];
    _username = data['username'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    await prefs.setString('user_role', _role);
    await prefs.setString('user_id', _userId!);
    await prefs.setString('username', _username!);
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _username = null;
    _role = 'trainer';
    _isLoggedIn = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    await prefs.remove('username');
    notifyListeners();
  }

  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
}
