import 'dart:typed_data';
import 'package:para/para.dart' as para;
import 'package:web3_signers/web3_signers.dart';
import 'package:web3dart/crypto.dart';
import 'package:eth_sig_util/constant/typed_data_version.dart';

class ParaSigner extends MSI {
  final para.Para client;
  final para.Wallet _wallet;

  ParaSigner._(this.client, this._wallet);

  static Future<ParaSigner> create(para.Para client) async {
    final wallet = await _fetchOrCreateWallet(client);
    return ParaSigner._(client, wallet);
  }

  static ParaSigner fromWallet(para.Para client, para.Wallet wallet) {
    if (wallet.id == null || wallet.address == null) {
      throw ArgumentError('Wallet must have an ID and address');
    }
    return ParaSigner._(client, wallet);
  }

  @override
  String getAddress({int? index}) {
    return _wallet.address!;
  }

  @override
  String getDummySignature() {
    return "0xee2eb84d326637ae9c4eb2febe1f74dc43e6bb146182ef757ebf0c7c6e0d29dc2530d8b5ec0ab1d0d6ace9359e1f9b117651202e8a7f1f664ce6978621c7d5fb1b";
  }

  @override
  Future<Uint8List> personalSign(Uint8List hash, {int? index}) async {
    final sig = await client.signMessage(
      message: hexlify(hash),
      walletId: _wallet.id!,
    );

    if (sig is para.SuccessfulSignatureResult) {
      return hexToBytes(sig.signedTransaction);
    }

    throw Exception("Failed to sign message: $sig");
  }

  @override
  Future<MsgSignature> signToEc(Uint8List hash, {int? index}) async {
    final signature = await personalSign(hash, index: index);
    if (signature.length != 65) {
      throw Exception(
        'Invalid signature length: expected 65, got ${signature.length}',
      );
    }

    final r = bytesToUnsignedInt(signature.sublist(0, 32));
    final s = bytesToUnsignedInt(signature.sublist(32, 64));
    final v = signature[64];

    return MsgSignature(r, s, v);
  }

  @override
  Future<Uint8List> signTypedData(
    String jsonData,
    TypedDataVersion version, {
    int? index,
  }) async {
    return Future.error(
      UnimplementedError('signTypedData is not implemented yet'),
    );
  }

  @override
  Future<ERC1271IsValidSignatureResponse> isValidSignature<T, U>(
    Uint8List hash,
    U signature,
    T signer,
  ) async {
    require(
      signature is Uint8List || signature is MsgSignature,
      'Signature must be of type Uint8List or MsgSignature',
    );
    require(
      signer is String || signer is EthereumAddress,
      'Signer must be of type String or EthereumAddress',
    );

    try {
      final signerAddress =
          signer is String
              ? EthereumAddress.fromHex(signer)
              : signer as EthereumAddress;

      if (signature is Uint8List) {
        return Future.value(
          isValidPersonalSignature(hash, signature, signerAddress),
        );
      } else {
        final sig = signature as MsgSignature;
        final recoveredSigner = ecRecover(keccak256(hash), sig);
        return Future.value(
          ERC1271IsValidSignatureResponse.isValid(
            publicKeyToAddress(recoveredSigner).eq(signerAddress.addressBytes),
          ),
        );
      }
    } catch (e) {
      throw Exception('Signature validation failed: $e');
    }
  }

  static Future<para.Wallet> _fetchOrCreateWallet(para.Para client) async {
    final wallets = await client.fetchWallets();

    if (wallets.isEmpty) {
      final result = await client.createWallet(
        type: para.WalletType.evm,
        skipDistribute: false,
      );
      return result;
    }

    return wallets.first;
  }

  para.Wallet get wallet => _wallet;

  para.WalletType? get walletType => _wallet.type;

  String get walletId => _wallet.id!;
}
