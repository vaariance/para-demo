import 'package:flutter/material.dart';
import 'package:para_demo/provider/auth_provider.dart';
import 'package:para_demo/screen/wallet_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _validateSession();
  }

  Future<void> _validateSession() async {
    final authProvider = context.read<AuthProvider>();

    // Refresh user data to ensure session is still valid
    await authProvider.refreshUser();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Directly show the WalletsScreen
    return WalletsScreen(
      onLogout: () async {
        await authProvider.logout();
      },
      onDeleteAccount: () async {
        final success = await authProvider.deleteAccount();
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }
}
