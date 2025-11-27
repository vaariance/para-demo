import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:para/para.dart';

class EVMWalletView extends StatefulWidget {
  final Wallet wallet;

  const EVMWalletView({super.key, required this.wallet});

  @override
  State<EVMWalletView> createState() => _EVMWalletViewState();
}

class _EVMWalletViewState extends State<EVMWalletView> {
  bool _isProcessing = false;

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _showTransferDialog() async {
    final toController = TextEditingController();
    final amountController = TextEditingController();
    final tokenAddressController = TextEditingController();
    final chainIdController = TextEditingController();
    final rpcUrlController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Tokens'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: toController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Address *',
                  hintText: '0x...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (in wei) *',
                  hintText: '1000000000000000000',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tokenAddressController,
                decoration: const InputDecoration(
                  labelText: 'Token Address (optional)',
                  hintText: '0x... (leave empty for native token)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: chainIdController,
                decoration: const InputDecoration(
                  labelText: 'Chain ID (optional)',
                  hintText: 'e.g., 1 for Ethereum',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rpcUrlController,
                decoration: const InputDecoration(
                  labelText: 'RPC URL (optional)',
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showMintNftDialog() async {
    final contractController = TextEditingController();
    final toController = TextEditingController(text: widget.wallet.address);
    final tokenIdController = TextEditingController();
    final tokenUriController = TextEditingController();
    final chainIdController = TextEditingController();
    final rpcUrlController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mint NFT'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contractController,
                decoration: const InputDecoration(
                  labelText: 'NFT Contract Address *',
                  hintText: '0x...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: toController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Address *',
                  hintText: '0x...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tokenIdController,
                decoration: const InputDecoration(
                  labelText: 'Token ID *',
                  hintText: '1',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tokenUriController,
                decoration: const InputDecoration(
                  labelText: 'Token URI (optional)',
                  hintText: 'ipfs://...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: chainIdController,
                decoration: const InputDecoration(
                  labelText: 'Chain ID (optional)',
                  hintText: 'e.g., 1 for Ethereum',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rpcUrlController,
                decoration: const InputDecoration(
                  labelText: 'RPC URL (optional)',
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(onPressed: () {}, child: const Text('Mint')),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
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
        title: const Text(
          'EVM Wallet',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Wallet Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 50,
                    color: Colors.purple,
                  ),
                ),

                const SizedBox(height: 24),

                // Address Card
                _buildInfoCard(
                  context,
                  title: 'Wallet Address',
                  value: widget.wallet.address ?? '',
                  onCopy: () => _copyToClipboard(
                    context,
                    widget.wallet.address ?? '',
                    'Address',
                  ),
                ),

                const SizedBox(height: 12),

                // ID Card
                _buildInfoCard(
                  context,
                  title: 'Wallet ID',
                  value: widget.wallet.id ?? '',
                  onCopy: () => _copyToClipboard(
                    context,
                    widget.wallet.id ?? '',
                    'Wallet ID',
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButton(
                  context,
                  label: 'Transfer Tokens',
                  icon: Icons.send,
                  color: Colors.blue,
                  onTap: _showTransferDialog,
                ),

                const SizedBox(height: 12),

                _buildActionButton(
                  context,
                  label: 'Mint NFT',
                  icon: Icons.auto_awesome,
                  color: Colors.purple,
                  onTap: _showMintNftDialog,
                ),

                const SizedBox(height: 24),

                // Info section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'About EVM Wallets',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This wallet is compatible with Ethereum and other EVM-compatible chains like Polygon, BSC, Avalanche, and more.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Processing transaction...\nPlease approve in Para WebView',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                    color: Colors.black,
                  ),
                ),
              ),
              IconButton(
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 20),
                tooltip: 'Copy',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : onTap,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
