import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/storage_service.dart';
import 'core/services/ai_service.dart';
import 'core/services/chromium_session_service.dart';
import 'core/network/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'providers/ai_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Local Storage & Services
  final storage = await StorageService.getInstance();
  final apiClient = ApiClient(storage);
  final aiService = AiService(storage);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(storage, apiClient)),
        ChangeNotifierProvider(create: (_) => CourseProvider(apiClient, storage)),
        ChangeNotifierProvider(create: (_) => AiProvider(aiService, storage)),
      ],
      child: UnpamMobileApp(initialLoggedIn: storage.hasToken),
    ),
  );
}

class UnpamMobileApp extends StatelessWidget {
  final bool initialLoggedIn;

  const UnpamMobileApp({super.key, required this.initialLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNPAM LMS Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialLoggedIn ? const HomeScreen() : const LoginScreen(),
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            Positioned(
              left: -9999,
              top: -9999,
              width: 1,
              height: 1,
              child: ChromiumSessionService.instance.buildHeadlessWidget(),
            ),
          ],
        );
      },
    );
  }
}
