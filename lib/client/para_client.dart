import 'package:para/para.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/para_config.dart';

/// Para SDK Client Singleton
class ParaClient {
  static final ParaClient _instance = ParaClient._internal();
  factory ParaClient() => _instance;
  ParaClient._internal();

  late final Para para;
  late final ParaPhantomConnector phantomConnector;
  late final ParaMetaMaskConnector metamaskConnector;
  late final SessionPersistenceService sessionPersistence;
  Future<void> initialize() async {
    sessionPersistence = SessionPersistenceService();
    final config = ParaConfiguration(
      apiKey: dotenv.env['PARA_API_KEY'] ?? 'YOUR_API_KEY_HERE',
      environment: _getEnvironmentFromString(dotenv.env['PARA_ENV']),
    );

    // Initialize Para SDK
    para = Para.fromConfig(
      config: config.toParaConfig(),
      appScheme: 'paraflutter',
      sessionPersistence: sessionPersistence,
    );

    phantomConnector = ParaPhantomConnector(
      para: para,
      appUrl: "https://com.para.example.flutter",
      appScheme: "paraflutter",
    );

    metamaskConnector = ParaMetaMaskConnector(
      para: para,
      appUrl: "https://com.para.example.flutter",
      appScheme: "paraflutter",
      config: const MetaMaskConfig(
        appName: "ParaFlutter",
        appId: "com.para.example.flutter",
      ),
    );
  }

  /// Helper function to map environment string to Environment enum
  Environment _getEnvironmentFromString(String? envString) {
    switch (envString?.toLowerCase()) {
      case 'sandbox':
        return Environment.sandbox;
      case 'beta':
        return Environment.beta;
      case 'prod':
        return Environment.prod;
      default:
        return Environment.beta;
    }
  }
}

// Global instance for easy access
final paraClient = ParaClient();
