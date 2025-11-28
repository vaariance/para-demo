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
    _webAuthSession = FlutterWebAuthSession(callbackUrlScheme: 'parademo');
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

  Future<void> loginWithGoogle() async {
    await _performOAuthLogin(OAuthMethod.google, 'Google');
  }

  Future<void> loginWithApple() async {
    await _performOAuthLogin(OAuthMethod.apple, 'Apple');
  }

  Future<void> loginWithDiscord() async {
    await _performOAuthLogin(OAuthMethod.discord, 'Discord');
  }

  Future<void> loginWithSocial(SocialProvider provider) async {
    switch (provider) {
      case SocialProvider.google:
        await loginWithGoogle();
        break;
      case SocialProvider.apple:
        await loginWithApple();
        break;
      case SocialProvider.discord:
        await loginWithDiscord();
        break;
    }
  }

  Future<void> _performOAuthLogin(
    OAuthMethod provider,
    String providerName,
  ) async {
    _setState(AppAuthState.loading);

    try {
      debugPrint('Starting $providerName login...');

      // Step 1: Initiate OAuth flow
      final authState = await paraClient.para.verifyOAuth(
        provider: provider,
        appScheme: 'parademo',
      );

      // Step 2: Check if one-click auth is available
      if (await _handleOneClickAuth(authState)) {
        debugPrint('$providerName login successful via one-click');
        return;
      }

      // Step 3: Fallback to standard OAuth login finalization
      await _finalizeOAuthLogin(providerName);
    } catch (e) {
      _errorMessage = '$providerName login failed: $e';
      debugPrint('$providerName login error: $e');
      _setState(AppAuthState.error);
    }
  }

  Future<bool> _handleOneClickAuth(AuthState authState) async {
    final url = authState.loginUrl;
    if (url?.isNotEmpty != true) return false;

    try {
      // Present auth URL in browser
      await paraClient.para.presentAuthUrl(
        url: url!,
        webAuthenticationSession: _webAuthSession,
      );

      // Wait for signup or login based on stage
      final nextStage = authState.effectiveNextStage;
      if (nextStage == AuthStage.signup) {
        await paraClient.para.waitForSignup();
      } else {
        await paraClient.para.waitForLogin();
      }

      // Touch session and fetch wallets
      await paraClient.para.touchSession();
      await paraClient.para.fetchWallets();

      // Get current user and update state
      final user = await paraClient.para.currentUser();
      _currentUser = user;
      _setState(AppAuthState.authenticated);

      return true;
    } catch (e) {
      debugPrint('One-click auth error: $e');
      return false;
    }
  }

  Future<void> _finalizeOAuthLogin(String providerName) async {
    try {
      // Touch session (best-effort)
      await paraClient.para.touchSession();
    } catch (_) {}

    // Fetch wallets
    await paraClient.para.fetchWallets();

    // Get current user and update state
    final user = await paraClient.para.currentUser();
    _currentUser = user;
    _setState(AppAuthState.authenticated);
    debugPrint('$providerName login finalized successfully');
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
