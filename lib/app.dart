import 'package:flutter/material.dart';
import 'package:para_demo/provider/auth_provider.dart';
import 'package:para_demo/screen/auth_screen.dart';
import 'package:para_demo/screen/home_screen.dart';
import 'package:para_demo/shared/state_widgets.dart';
import 'package:provider/provider.dart';

class ParaApp extends StatefulWidget {
  const ParaApp({super.key});

  @override
  State<ParaApp> createState() => _ParaAppState();
}

class _ParaAppState extends State<ParaApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.state == AppAuthState.initial ||
            authProvider.state == AppAuthState.loading) {
          return const WalletCreationLoadingScreen();
        }
        if (authProvider.state == AppAuthState.unauthenticated ||
            authProvider.state == AppAuthState.error) {
          return const AuthScreen();
        }
        if (authProvider.state == AppAuthState.authenticated) {
          return const HomeScreen();
        }
        return const WalletCreationLoadingScreen();
      },
    );
  }
}
