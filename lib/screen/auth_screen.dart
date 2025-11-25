import 'package:flutter/material.dart';
import 'package:para_demo/client/para_client.dart';
import 'package:para_demo/provider/auth_provider.dart';
import 'package:para_demo/shared/buttons.dart';
import 'package:provider/provider.dart';
import 'package:para/para.dart';

enum _AuthFlow { oauth }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();

  SocialProvider? _loadingProvider;
  final bool _isProcessing = false;
  late final FlutterWebAuthSession _webAuthSession;

  @override
  void initState() {
    super.initState();
    _webAuthSession = FlutterWebAuthSession(callbackUrlScheme: 'paraflutter');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSocialAuth(SocialProvider provider) async {
    setState(() => _loadingProvider = provider);

    try {
      final oauthMethod = switch (provider) {
        SocialProvider.google => OAuthMethod.google,
        SocialProvider.apple => OAuthMethod.apple,
        SocialProvider.discord => OAuthMethod.discord,
      };

      final authState = await paraClient.para.verifyOAuth(
        provider: oauthMethod,
        appScheme: 'paraflutter',
      );

      await _continueAuth(authState, flow: _AuthFlow.oauth);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingProvider = null);
      }
    }
  }

  Future<void> _continueAuth(
    AuthState authState, {
    required _AuthFlow flow,
  }) async {
    if (await _handleOneClick(authState)) {
      return;
    }

    if (authState.stage == AuthStage.login) {
      if (flow == _AuthFlow.oauth) {
        await _finalizeOAuthLogin();
      } else {
        await _completeLogin(authState);
      }
    }
  }

  Future<void> _completeLogin(AuthState authState) async {
    try {
      await paraClient.para.handleLogin(
        authState: authState,
        webAuthenticationSession: _webAuthSession,
      );

      if (mounted) {
        final user = await paraClient.para.currentUser();
        context.read<AuthProvider>().markAuthenticated(user);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _finalizeOAuthLogin() async {
    try {
      await paraClient.para.touchSession();
    } catch (_) {}

    await paraClient.para.fetchWallets();

    if (mounted) {
      final user = await paraClient.para.currentUser();
      context.read<AuthProvider>().markAuthenticated(user);
    }
  }

  Future<bool> _handleOneClick(AuthState authState) async {
    final url = authState.loginUrl;
    if (url?.isNotEmpty != true) return false;

    try {
      await paraClient.para.presentAuthUrl(
        url: url!,
        webAuthenticationSession: _webAuthSession,
      );

      final nextStage = authState.effectiveNextStage;
      if (nextStage == AuthStage.signup) {
        await paraClient.para.waitForSignup();
      } else {
        await paraClient.para.waitForLogin();
      }

      await paraClient.para.touchSession();
      await paraClient.para.fetchWallets();

      if (mounted) {
        final user = await paraClient.para.currentUser();
        context.read<AuthProvider>().markAuthenticated(user);
      }

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed: ${e.toString()}')),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isProcessing || _loadingProvider != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F7),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Text(
                'Sign Up or Log In',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 32),
              SocialAuthButton(
                provider: SocialProvider.google,
                isLoading: _loadingProvider == SocialProvider.google,
                onPressed: () => _handleSocialAuth(SocialProvider.google),
              ),
              SocialAuthButton(
                provider: SocialProvider.apple,
                isLoading: _loadingProvider == SocialProvider.apple,
                onPressed: () => _handleSocialAuth(SocialProvider.apple),
              ),
              const SizedBox(height: 48),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'By logging in you agree to our Terms & Conditions',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Powered by',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Para',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
