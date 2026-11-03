import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'https://onespend-by-ar1.onrender.com';
  final http.Client _client;

  ApiClient([http.Client? client]) : _client = client ?? http.Client();

  Map<String, String> _headers([String? token]) {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
    return map;
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');
    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw HttpException(data['error'] as String? ?? 'Registration failed.');
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw HttpException(data['error'] as String? ?? 'Login failed. Please check credentials.');
    }
  }

  // Get Me
  Future<Map<String, dynamic>> getMe(String token) async {
    final uri = Uri.parse('$baseUrl/api/auth/me');
    final response = await _client.get(
      uri,
      headers: _headers(token),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return data;
    } else {
      throw HttpException(data['error'] as String? ?? 'Failed to load profile.');
    }
  }

  // Batch Delta Sync
  Future<Map<String, dynamic>> syncTransactions({
    required String token,
    required List<Map<String, dynamic>> clientChanges,
    String? lastSyncedAt,
  }) async {
    final uri = Uri.parse('$baseUrl/api/transactions/sync');
    final response = await _client.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({
        'lastSyncedAt': lastSyncedAt,
        'clientChanges': clientChanges,
      }),
    ).timeout(const Duration(seconds: 25));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return data;
    } else {
      throw HttpException(data['error'] as String? ?? 'Sync failed.');
    }
  }
}

