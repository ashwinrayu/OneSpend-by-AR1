import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _tokenKey = 'onespend_jwt_token';
  static const _userKey = 'onespend_user_profile';
  static const _guestKey = 'onespend_is_guest';

  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          wOptions: WindowsOptions(
            useBackwardCompatibility: false,
          ),
        );

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _guestKey, value: 'false');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final str = await _storage.read(key: _userKey);
    if (str != null) {
      try {
        return jsonDecode(str) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  Future<void> setGuestMode(bool isGuest) async {
    await _storage.write(key: _guestKey, value: isGuest ? 'true' : 'false');
  }

  Future<bool> isGuestMode() async {
    final val = await _storage.read(key: _guestKey);
    return val == 'true';
  }

  Future<void> clearAuth() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _guestKey);
  }
}

