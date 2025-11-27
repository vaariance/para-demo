import 'package:flutter/foundation.dart';
import 'package:para/para.dart';
import 'package:para_demo/client/para_client.dart';

enum WalletLoadState { initial, loading, loaded, error }

class WalletProvider with ChangeNotifier {
  WalletLoadState _state = WalletLoadState.initial;
  List<Wallet> _wallets = [];
  String? _errorMessage;
  bool _isRefreshing = false;
  WalletType? _creatingWalletType;
  bool _isDeletingAccount = false;

  WalletLoadState get state => _state;
  List<Wallet> get wallets => _wallets;
  String? get errorMessage => _errorMessage;
  bool get isRefreshing => _isRefreshing;
  WalletType? get creatingWalletType => _creatingWalletType;
  bool get isDeletingAccount => _isDeletingAccount;
  bool get isLoading => _state == WalletLoadState.loading;

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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
