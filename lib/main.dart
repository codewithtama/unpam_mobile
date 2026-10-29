import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'core/services/storage_service.dart';
import 'core/services/ai_service.dart';
import 'core/services/biometric_auth_service.dart';
import 'core/services/notification_service.dart';
import 'providers/ai_provider.dart';
import 'providers/biometric_provider.dart';
import 'features/academic/data/academic_portal_service.dart';
import 'features/academic/data/finance_service.dart';
import 'features/academic/data/my_unpam_refresher.dart';
import 'features/academic/data/my_unpam_session.dart';
import 'features/academic/data/my_unpam_web_fetcher.dart';
import 'features/academic/presentation/providers/academic_portal_provider.dart';
import 'features/academic/presentation/providers/finance_provider.dart';
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

  // Inisialisasi Sesi & Fetcher My UNPAM
  final portalSession = MyUnpamSession(storage);
  final portalRefresher = MyUnpamRefresher(portalSession);
  final portalFetcher = MyUnpamWebFetcher(portalSession);
  portalSession
    ..refresher = portalRefresher.run
    ..fetcher = portalFetcher.get;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AiProvider(aiService, storage)),
        ChangeNotifierProvider(create: (_) => BiometricProvider(biometricService)),
        ChangeNotifierProvider(
          create: (_) => ScheduleProvider(scheduleService, storage.rawPreferences),
        ),
        ChangeNotifierProvider.value(value: portalSession),
        ChangeNotifierProvider(
          create: (_) => FinanceProvider(FinanceService(portalSession, storage), storage),
        ),
        ChangeNotifierProvider(
          create: (_) => AcademicPortalProvider(AcademicPortalService(portalSession, storage)),
        ),
      ],
      child: ThePamsApp(
        storageService: storage,
        portalWebViews: [portalRefresher.controller, portalFetcher.controller],
      ),
    ),
  );
}

class ThePamsApp extends StatelessWidget {
  final StorageService storageService;
  final List<ValueListenable<WebViewController?>> portalWebViews;

  const ThePamsApp({
    super.key,
    required this.storageService,
    required this.portalWebViews,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The PAMs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) => MyUnpamRefreshHost(
        controllers: portalWebViews,
        child: child ?? const SizedBox.shrink(),
      ),
      home: AppGate(storageService: storageService),
    );
  }
}

/// Backward compatibility alias
typedef UnpamMobileApp = ThePamsApp;
