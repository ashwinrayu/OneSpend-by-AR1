import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String primaryUrl = 'https://onespend.vercel.app';
  static const String fallbackUrl = 'https://onespend-by-ar1.onrender.com';
  static const Duration requestTimeout = Duration(seconds: 60);

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

  Future<http.Response> _postWithFallback(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final res = await _client.post(
        Uri.parse('$primaryUrl$path'),
        headers: headers,
        body: body,
      ).timeout(requestTimeout);

      if (res.statusCode < 500) {
        return res;
      }
    } catch (_) {
      // Primary attempt failed or timed out, attempt fallback URL
    }

    return await _client.post(
      Uri.parse('$fallbackUrl$path'),
      headers: headers,
      body: body,
    ).timeout(requestTimeout);
  }

  Future<http.Response> _getWithFallback(
    String path, {
    Map<String, String>? headers,
  }) async {
    try {
      final res = await _client.get(
        Uri.parse('$primaryUrl$path'),
        headers: headers,
      ).timeout(requestTimeout);

      if (res.statusCode < 500) {
        return res;
      }
    } catch (_) {
      // Primary attempt failed or timed out, attempt fallback URL
    }

    return await _client.get(
      Uri.parse('$fallbackUrl$path'),
      headers: headers,
    ).timeout(requestTimeout);
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _postWithFallback(
      '/api/auth/register',
      headers: _headers(),
      body: jsonEncode({
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

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
    final response = await _postWithFallback(
      '/api/auth/login',
      headers: _headers(),
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw HttpException(data['error'] as String? ?? 'Login failed. Please check credentials.');
    }
  }

  // Get Me
  Future<Map<String, dynamic>> getMe(String token) async {
    final response = await _getWithFallback(
      '/api/auth/me',
      headers: _headers(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return data;
    } else {
      throw HttpException(data['error'] as String? ?? 'Failed to load profile.');
    }
  }

  // Batch Delta Sync for Transactions
  Future<Map<String, dynamic>> syncTransactions({
    required String token,
    required List<Map<String, dynamic>> clientChanges,
    String? lastSyncedAt,
  }) async {
    final response = await _postWithFallback(
      '/api/transactions/sync',
      headers: _headers(token),
      body: jsonEncode({
        'lastSyncedAt': lastSyncedAt,
        'clientChanges': clientChanges,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return data;
    } else {
      throw HttpException(data['error'] as String? ?? 'Sync failed.');
    }
  }

  // Batch Delta Sync for Loans
  Future<Map<String, dynamic>> syncLoans({
    required String token,
    required List<Map<String, dynamic>> clientChanges,
    String? lastSyncedAt,
  }) async {
    final response = await _postWithFallback(
      '/api/loans/sync',
      headers: _headers(token),
      body: jsonEncode({
        'lastSyncedAt': lastSyncedAt,
        'clientChanges': clientChanges,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return data;
    } else {
      throw HttpException(data['error'] as String? ?? 'Loan sync failed.');
    }
  }

  // Batch Delta Sync for Subscriptions
  Future<Map<String, dynamic>> syncSubscriptions({
    required String token,
    required List<Map<String, dynamic>> clientChanges,
    String? lastSyncedAt,
  }) async {
    final response = await _postWithFallback(
      '/api/subscriptions/sync',
      headers: _headers(token),
      body: jsonEncode({
        'lastSyncedAt': lastSyncedAt,
        'clientChanges': clientChanges,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return data;
    } else {
      throw HttpException(data['error'] as String? ?? 'Subscription sync failed.');
    }
  }
}
