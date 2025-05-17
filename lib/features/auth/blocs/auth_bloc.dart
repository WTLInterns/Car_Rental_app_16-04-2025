import 'dart:async';
import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';
import 'auth_state.dart';

class AuthBloc extends ChangeNotifier {
  final AuthRepository _authRepository;
  AuthState _state = AuthState.initial();

  AuthBloc({AuthRepository? authRepository}) 
      : _authRepository = authRepository ?? AuthRepository() {
    checkAuthentication();
  }

  // Getters
  AuthState get state => _state;
  bool get isAuthenticated => _state.status == AuthStatus.authenticated;
  User? get currentUser => _state.user;
  bool get isLoading => _state.status == AuthStatus.loading;

  // Update state and notify listeners
  void _updateState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  // Check if user is authenticated
  Future<void> checkAuthentication() async {
    _updateState(AuthState.loading());
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          _updateState(AuthState.authenticated(user));
        } else {
          _updateState(AuthState.unauthenticated());
        }
      } else {
        _updateState(AuthState.unauthenticated());
      }
    } catch (e) {
      _updateState(AuthState.error(e.toString()));
    }
  }

  // Login user
  Future<void> login(String mobile, String password, bool rememberMe) async {
    _updateState(AuthState.loading());
    try {
      final user = await _authRepository.login(mobile, password);
      await _authRepository.saveRememberMe(rememberMe, mobile);
      _updateState(AuthState.authenticated(user));
    } catch (e) {
      _updateState(AuthState.error(e.toString()));
    }
  }

  // Logout user
  Future<void> logout() async {
    _updateState(AuthState.loading());
    try {
      await _authRepository.logout();
      _updateState(AuthState.unauthenticated());
    } catch (e) {
      _updateState(AuthState.error(e.toString()));
    }
  }

  // Get remember me settings
  bool getRememberMe() {
    return _authRepository.getRememberMe();
  }

  // Get saved mobile number
  String getSavedMobile() {
    return _authRepository.getSavedMobile();
  }
} 