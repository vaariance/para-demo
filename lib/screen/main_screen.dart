import 'package:flutter/material.dart';
import 'package:para/para.dart';
import 'package:para_demo/provider/auth_provider.dart';
import 'package:para_demo/provider/wallet_provider.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isProcessing = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWalletData();
    });
  }

  Future<void> _loadWalletData() async {
    final walletProvider = context.read<WalletProvider>();
    await walletProvider.loadWallets();
  }

  Future<void> _handleCreateSafeAccount() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Creating Safe account...';
    });

    try {
      final walletProvider = context.read<WalletProvider>();
      await walletProvider.createSafeAccount();

      if (mounted) {
        setState(() {
          _statusMessage = 'Safe account created successfully!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Safe account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create Safe account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleMintTransfer() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing mint transfer...';
    });

    try {
      final walletProvider = context.read<WalletProvider>();
      await walletProvider.mintTransfer();

      if (mounted) {
        setState(() {
          _statusMessage = 'Mint transfer completed successfully!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mint transfer completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mint transfer failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleMintNft() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Minting NFT...';
    });

    try {
      final walletProvider = context.read<WalletProvider>();
      await walletProvider.mintNft();

      if (mounted) {
        setState(() {
          _statusMessage = 'NFT minted successfully!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NFT minted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NFT minting failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Para Demo',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<WalletProvider>(
          builder: (context, walletProvider, child) {
            final evmWallets = walletProvider.wallets
                .where((w) => w.type == WalletType.evm)
                .toList();

            final walletAddress = evmWallets.isNotEmpty
                ? evmWallets.first.address
                : 'No wallet yet';

            final safeAddress = walletProvider.smartWallet?.address.hex;
            final hasSafeAccount = walletProvider.isSmartWalletCreated;

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // EVM Wallet Address Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evm Signer',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          walletAddress ?? 'Loading...',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontFamily: 'monospace',
                                color: Colors.black87,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Safe Account Address Card
                  if (hasSafeAccount && safeAddress != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: const Color(0xFF6366F1),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Safe Account Address',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6366F1),
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            safeAddress,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontFamily: 'monospace',
                                  color: Colors.black87,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Status Message
                  if (_statusMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!hasSafeAccount)
                          _ActionButton(
                            label: 'Create Safe Account',
                            icon: Icons.account_balance_wallet,
                            onPressed: _isProcessing ? null : _handleCreateSafeAccount,
                            color: const Color(0xFF6366F1),
                          ),
                        if (!hasSafeAccount) const SizedBox(height: 16),
                        _ActionButton(
                          label: 'Mint Transfer',
                          icon: Icons.swap_horiz,
                          onPressed: _isProcessing ? null : _handleMintTransfer,
                          color: const Color(0xFF8B5CF6),
                        ),
                        const SizedBox(height: 16),
                        _ActionButton(
                          label: 'Mint NFT',
                          icon: Icons.image,
                          onPressed: _isProcessing ? null : _handleMintNft,
                          color: const Color(0xFFEC4899),
                        ),
                      ],
                    ),
                  ),

                  // Loading Indicator
                  if (_isProcessing)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
