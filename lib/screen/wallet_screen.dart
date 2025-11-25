import 'package:flutter/material.dart';
import 'package:para/para.dart';
import 'package:para_demo/client/para_client.dart';
import 'package:para_demo/screen/cosmos.dart';
import 'package:para_demo/screen/evm_wallet.dart';
import 'package:para_demo/screen/solana_wallet.dart';
import 'package:para_demo/screen/wallet_card.dart';

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
  List<Wallet> _wallets = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  WalletType? _creatingWalletType;
  bool _isDeletingAccount = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    try {
      final wallets = await paraClient.para.fetchWallets();
      if (mounted) {
        setState(() {
          _wallets = wallets;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _refreshWallets() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      final wallets = await paraClient.para.fetchWallets();
      if (mounted) {
        setState(() {
          _wallets = wallets;
          _isRefreshing = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _error = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refresh failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _createWallet(WalletType type, StateSetter setModalState) async {
    setState(() => _creatingWalletType = type);
    setModalState(() => _creatingWalletType = type);

    try {
      await paraClient.para.createWallet(type: type, skipDistribute: false);
      await _loadWallets();
      if (mounted) {
        setState(() => _creatingWalletType = null);
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
        setState(() => _creatingWalletType = null);
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
    if (_isDeletingAccount) return;

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

    if (confirmed != true) return;

    setState(() => _isDeletingAccount = true);

    try {
      await paraClient.para.deleteAccount();
      if (mounted) {
        widget.onDeleteAccount();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
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
                        onPressed: _creatingWalletType != null
                            ? null
                            : () => _createWallet(type, setModalState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _creatingWalletType == type
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
            case WalletType.solana:
              return SolanaWalletView(wallet: wallet);
            case WalletType.cosmos:
              return CosmosWalletView(wallet: wallet);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            _isRefreshing ? Icons.hourglass_empty : Icons.refresh,
            color: Colors.black,
          ),
          onPressed: _isRefreshing ? null : _refreshWallets,
        ),
        title: const Text(
          'Wallets',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _isDeletingAccount ? null : widget.onLogout,
            child: const Text('Logout', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: _isDeletingAccount ? null : _handleDeleteAccount,
            child: _isDeletingAccount
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
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
                    onPressed: _loadWallets,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshWallets,
              child: _wallets.isEmpty
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
                      itemCount: _wallets.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _wallets.length) {
                          return AddWalletCard(onTap: _showCreateWalletSheet);
                        }

                        final wallet = _wallets[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: WalletCard(
                            wallet: wallet,
                            onTap: () => _navigateToWalletDetail(wallet),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
