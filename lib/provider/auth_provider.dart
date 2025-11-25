import 'package:flutter/foundation.dart';
import 'package:para/para.dart';
import 'package:para_demo/client/para_client.dart';

enum AppAuthState { initial, loading, authenticated, unauthenticated, error }

enum SocialProvider { google, apple, discord }

class AuthProvider with ChangeNotifier {
  AppAuthState _state = AppAuthState.initial;
  ParaUser? _currentUser;
  String? _errorMessage;
  late final FlutterWebAuthSession _webAuthSession;

  AppAuthState get state => _state;
  ParaUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AppAuthState.authenticated;
  bool get isLoading => _state == AppAuthState.loading;

  AuthProvider() {
    _webAuthSession = FlutterWebAuthSession(callbackUrlScheme: 'paraflutter');
  }

  Future<void> initialize() async {
    _setState(AppAuthState.loading);

    try {
      final user = await paraClient.para.currentUser();

      if (user.isLoggedIn) {
        _currentUser = user;
        _setState(AppAuthState.authenticated);
        debugPrint('User already authenticated: ${user.email}');
      } else {
        _setState(AppAuthState.unauthenticated);
        debugPrint('No existing session found');
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      _setState(AppAuthState.unauthenticated);
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('Logging out user...');
      await paraClient.para.logout();
      _currentUser = null;
      _setState(AppAuthState.unauthenticated);
      debugPrint('User logged out successfully');
    } catch (e) {
      debugPrint('Logout error: $e');

      _currentUser = null;
      _setState(AppAuthState.unauthenticated);
    }
  }

  Future<bool> deleteAccount() async {
    try {
      debugPrint('Deleting user account...');
      await paraClient.para.deleteAccount();
      _currentUser = null;
      _setState(AppAuthState.unauthenticated);
      debugPrint('Account deleted successfully');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Delete account error: $e');
      return false;
    }
  }

  void markAuthenticated(ParaUser user) {
    _currentUser = user;
    _setState(AppAuthState.authenticated);
  }

  Future<void> refreshUser() async {
    try {
      final user = await paraClient.para.currentUser();
      if (user.isLoggedIn) {
        _currentUser = user;
        notifyListeners();
      } else {
        await logout();
      }
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }

  void _setState(AppAuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void setError(String error) {
    _errorMessage = error;
    _setState(AppAuthState.error);
  }

  void clearError() {
    _errorMessage = null;
    if (_state == AppAuthState.error) {
      _setState(AppAuthState.unauthenticated);
    }
    notifyListeners();
  }
}
