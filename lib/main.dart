import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/services/storage_service.dart';
import 'core/services/ai_service.dart';
import 'core/services/biometric_auth_service.dart';
import 'core/services/notification_service.dart';
import 'providers/ai_provider.dart';
import 'providers/biometric_provider.dart';
import 'features/schedule/data/schedule_service.dart';
import 'features/schedule/data/deadline_reminder_service.dart';
import 'features/schedule/presentation/providers/schedule_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/app_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale formatting untuk format tanggal Indonesia
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi notifikasi lokal sistem Android
  await NotificationService().initialize();

  // Inisialisasi reminder deadline
  await DeadlineReminderService().initialize();

  // Inisialisasi Local Storage, Biometric & AI Service
  final storage = await StorageService.getInstance();
  final aiService = AiService(storage);
  final biometricService = BiometricAuthService(prefs: storage.rawPreferences);
  final scheduleService = ScheduleService(storage.rawPreferences);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AiProvider(aiService, storage)),
        ChangeNotifierProvider(create: (_) => BiometricProvider(biometricService)),
        ChangeNotifierProvider(
          create: (_) => ScheduleProvider(scheduleService, storage.rawPreferences),
        ),
      ],
      child: ThePamsApp(storageService: storage),
    ),
  );
}

class ThePamsApp extends StatelessWidget {
  final StorageService storageService;

  const ThePamsApp({
    super.key,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The PAMs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AppGate(storageService: storageService),
    );
  }
}

/// Backward compatibility alias
typedef UnpamMobileApp = ThePamsApp;
