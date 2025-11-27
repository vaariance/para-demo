import 'package:flutter/material.dart';
import 'package:para_demo/provider/auth_provider.dart';
import 'package:para_demo/shared/buttons.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  SocialProvider? _loadingProvider;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleSocialAuth(SocialProvider provider) async {
    setState(() => _loadingProvider = provider);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.loginWithSocial(provider);

      // Check if authentication failed
      if (mounted && authProvider.state == AppAuthState.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Authentication failed',
            ),
          ),
        );
        authProvider.clearError();
      }
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

  @override
  Widget build(BuildContext context) {
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
