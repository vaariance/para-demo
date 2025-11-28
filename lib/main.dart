import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:para_demo/app.dart';
import 'package:para_demo/client/para_client.dart';
import 'package:para_demo/provider/auth_provider.dart';
import 'package:para_demo/provider/wallet_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await paraClient.initialize();

  runApp(const ParaFlutterApp());
}

class ParaFlutterApp extends StatelessWidget {
  const ParaFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: MaterialApp(
        home: const ParaApp(),
        title: 'Para Demo',
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
