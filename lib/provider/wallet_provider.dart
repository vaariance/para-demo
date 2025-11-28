import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:para/para.dart';
import 'package:para_demo/client/para_client.dart';
import 'package:para_demo/variance/signers.dart';
import 'package:variance_dart/variance_dart.dart';
import 'package:web3_signers/web3_signers.dart';
import 'package:web3dart/web3dart.dart' as web3dart;

enum WalletLoadState { initial, loading, loaded, error }

enum SmartWalletState { initial, loading, created }

final EthereumAddress nft = EthereumAddress.fromHex(
  "0xEBE46f55b40C0875354Ac749893fe45Ce28e1333",
);
// fuse = Address.fromHex("0xBF20E2bB8bb6859A424C898d5a2995c3659b90f2");
final EthereumAddress erc20 = EthereumAddress.fromHex(
  "0x7BF7957315AFbC9bA717b004BB9E3f43321a9A48",
);
// fuse = Address.fromHex("0xAc94c8dD3094AB2D68B092AA34A6e29A293E592a");
final EthereumAddress dump = EthereumAddress.fromHex(
  "0xf5bb7f874d8e3f41821175c0aa9910d30d10e193",
);

class WalletProvider with ChangeNotifier {
  WalletLoadState _state = WalletLoadState.initial;
  List<Wallet> _wallets = [];
  String? _errorMessage;
  bool _isRefreshing = false;
  WalletType? _creatingWalletType;
  bool _isDeletingAccount = false;
  SmartWalletState _smartWalletState = SmartWalletState.initial;

  WalletLoadState get state => _state;
  List<Wallet> get wallets => _wallets;
  String? get errorMessage => _errorMessage;
  bool get isRefreshing => _isRefreshing;
  WalletType? get creatingWalletType => _creatingWalletType;
  bool get isDeletingAccount => _isDeletingAccount;
  bool get isLoading => _state == WalletLoadState.loading;
  SmartWallet? _smartWallet;

  SmartWalletState get smartWalletState => _smartWalletState;
  bool get isCreatingSmartWallet =>
      _smartWalletState == SmartWalletState.loading;
  bool get isSmartWalletCreated =>
      _smartWalletState == SmartWalletState.created;
  SmartWallet? get smartWallet => _smartWallet;

  Future<void> loadWallets() async {
    _state = WalletLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Touch the session to ensure it's still valid
      await paraClient.para.touchSession();

      _wallets = await paraClient.para.fetchWallets();
      _state = WalletLoadState.loaded;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _state = WalletLoadState.error;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createSafeAccount() async {
    try {
      _setSmartWalletState(SmartWalletState.loading);

      // Ensure we have wallets loaded
      if (_wallets.isEmpty) {
        await loadWallets();
      }

      final evmWallet = _wallets.firstWhere(
        (w) => w.type == WalletType.evm,
        orElse: () => throw Exception('No EVM wallet found'),
      );

      final safeAccount = await ParaSigner.createSafeAccount(
        paraClient.para,
        evmWallet,
        getChain(),
        Uint256.zero,
      );
      _smartWallet = safeAccount;
      _setSmartWalletState(SmartWalletState.created);
    } catch (e) {
      log(e.toString());
      _setSmartWalletState(SmartWalletState.initial);
      rethrow;
    }
  }

  Chain getChain() {
    return Chains.getChain(Network.baseTestnet)
      ..accountFactory = Addresses.safeProxyFactoryAddress
      ..bundlerUrl =
          'https://api.pimlico.io/v2/84532/rpc?apikey=pim_NuuL4a9tBdyfoogF5LtP5A'
      ..jsonRpcUrl = 'https://base-sepolia.drpc.org'
      ..testnet = true
      ..paymasterUrl =
          'https://api.pimlico.io/v2/84532/rpc?apikey=pim_NuuL4a9tBdyfoogF5LtP5A';
  }

  Future<(bool, String)> simulateTransfer(SmartWallet smartWallet) async {
    final mintAbi = ContractAbis.get("ERC20_Mint");
    final amount = BigInt.from(20e18);
    final mintCall = Contract.encodeFunctionCall("mint", erc20, mintAbi, [
      smartWallet.address,
      amount,
    ]);

    final transferCall = Contract.encodeERC20TransferCall(
      erc20,
      dump,
      web3dart.EtherAmount.fromBigInt(web3dart.EtherUnit.wei, amount),
    );

    try {
      UserOperationResponse? tx;
      tx = await smartWallet.sendBatchedTransaction(
        [erc20, erc20],
        [mintCall, transferCall],
      );

      final reciept = await tx.wait();
      final txHash = reciept?.userOpHash;
      if (txHash == null) {
        return (false, "Transaction failed");
      }
      return (true, txHash);
    } catch (e) {
      final errString = e.toString();
      log(errString);
      return (
        false,
        errString.substring(0, errString.length > 200 ? 200 : null),
      );
    }
  }

  Future<void> mintTransfer() async {
    if (_smartWallet == null) {
      throw Exception('Smart wallet not created yet. Please create a Safe account first.');
    }

    final result = await simulateTransfer(_smartWallet!);
    if (!result.$1) {
      throw Exception(result.$2);
    }
  }

  Future<void> mintNft() async {
    if (_smartWallet == null) {
      throw Exception('Smart wallet not created yet. Please create a Safe account first.');
    }

    try {
      final mintAbi = ContractAbis.get("ERC721_Mint");
      final mintCall = Contract.encodeFunctionCall("mint", nft, mintAbi, [
        _smartWallet!.address,
      ]);

      final tx = await _smartWallet!.sendTransaction(nft, mintCall);
      final receipt = await tx.wait();

      if (receipt?.userOpHash == null) {
        throw Exception('NFT minting transaction failed');
      }
    } catch (e) {
      log('NFT minting error: $e');
      rethrow;
    }
  }

  Future<void> refreshWallets() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      // Touch the session to ensure it's still valid
      await paraClient.para.touchSession();

      _wallets = await paraClient.para.fetchWallets();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> createWallet(WalletType type) async {
    _creatingWalletType = type;
    notifyListeners();

    try {
      await paraClient.para.createWallet(type: type, skipDistribute: false);
      await loadWallets();
    } finally {
      _creatingWalletType = null;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    if (_isDeletingAccount) return;

    _isDeletingAccount = true;
    notifyListeners();

    try {
      await paraClient.para.deleteAccount();
    } finally {
      _isDeletingAccount = false;
      notifyListeners();
    }
  }

  void _setSmartWalletState(SmartWalletState newState) {
    _smartWalletState = newState;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
