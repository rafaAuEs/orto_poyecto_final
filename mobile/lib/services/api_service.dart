import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config.dart';

class ApiService {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> _saveToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
    } else {
      await _secureStorage.write(key: 'token', value: token);
    }
  }

  Future<String?> getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } else {
      return await _secureStorage.read(key: 'token');
    }
  }

  Future<void> logout() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    } else {
      await _secureStorage.delete(key: 'token');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Auth ---

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveToken(data['access_token']);
      return data;
    } else {
      throw Exception('Login fallido: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/auth/me'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar perfil');
    }
  }

  Future<void> register(String email, String name, String password) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'full_name': name,
        'password': password,
        'role': 'client'
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Registro fallido: ${response.body}');
    }
  }

  // --- Activities ---

  Future<List<dynamic>> getActivities() async {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/activities'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar actividades');
    }
  }

  // --- Reservations ---

  Future<List<dynamic>> getMyReservations() async {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/reservations/me'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar mis reservas');
    }
  }

  Future<void> createReservation(String activityId) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/reservations/'),
      headers: await _getHeaders(),
      body: jsonEncode({'activity_id': activityId}),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body)['detail'] ?? 'Error desconocido';
      throw Exception(error);
    }
  }

  Future<Map<String, dynamic>> cancelReservation(String reservationId) async {
    final response = await http.put(
      Uri.parse('${Config.baseUrl}/reservations/$reservationId/cancel'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cancelar');
    }
  }

  // --- Admin ---

  Future<List<dynamic>> getActivityReservations(String activityId) async {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/reservations/activity/$activityId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar asistencia');
    }
  }

  Future<void> updateAttendance(String reservationId, String status) async {
    final response = await http.put(
      Uri.parse('${Config.baseUrl}/reservations/$reservationId/attendance'),
      headers: await _getHeaders(),
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar asistencia');
    }
  }

  // Activity Management
  Future<void> createActivity(Map<String, dynamic> activityData) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/activities/'),
      headers: await _getHeaders(),
      body: jsonEncode(activityData),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al crear actividad: ${response.body}');
    }
  }

  Future<void> updateActivity(String id, Map<String, dynamic> activityData) async {
    final response = await http.put(
      Uri.parse('${Config.baseUrl}/activities/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(activityData),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar actividad: ${response.body}');
    }
  }

  Future<void> deleteActivity(String id) async {
    final response = await http.delete(
      Uri.parse('${Config.baseUrl}/activities/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception('Error al eliminar actividad');
    }
  }

  // User Management
  Future<List<dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/auth/users'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar usuarios');
    }
  }

  Future<void> deleteUser(String id) async {
    final response = await http.delete(
      Uri.parse('${Config.baseUrl}/auth/users/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception('Error al eliminar usuario');
    }
  }
}
