# Para + Variance: ERC-4337 Account Abstraction Integration

A complete demonstration of bridging Para's embedded wallet with Variance SDK to enable ERC-4337 Account Abstraction (smart accounts).

## 🎯 Overview

This integration demonstrates how to use **Para's embedded wallet** as a signer for **ERC-4337 smart accounts** using the Variance SDK. It bridges Para's authentication and key management with Ethereum's Account Abstraction standard, enabling gasless transactions, batch operations, and enhanced security for your users.

### What This Enables

- ✅ **Smart Account Creation**: Deploy ERC-4337 Safe smart accounts for users
- ✅ **Gasless Transactions**: Sponsor gas fees for your users
- ✅ **Batch Operations**: Execute multiple transactions atomically
- ✅ **Social Recovery**: Add guardians and recovery mechanisms
- ✅ **Session Keys**: Delegate limited permissions without exposing main keys
- ✅ **Para Authentication**: OAuth (Google, Apple) + Passkey security

## 📚 Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Architecture](#architecture)
- [Core Components](#core-components)
- [Quick Start](#quick-start)

### Required Packages

```yaml
dependencies:
  flutter: sdk: flutter
  para: ^latest_version
  variance_dart: ^latest_version
  web3_signers: ^latest_version
  web3dart: ^2.7.0
  crypto: ^3.0.3
  eth_sig_util: ^latest_version
```

### API Keys & Configuration

1. **Para Account**: Sign up at [Para Dashboard](https://dashboard.getpara.com)
2. **RPC Provider**: Your target RPC
3. **Bundler**: ERC-4337 bundler endpoint (Pimlico, Stackup, Gelato or run your own)

## 📦 Installation

### 1. Add Dependencies

```bash
flutter pub add para variance_dart web3_signers web3dart crypto eth_sig_util
```

### 2. Clone This Repository

```bash
git clone https://github.com/vaariance/para-demo.git
cd para-demo
```

### 3. Configure Environment

Create a `.env` file:

```env
PARA_API_KEY=your_para_api_key
PARA_ENVIRONMENT=beta  # or production
VARIANCE_API_KEY=your_variance_api_key
RPC_URL=your_ethereum_rpc_url
BUNDLER_URL=your_bundler_url
ENTRYPOINT_ADDRESS= There are existing entrypoints address in the variance_dart package to utilize
```

### 4. Para Configuration

```dart
final para = Parra.fromConfig(
      config: ParaConfig(
        apiKey: dotenv.env['PARA_API_KEY'] ?? '',
        environment: Environment.beta,
        requestTimeout: const Duration(seconds: 60),
      ),
      appScheme: 'parademo',
      sessionPersistence: sessionPersistence,
    );
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Your Flutter App                        │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                    ParaSigner (MSI)                          │
│  • Implements MultiSignerInterface                           │
│  • Bridges Para ↔ Variance                                   │
│  • Handles EIP-191 signing                                   │
└────────────┬────────────────────────────┬───────────────────┘
             │                            │
             ↓                            ↓
┌────────────────────────┐   ┌──────────────────────────────┐
│    Parra (Custom)      │   │    Variance SDK              │
│  • signMessageRaw()    │   │  • Smart Account Factory     │
│  • Base64 encoding     │   │  • UserOp creation           │
│  • JS Bridge access    │   │  • Bundler communication     │
└────────┬───────────────┘   └──────────────┬───────────────┘
         │                                   │
         ↓                                   ↓
┌────────────────────────┐   ┌──────────────────────────────┐
│    Para SDK            │   │    ERC-4337 Network          │
│  • Capsule MPC         │   │  • EntryPoint Contract       │
│  • OAuth               │   │  • Bundler                   │
│  • Passkey Auth        │   │  • Paymaster (optional)      │
└────────────────────────┘   └──────────────────────────────┘
```

## Core Components

### 1. Parra Class (Extended Para SDK)

The `Parra` class extends Para's SDK to add raw byte signing capability, which is required for ERC-4337 but not supported out-of-the-box.

```dart
class Parra extends Para {
  /// Signs raw bytes by directly accessing the Capsule JS bridge
  /// This bypasses Para's string-only signMessage API
  ParaFuture<SignatureResult> signMessageRaw({
    required String walletId,
    required String messageBase64,  // Base64-encoded bytes
  }) {
    // Direct JS bridge call with proper keyshare loading
  }
}
```

**Key Features:**

- Direct access to Capsule's signing infrastructure
- Base64 encoding for byte transport
- Automatic transmission keyshare loading
- Proper error handling

### 2. ParaSigner Class (MSI Implementation)

Implements the `MultiSignerInterface` (MSI) from web3_signers, making Para compatible with Variance and other Ethereum libraries.

```dart
class ParaSigner extends MSI {
  final Parra client;
  final para.Wallet _wallet;

  @override
  Future<Uint8List> personalSign(Uint8List hash, {int? index}) async {
    // EIP-191 implementation with Para signing
  }

  @override
  Future<MsgSignature> signToEc(Uint8List hash, {int? index}) async {
    // ECDSA signature for transaction signing
  }
}
```

**Key Features:**

- EIP-191 compliant personal message signing
- EIP-712 typed data signing support
- Signature verification
- V value normalization (0/1 → 27/28)

### 3. Smart Account Factory

Creates and manages ERC-4337 Safe smart accounts.

```dart
static Future<SmartWallet> createSafeAccount(
  Parra client,
  para.Wallet wallet,
  Chain chain,
  Uint256 salt,
) async {
  final signer = ParaSigner.fromWallet(client, wallet);
  final factory = SmartWalletFactory(chain, signer);
  return await factory.createSafeAccount(salt);
}
```

## 🚀 Quick Start

### Step 1: Initialize Para

```dart
import 'package:para/para.dart';
import 'parra.dart';  // Your custom extension

Future<Parra> initializePara() async {
  final para = Parra(
    environment: Environment.beta,
    apiKey: 'your_api_key',
    appScheme: 'myapp',
  );

  return para;
}
```

### Step 2: Authenticate User

```dart
Future<para.Wallet> authenticateUser(Parra client) async {
  // OAuth authentication
  final authResult = await client.verifyOAuth(
    provider: OAuthProvider.google,
  );

  if (authResult.stage == AuthStage.login) {
    // User authenticated, get wallet
    final wallets = await client.getWallets();
    return wallets.first;
  }

  throw Exception('Authentication failed');
}
```

### Step 3: Create Smart Account

```dart
import 'package:variance_dart/variance_dart.dart';
import 'para_signer.dart';

Future<SmartWallet> createSmartAccount(
  Parra paraClient,
  para.Wallet paraWallet,
) async {
  // Configure chain
  final chain = Chain(
    chainId: 84532,  // Base Sepolia
    rpcUrl: 'your_rpc_url',
    bundlerUrl: 'your_bundler_url',
    entrypoint: EthereumAddress.fromHex(
      '0x0000000071727De22E5E9d8BAf0edAc6f37da032',
    ),
  );

  // Create smart account
  final smartWallet = await ParaSigner.createSafeAccount(
    paraClient,
    paraWallet,
    chain,
    Uint256.zero,  // Salt for deterministic address
  );

  print('Smart Account Address: ${smartWallet.address}');
  return smartWallet;
}
```

### Step 4: Send Transaction

```dart
Future<String> sendTransaction(SmartWallet wallet) async {
  // Create transaction
  final tx = Contract.function(
    'transfer',
    EthereumAddress.fromHex('0xRecipient...'),
    amount: BigInt.from(1000000),  // 0.001 ETH
  );

  // Send via smart account
  final userOpHash = await wallet.sendUserOperation(tx);
  print('UserOp Hash: $userOpHash');

  // Wait for confirmation
  final receipt = await wallet.waitForUserOperationReceipt(userOpHash);
  print('Transaction Hash: ${receipt.transactionHash}');

  return receipt.transactionHash;
}
```

#### Our Solution

```dart
// 1. Encode bytes as base64 (string representation of bytes)
String messageBase64 = base64Encode(hash);  // "Op9f2b..."

// 2. Call Capsule JS bridge directly
final sig = await client.signMessageRaw(
  walletId: wallet.id!,
  messageBase64: messageBase64,  // Para decodes back to bytes internally
);

// 3. Capsule signs the actual bytes (not string)
// Result: Valid Ethereum signature ✅
```

### EIP-191 Personal Sign Implementation

```dart
Future<Uint8List> personalSign(Uint8List message) async {
  // 1. Add Ethereum message prefix
  final prefix = '\u0019Ethereum Signed Message:\n${message.length}';
  final prefixBytes = ascii.encode(prefix);

  // 2. Concatenate prefix + message
  final payload = prefixBytes.concat(message);

  // 3. Hash the complete payload
  final digest = keccak256(payload);

  // 4. Sign via Para (as base64)
  final sig = await client.signMessageRaw(
    walletId: _wallet.id!,
    messageBase64: base64Encode(digest),
  );

  // 5. Parse and normalize signature
  final sigBytes = hexToBytes(sig.signedTransaction);
  final r = sigBytes.sublist(0, 32);
  final s = sigBytes.sublist(32, 64);
  final v = 27 + sigBytes[64];  // Convert parity (0/1) to Ethereum v (27/28)

  return Uint8List.fromList([...r, ...s, v]);
}
```

### Signature Format

Para returns signatures in this format:

```
[r (32 bytes)][s (32 bytes)][v (1 byte)]
Total: 65 bytes

r: ECDSA signature component
s: ECDSA signature component
v: Recovery ID (Para uses 0/1, Ethereum expects 27/28)
```

**Important:** Para returns `v` as the parity bit (0 or 1). We must add 27 to convert to Ethereum's standard:

```dart
final parity = sigBytes[64];  // 0 or 1 from Para
final v = 27 + parity;        // 27 or 28 for Ethereum
```

### Why Base64 Encoding?

Para's API signature requires strings:

```dart
// Para's API definition
Future<SignatureResult> signMessage({
  required String walletId,
  required String message,  // ← Must be String
});
```

Base64 is a standard way to represent binary data as text:

```
Binary:  [0x3a, 0x5f, 0x2b]
         ↓
Base64:  "Op8r"
         ↓ (Para decodes)
Binary:  [0x3a, 0x5f, 0x2b]  ✅ Same bytes
```

This ensures Para signs the **exact bytes** we intend, not a string representation.

### Transmission Keyshare Loading

Para uses Capsule's MPC (Multi-Party Computation) for key management. Before signing, we must ensure keyshares are loaded:

```dart
Future<void> _ensureTransmissionKeysharesLoaded() async {
  if (!_transmissionKeysharesLoaded) {
    final sharesLoaded = await loadTransmissionKeyshares();
    if (sharesLoaded > 0) {
      _transmissionKeysharesLoaded = true;
    }
  }
}
```

**Why this matters:**

- Capsule splits private keys across multiple parties
- Keyshares must be loaded before signing
- Without this, signing operations fail silently
