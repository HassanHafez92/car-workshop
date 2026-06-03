import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import 'app_state_provider.dart';
import 'role_provider.dart';

class AuthState {
  final UserAccount? currentUser;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserAccount? currentUser,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  static const String _sessionKey = 'car_workshop_auth_session';

  @override
  AuthState build() {
    _restoreSession();
    return const AuthState(isLoading: true);
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_sessionKey);
      if (userJson != null) {
        final user = UserAccount.fromJson(userJson);
        state = AuthState(currentUser: user);
        ref.read(roleProvider.notifier).setRole(user.role);
      } else {
        state = const AuthState();
      }
    } catch (e) {
      state = const AuthState();
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    // Simulate brief network delay for realism and micro-animations
    await Future.delayed(const Duration(milliseconds: 500));

    final apiService = ApiService();
    try {
      // 1. Try to authenticate via REST API
      final user = await apiService.login(username.trim(), password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, user.toJson());

      // Update role provider
      ref.read(roleProvider.notifier).setRole(user.role);

      state = AuthState(currentUser: user);
      
      // Sync AppState in the background
      ref.read(appStateProvider.notifier).loadAsync();

      return true;
    } catch (e) {
      final errorStr = e.toString().replaceAll('Exception: ', '');
      // If server explicitly rejected due to invalid credentials or disabled account, fail early
      if (errorStr.contains('معطل') || errorStr.contains('كلمة المرور غير صحيحة')) {
        state = state.copyWith(isLoading: false, errorMessage: errorStr);
        return false;
      }
      print(">>> REST API login failed (falling back to offline local auth): $e");
    }

    // 2. Offline Fallback: Load users from DatabaseService SharedPreferences storage
    try {
      final dbService = DatabaseService();
      final persisted = await dbService.loadState();
      List<UserAccount> usersList = [];
      
      if (persisted != null && persisted['users'] != null) {
        usersList = List<UserAccount>.from(
          (persisted['users'] as List).map((x) => UserAccount.fromMap(x))
        );
      } else {
        final mock = dbService.getMockInitialData();
        usersList = List<UserAccount>.from(
          (mock['users'] as List).map((x) => UserAccount.fromMap(x))
        );
      }

      final user = usersList.firstWhere(
        (u) => u.username.toLowerCase() == username.toLowerCase().trim() && u.password == password,
      );

      if (!user.isActive) {
        state = state.copyWith(isLoading: false, errorMessage: 'هذا الحساب معطل حالياً من قبل الإدارة.');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, user.toJson());

      // Update role provider
      ref.read(roleProvider.notifier).setRole(user.role);

      state = AuthState(currentUser: user);
      return true;
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'اسم المستخدم أو كلمة المرور غير صحيحة.');
      return false;
    }
  }

  Future<void> logout() async {
    state = const AuthState(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    ref.read(roleProvider.notifier).setRole(UserRole.admin);
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
