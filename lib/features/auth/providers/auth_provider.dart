import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/secure_storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class AuthState {
  final bool isAuthenticated;
  final bool isGuest;
  final String? token;
  final Map<String, dynamic>? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isGuest = false,
    this.token,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get canAccessApp => isAuthenticated || isGuest;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isGuest,
    String? token,
    Map<String, dynamic>? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isGuest: isGuest ?? this.isGuest,
      token: token ?? this.token,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final Ref ref;

  AuthController(this.ref) : super(const AuthState(isLoading: true)) {
    checkInitialAuth();
  }

  SecureStorageService get _storage => ref.read(secureStorageProvider);
  ApiClient get _api => ref.read(apiClientProvider);

  Future<void> checkInitialAuth() async {
    try {
      final token = await _storage.getToken();
      final isGuest = await _storage.isGuestMode();

      if (token != null && token.isNotEmpty) {
        final cachedUser = await _storage.getUser();
        state = AuthState(
          isAuthenticated: true,
          isGuest: false,
          token: token,
          user: cachedUser,
          isLoading: false,
        );

        // Fetch fresh profile in background
        try {
          final profileData = await _api.getMe(token);
          final user = profileData['user'] as Map<String, dynamic>?;
          if (user != null) {
            await _storage.saveUser(user);
            state = state.copyWith(user: user);
          }
        } catch (_) {}
      } else if (isGuest) {
        state = const AuthState(
          isAuthenticated: false,
          isGuest: true,
          isLoading: false,
        );
      } else {
        state = const AuthState(isLoading: false);
      }
    } catch (e) {
      state = const AuthState(isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _api.login(email: email, password: password);
      final token = res['token'] as String;
      final user = res['user'] as Map<String, dynamic>;

      await _storage.saveToken(token);
      await _storage.saveUser(user);

      state = AuthState(
        isAuthenticated: true,
        isGuest: false,
        token: token,
        user: user,
        isLoading: false,
      );
      return true;
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Server took too long to respond. It may be waking up from sleep, or you can Continue Offline.',
      );
      return false;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '').replaceAll('HttpException: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _api.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      final token = res['token'] as String;
      final user = res['user'] as Map<String, dynamic>;

      await _storage.saveToken(token);
      await _storage.saveUser(user);

      state = AuthState(
        isAuthenticated: true,
        isGuest: false,
        token: token,
        user: user,
        isLoading: false,
      );
      return true;
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Server took too long to respond. It may be waking up from sleep, or you can Continue Offline.',
      );
      return false;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '').replaceAll('HttpException: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<void> continueOffline() async {
    await _storage.setGuestMode(true);
    state = const AuthState(
      isAuthenticated: false,
      isGuest: true,
      isLoading: false,
    );
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _storage.clearAuth();
    state = const AuthState(isLoading: false);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

