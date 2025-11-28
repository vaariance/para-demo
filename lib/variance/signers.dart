import 'dart:convert';
import 'dart:typed_data';
import 'package:para/para.dart' as para;
import 'package:para_demo/client/parra_extension.dart';
import 'package:variance_dart/variance_dart.dart';
import 'package:web3_signers/web3_signers.dart';
import 'package:web3dart/crypto.dart';
import 'package:eth_sig_util/eth_sig_util.dart';

class ParaSigner extends MSI {
  final Parra client;
  final para.Wallet _wallet;

  ParaSigner._(this.client, this._wallet);

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

  static ParaSigner fromWallet(Parra client, para.Wallet wallet) {
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
    final prefix = '\u0019Ethereum Signed Message:\n${hash.length}';
    final prefixBytes = ascii.encode(prefix);
    final payload = prefixBytes.concat(hash);
    final digest = keccak256(payload);
    final sig = await client.signMessageRaw(
      walletId: _wallet.id!,
      messageBase64: base64Encode(digest),
    );

    if (sig is! para.SuccessfulSignatureResult) {
      throw Exception("Failed to sign message: $sig");
    }

    final sigWParity = hexToBytes(sig.signedTransaction);
    if (sigWParity.length != 65) {
      throw Exception("Unexpected signature length: ${sigWParity.length}");
    }

    final rAndS = sigWParity.sublist(0, 64);
    final parity = sigWParity[64];

    final v = 27 + parity;
    final signature = Uint8List.fromList([...rAndS, v]);

    return signature;
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
    var v = signature[64];

    if (v < 27) {
      v = v + 27;
    }

    return MsgSignature(r, s, v);
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
      final signerAddress = signer is String
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

  para.Wallet get wallet => _wallet;

  para.WalletType? get walletType => _wallet.type;

  String get walletId => _wallet.id!;

  @override
  Future<Uint8List> signTypedData(
    String jsonData,
    TypedDataVersion version, {
    int? index,
  }) {
    throw UnimplementedError();
  }
}
