import 'package:para/para.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ParaClient {
  static final ParaClient _instance = ParaClient._internal();
  factory ParaClient() => _instance;
  ParaClient._internal();

  late final Para para;
  late final SessionPersistenceService sessionPersistence;
  Future<void> initialize() async {
    sessionPersistence = SessionPersistenceService();

    para = Para.fromConfig(
      config: ParaConfig(
        apiKey: dotenv.env['PARA_API_KEY'] ?? '',
        environment: Environment.beta,
      ),
      appScheme: 'parademo',
      sessionPersistence: sessionPersistence,
    );
  }
}

final paraClient = ParaClient();
