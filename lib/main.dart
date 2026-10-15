import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/storage_service.dart';
import 'core/services/ai_service.dart';
import 'providers/auth_provider.dart';
import 'providers/ai_provider.dart';
import 'theme/app_theme.dart';
import 'screens/portal_webview_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Local Storage & AI Service
  final storage = await StorageService.getInstance();
  final aiService = AiService(storage);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(storage)),
        ChangeNotifierProvider(create: (_) => AiProvider(aiService, storage)),
      ],
      child: const UnpamMobileApp(),
    ),
  );
}

class UnpamMobileApp extends StatelessWidget {
  const UnpamMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNPAM LMS Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const PortalWebViewScreen(),
    );
  }
}
