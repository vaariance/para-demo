import 'package:para/para.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:para_demo/client/parra_extension.dart';

class ParaClient {
  static final ParaClient _instance = ParaClient._internal();
  factory ParaClient() => _instance;
  ParaClient._internal();

  late final Parra para;
  late final SessionPersistenceService sessionPersistence;
  Future<void> initialize() async {
    sessionPersistence = SessionPersistenceService();

    para = Parra.fromConfig(
      config: ParaConfig(
        apiKey: dotenv.env['PARA_API_KEY'] ?? '',
        environment: Environment.beta,
        requestTimeout: const Duration(seconds: 30), // Increase timeout
      ),
      appScheme: 'parademo',
      sessionPersistence: sessionPersistence,
    );
  }
}

final paraClient = ParaClient();
