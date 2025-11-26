import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:para_demo/app.dart';
import 'package:para_demo/client/para_client.dart';
import 'package:para_demo/provider/auth_provider.dart';
import 'package:para_demo/shared/app_theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await paraClient.initialize();

  runApp(const para_demoApp());
}

class para_demoApp extends StatelessWidget {
  const para_demoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: 'Para Wallet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const ParaApp(),
      ),
    );
  }
}
