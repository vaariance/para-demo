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

extension ParaSignerExtension on para.Para {
  Future<ParaSigner> createSigner() async {
    return await ParaSigner.create(this);
  }

  Future<String> transferToken({
    required String walletId,
    required String to,
    required String amount,
    String? tokenAddress,
    String? chainId,
    String? rpcUrl,
  }) async {
    if (tokenAddress != null) {
      final transferSelector = '0xa9059cbb';

      final addressParam = to.replaceAll('0x', '').padLeft(64, '0');
      final amountBigInt = BigInt.parse(amount);
      final amountParam = amountBigInt.toRadixString(16).padLeft(64, '0');

      final data = '$transferSelector$addressParam$amountParam';

      final transaction = {'to': tokenAddress, 'data': data, 'value': '0'};

      final result = await signTransaction(
        walletId: walletId,
        transaction: transaction,
        chainId: chainId,
        rpcUrl: rpcUrl,
      );

      if (result is para.SuccessfulSignatureResult) {
        return result.signedTransaction;
      }

      throw Exception('Failed to transfer ERC20: $result');
    } else {
      final result = await transfer(
        walletId: walletId,
        to: to,
        amount: amount,
        chainId: chainId,
        rpcUrl: rpcUrl,
      );

      return result.hash;
    }
  }

  Future<String> mintNft({
    required String walletId,
    required String nftContractAddress,
    required String to,
    required String tokenId,
    String? tokenUri,
    String? chainId,
    String? rpcUrl,
  }) async {
    String data;

    if (tokenUri != null && tokenUri.isNotEmpty) {
      // safeMint(address,uint256,string) - 0xd204c45e
      final selector = '0xd204c45e';
      final addressParam = to.replaceAll('0x', '').padLeft(64, '0');
      final tokenIdBigInt = BigInt.parse(tokenId);
      final tokenIdParam = tokenIdBigInt.toRadixString(16).padLeft(64, '0');

      final stringOffset =
          '0000000000000000000000000000000000000000000000000000000000000060';

      // String data
      final uriBytes = tokenUri.codeUnits;
      final uriLength = uriBytes.length.toRadixString(16).padLeft(64, '0');
      final uriHex = uriBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      final uriData = uriHex.padRight(((uriBytes.length + 31) ~/ 32) * 64, '0');

      data =
          '$selector$addressParam$tokenIdParam$stringOffset$uriLength$uriData';
    } else {
      final selector = '0x40c10f19';
      final addressParam = to.replaceAll('0x', '').padLeft(64, '0');
      final tokenIdBigInt = BigInt.parse(tokenId);
      final tokenIdParam = tokenIdBigInt.toRadixString(16).padLeft(64, '0');
      data = '$selector$addressParam$tokenIdParam';
    }

    final result = await signTransaction(
      walletId: walletId,
      transaction: {'to': nftContractAddress, 'data': data, 'value': '0'},
      chainId: chainId,
      rpcUrl: rpcUrl,
    );

    if (result is para.SuccessfulSignatureResult) {
      return result.signedTransaction;
    }
    throw Exception('Failed to mint NFT: $result');
  }
}
