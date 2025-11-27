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
      appScheme: 'parademo',
      sessionPersistence: sessionPersistence,
    );

    phantomConnector = ParaPhantomConnector(
      para: para,
      appUrl: "https://com.example.para_demo",
      appScheme: "parademo",
    );

    metamaskConnector = ParaMetaMaskConnector(
      para: para,
      appUrl: "https://com.example.para_demo",
      appScheme: "parademo",
      config: const MetaMaskConfig(
        appName: "ParaDemo",
        appId: "com.example.para_demo",
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
