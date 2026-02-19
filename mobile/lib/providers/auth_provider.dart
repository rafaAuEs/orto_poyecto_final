import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  bool _isAuthenticated = false;
  String? _role;

  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _role == 'admin';

  Future<void> checkAuth() async {
    final token = await _api.getToken();
    if (token != null) {
      try {
        final profile = await _api.getProfile();
        _role = profile['role'];
        _isAuthenticated = true;
      } catch (e) {
        // Token inválido o expirado
        _isAuthenticated = false;
        _role = null;
        await _api.logout();
      }
    } else {
      _isAuthenticated = false;
      _role = null;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _api.login(email, password);
    // Fetch profile to get role
    final profile = await _api.getProfile();
    _role = profile['role'];
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> register(String email, String name, String password) async {
    await _api.register(email, name, password);
    await login(email, password); // Auto login
  }

  Future<void> logout() async {
    await _api.logout();
    _isAuthenticated = false;
    _role = null;
    notifyListeners();
  }
}
