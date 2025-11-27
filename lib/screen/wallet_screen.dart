import 'package:flutter/material.dart';
import 'package:para/para.dart';
import 'package:para_demo/provider/auth_provider.dart';
import 'package:para_demo/provider/wallet_provider.dart';
import 'package:para_demo/screen/evm_wallet.dart';
import 'package:para_demo/screen/safe_account_card.dart';
import 'package:para_demo/screen/safe_transaction_screen.dart';
import 'package:para_demo/screen/wallet_card.dart';
import 'package:provider/provider.dart';

class WalletsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  const WalletsScreen({
    super.key,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  @override
  void initState() {
    super.initState();
    // Load wallets on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().loadWallets().catchError((e) {
        _handleAuthError(e);
      });
    });
  }

  void _handleAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    final isAuthError = errorString.contains('401') ||
        errorString.contains('unauthorized') ||
        errorString.contains('user must be authenticated') ||
        errorString.contains('authentication');

    if (isAuthError && mounted) {
      debugPrint('Session expired or invalid - logging out user');
      context.read<AuthProvider>().logout();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please log in again.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleRefresh() async {
    try {
      await context.read<WalletProvider>().refreshWallets();
    } catch (e) {
      _handleAuthError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refresh failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleCreateWallet(WalletType type) async {
    try {
      await context.read<WalletProvider>().createWallet(type);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.value} wallet created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Create wallet failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently remove your Para account and all wallets. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<WalletProvider>().deleteAccount();
      if (mounted) {
        widget.onDeleteAccount();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete account failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateWalletSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Consumer<WalletProvider>(
        builder: (context, walletProvider, child) => SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Wallet Type',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                ...WalletType.values.map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: walletProvider.creatingWalletType != null
                            ? null
                            : () => _handleCreateWallet(type),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: walletProvider.creatingWalletType == type
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                type.value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToWalletDetail(Wallet wallet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          switch (wallet.type) {
            case WalletType.evm:
              return EVMWalletView(wallet: wallet);
            default:
              return Scaffold(
                appBar: AppBar(title: const Text('Unknown Wallet')),
                body: const Center(child: Text('Unknown wallet type')),
              );
          }
        },
      ),
    );
  }

  void _navigateToSafeTransaction() {
    final smartWallet = context.read<AuthProvider>().smartWallet;
    if (smartWallet == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SafeTransactionScreen(smartWallet: smartWallet),
      ),
    );
  }

  Future<void> _handleCreateSafeAccount() async {
    final walletProvider = context.read<WalletProvider>();

    if (walletProvider.wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a wallet first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await context.read<AuthProvider>().createSafeAccounts(walletProvider.wallets);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Safe Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create Safe Account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _calculateItemCount(int walletCount, bool hasSafeAccount) {
    // Safe Account card (if exists) + Create Safe Account button (if not exists) + wallets + Add Wallet card
    if (hasSafeAccount) {
      return 1 + walletCount + 1; // Safe Account + wallets + Add Wallet
    } else {
      return 1 + walletCount + 1; // Create Safe Account button + wallets + Add Wallet
    }
  }

  Widget _buildCreateSafeAccountCard(AuthProvider authProvider) {
    return GestureDetector(
      onTap: authProvider.isCreatingSmartWallet ? null : _handleCreateSafeAccount,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withValues(alpha: 0.1),
              Colors.blue.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.purple.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: authProvider.isCreatingSmartWallet
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Creating Safe Account...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF764BA2),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Safe Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Enhanced security smart wallet',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.black.withValues(alpha: 0.3),
                    size: 16,
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F7),
        elevation: 0,
        centerTitle: true,
        leading: Consumer<WalletProvider>(
          builder: (context, walletProvider, child) => IconButton(
            icon: Icon(
              walletProvider.isRefreshing
                  ? Icons.hourglass_empty
                  : Icons.refresh,
              color: Colors.black,
            ),
            onPressed: walletProvider.isRefreshing ? null : _handleRefresh,
          ),
        ),
        title: const Text(
          'Wallets',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          Consumer<WalletProvider>(
            builder: (context, walletProvider, child) => TextButton(
              onPressed: walletProvider.isDeletingAccount
                  ? null
                  : widget.onLogout,
              child: const Text('Logout', style: TextStyle(color: Colors.black)),
            ),
          ),
          Consumer<WalletProvider>(
            builder: (context, walletProvider, child) => TextButton(
              onPressed: walletProvider.isDeletingAccount
                  ? null
                  : _handleDeleteAccount,
              child: walletProvider.isDeletingAccount
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Delete',
                      style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          if (walletProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (walletProvider.state == WalletLoadState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading wallets',
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      context.read<WalletProvider>().loadWallets().catchError(
                            (e) => _handleAuthError(e),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return walletProvider.wallets.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 48,
                        ),
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: _showCreateWalletSheet,
                              child: Container(
                                width: 250,
                                height: 200,
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle,
                                      size: 60,
                                      color: Colors.blue[600],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Create Your First Wallet',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _calculateItemCount(
                          walletProvider.wallets.length,
                          authProvider.smartWallet != null,
                        ),
                        itemBuilder: (context, index) {
                          // Show Safe Account card first if it exists
                          if (authProvider.smartWallet != null && index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SafeAccountCard(
                                smartWallet: authProvider.smartWallet!,
                                onTap: _navigateToSafeTransaction,
                              ),
                            );
                          }

                          // Adjust index if Safe Account exists
                          final walletIndex = authProvider.smartWallet != null
                              ? index - 1
                              : index;

                          // Show Create Safe Account button if no Safe Account exists
                          if (authProvider.smartWallet == null &&
                              walletIndex == 0 &&
                              walletProvider.wallets.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildCreateSafeAccountCard(authProvider),
                            );
                          }

                          // Adjust for the create button
                          final adjustedWalletIndex =
                              authProvider.smartWallet == null
                                  ? walletIndex - 1
                                  : walletIndex;

                          // Show "Add Wallet" card at the end
                          if (adjustedWalletIndex ==
                              walletProvider.wallets.length) {
                            return AddWalletCard(onTap: _showCreateWalletSheet);
                          }

                          // Show regular wallet cards
                          final wallet =
                              walletProvider.wallets[adjustedWalletIndex];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: WalletCard(
                              wallet: wallet,
                              onTap: () => _navigateToWalletDetail(wallet),
                            ),
                          );
                        },
                      );
              },
            ),
          );
        },
      ),
    );
  }
}
