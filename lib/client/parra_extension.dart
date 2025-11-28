import 'package:para/para.dart';
import 'package:para/src/services/web_view_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class Parra extends Para {
  Parra({
    required super.environment,
    required super.apiKey,
    required super.appScheme,
    super.config,
    super.sessionPersistence,
  });

  factory Parra.fromConfig({
    required ParaConfig config,
    required String appScheme,
    SessionPersistenceService? sessionPersistence,
  }) {
    return Parra(
      environment: config.environment,
      apiKey: config.apiKey,
      appScheme: appScheme,
      config: config,
      sessionPersistence: sessionPersistence,
    );
  }

  WebViewService get _webview => WebViewService(
    bridgeUri: config.jsBridgeUri ?? WebUri.uri(environment.jsBridgeUri),
    environment: environment.name.toUpperCase(),
    apiKey: apiKey,
    timeout: config.requestTimeout,
  );

  ParaFuture<SignatureResult> signMessageRaw({
    required String walletId,
    required String messageBase64,
  }) {
    // Create a unique request ID for this operation
    final requestId = 'signMessageRaw-${DateTime.now().microsecondsSinceEpoch}';

    // Create the future that will handle the async operation
    final future = (() async {
      // load everytime
      await loadTransmissionKeyshares();

      // Now proceed with signing the message
      final params = {'walletId': walletId, 'messageBase64': messageBase64};
      final handle = _webview.createRequest('signMessage', params);
      final res = await handle.future;

      if (res is! Map<String, dynamic>) {
        throw ParaBridgeException(
          'Expected Map but got ${res.runtimeType}',
          code: 'invalid_response_type',
        );
      }
      return SignatureResult.fromMap(res);
    })();

    return ParaFuture<SignatureResult>(requestId, future);
  }
}
