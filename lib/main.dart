import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/storage_service.dart';
import 'core/services/ai_service.dart';
import 'providers/ai_provider.dart';
import 'theme/app_theme.dart';
import 'screens/portal_webview_screen.dart';
import 'screens/user_agreement_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Local Storage & AI Service
  final storage = await StorageService.getInstance();
  final aiService = AiService(storage);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AiProvider(aiService, storage)),
      ],
      child: UnpamMobileApp(storageService: storage),
    ),
  );
}

class UnpamMobileApp extends StatelessWidget {
  final StorageService storageService;

  const UnpamMobileApp({
    super.key,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAgreementAccepted = storageService.isUserAgreementAccepted();

    return MaterialApp(
      title: 'UNPAM LMS Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: isAgreementAccepted
          ? const PortalWebViewScreen()
          : UserAgreementScreen(storageService: storageService),
    );
  }
}
