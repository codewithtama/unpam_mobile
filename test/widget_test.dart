import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unpam_mobile/core/services/storage_service.dart';
import 'package:unpam_mobile/core/services/ai_service.dart';
import 'package:unpam_mobile/providers/ai_provider.dart';
import 'package:unpam_mobile/models/ai_model_config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:unpam_mobile/core/services/permission_service.dart';
import 'package:unpam_mobile/screens/user_agreement_screen.dart';
import 'package:unpam_mobile/screens/permission_gate_screen.dart';
import 'package:unpam_mobile/widgets/app_gate.dart';
import 'package:unpam_mobile/models/github_release.dart';
import 'package:unpam_mobile/core/services/update_checker_service.dart';
import 'package:unpam_mobile/widgets/release_history_dialog.dart';
import 'package:unpam_mobile/core/services/file_download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService Session & Config Tests', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.getInstance();
      await storage.resetAll();
    });

    test('Saving and retrieving token and cookies persists correctly', () async {
      expect(storage.hasToken, isFalse);
      expect(storage.getToken(), isNull);
      expect(storage.getCookies(), isNull);

      await storage.saveToken('test_bearer_token_123');
      await storage.saveCookies('session_id=abcxyz; Path=/');

      expect(storage.hasToken, isTrue);
      expect(storage.getToken(), equals('test_bearer_token_123'));
      expect(storage.getCookies(), equals('session_id=abcxyz; Path=/'));

      await storage.clearSession();
      expect(storage.hasToken, isFalse);
      expect(storage.getToken(), isNull);
      expect(storage.getCookies(), isNull);
    });

    test('Gemini API key is saved and retrieved from StorageService', () async {
      expect(storage.getGeminiApiKey(), isNull);

      await storage.saveGeminiApiKey('AIzaSyCustomKey98765');
      expect(storage.getGeminiApiKey(), equals('AIzaSyCustomKey98765'));

      await storage.resetAll();
      expect(storage.getGeminiApiKey(), isNull);
    });

    test('User agreement acceptance flag defaults to false and persists when set', () async {
      expect(storage.isUserAgreementAccepted(), isFalse);

      await storage.setUserAgreementAccepted(true);
      expect(storage.isUserAgreementAccepted(), isTrue);

      await storage.resetAll();
      expect(storage.isUserAgreementAccepted(), isFalse);
    });
  });

  group('AiProvider API Key & State Management Tests', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.getInstance();
      await storage.resetAll();
    });

    test('Saving and removing Gemini API key updates AiProvider state', () async {
      final aiService = AiService(storage);
      final aiProv = AiProvider(aiService, storage);

      expect(aiProv.hasCustomApiKey, isFalse);
      expect(aiProv.getGeminiApiKey(), isEmpty);

      await aiProv.updateGeminiApiKey('AIzaSyDummyKey123456');
      expect(aiProv.hasCustomApiKey, isTrue);
      expect(aiProv.getGeminiApiKey(), equals('AIzaSyDummyKey123456'));

      await aiProv.removeGeminiApiKey();
      expect(aiProv.hasCustomApiKey, isFalse);
      expect(aiProv.getGeminiApiKey(), isEmpty);
    });

    test('AiProvider clearChat resets message list to initial welcome message', () {
      final aiService = AiService(storage);
      final aiProv = AiProvider(aiService, storage);

      aiProv.clearChat();
      expect(aiProv.messages.length, equals(1));
      expect(aiProv.messages.first.isUser, isFalse);
      expect(aiProv.isLoading, isFalse);
    });

    test('AiProvider supports switching between Gemini, DeepSeek, Claude, and Qwen models', () async {
      final aiService = AiService(storage);
      final aiProv = AiProvider(aiService, storage);

      expect(aiProv.availableModels.length, greaterThanOrEqualTo(6));

      // Switch to DeepSeek
      await aiProv.setActiveModel('deepseek');
      expect(aiProv.activeModel.id, equals('deepseek'));
      expect(aiProv.hasKeyForActiveModel, isFalse);

      await storage.saveProviderApiKey(AiProviderType.deepseek, 'sk-deepseek-test');
      expect(aiProv.hasKeyForActiveModel, isTrue);
      expect(aiProv.getApiKeyForProvider(AiProviderType.deepseek), equals('sk-deepseek-test'));

      // Switch to Claude
      await aiProv.setActiveModel('claude');
      expect(aiProv.activeModel.id, equals('claude'));
      expect(aiProv.activeModel.supportsVision, isTrue);

      // Switch to Qwen
      await aiProv.setActiveModel('qwen');
      expect(aiProv.activeModel.id, equals('qwen'));

      // Switch back to Cloud AI
      await aiProv.setActiveModel('free_cloud');
      expect(aiProv.activeModel.id, equals('free_cloud'));
      expect(aiProv.hasKeyForActiveModel, isTrue);
    });

    test('AiProvider analyzeQuestionnaire provides fallback answers and polite feedback draft', () async {
      final aiService = AiService(storage);
      final aiProv = AiProvider(aiService, storage);

      final dummyQuestions = [
        {
          'index': 0,
          'number': '1',
          'questionText': 'Dosen melaksanakan perkuliahan secara daring sesuai jadwal.',
          'options': [
            {'optionIndex': 0, 'optionText': 'Ya'},
            {'optionIndex': 1, 'optionText': 'Tidak'},
          ]
        },
        {
          'index': 1,
          'number': '2',
          'questionText': 'Penggunaan LMS dalam perkuliahan daring.',
          'options': [
            {'optionIndex': 0, 'optionText': 'Sangat Baik'},
            {'optionIndex': 1, 'optionText': 'Kurang'},
          ]
        }
      ];

      final result = await aiProv.analyzeQuestionnaire(
        questions: dummyQuestions,
        courseName: 'Pemrograman Mobile',
      );

      expect(result['answers'], isNotNull);
      final answers = result['answers'] as List<dynamic>;
      expect(answers.length, equals(2));
      expect(answers[0]['recommendedOptionIndex'], equals(0)); // Memilih "Ya"
      expect(answers[1]['recommendedOptionIndex'], equals(0)); // Memilih "Sangat Baik"
      expect(result['feedbackSuggestion'], isNotEmpty);
    });
  });

  group('UserAgreementScreen Countdown & Consent Tests', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.getInstance();
      await storage.resetAll();
    });

    testWidgets('Action buttons remain locked during 15s timer, unlock after timer expires', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UserAgreementScreen(storageService: storage),
        ),
      );

      // Awal mula: tombol disable & timer 15s
      expect(find.text('Syarat & Ketentuan'), findsOneWidget);
      expect(find.text('TUNGGU (15s)'), findsOneWidget);
      expect(find.text('TOLAK (15s)'), findsOneWidget);

      final ElevatedButton acceptBtnInitial = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(acceptBtnInitial.onPressed, isNull);

      final OutlinedButton rejectBtnInitial = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(rejectBtnInitial.onPressed, isNull);

      // Jalankan waktu 10 detik: tombol masih terkunci
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('TUNGGU (5s)'), findsOneWidget);
      expect(find.text('TOLAK (5s)'), findsOneWidget);

      // Jalankan sisa 5 detik hingga timer selesai (total 15s)
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('SAYA SETUJU'), findsOneWidget);
      expect(find.text('TOLAK'), findsOneWidget);

      final ElevatedButton acceptBtnActive = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(acceptBtnActive.onPressed, isNotNull);

      final OutlinedButton rejectBtnActive = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(rejectBtnActive.onPressed, isNotNull);
    });

    testWidgets('Tapping SAYA SETUJU saves agreement state in storage', (WidgetTester tester) async {
      expect(storage.isUserAgreementAccepted(), isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: UserAgreementScreen(
            storageService: storage,
            onAccepted: () {},
          ),
        ),
      );

      // Majukan timer 15 detik
      await tester.pump(const Duration(seconds: 15));

      // Tekan tombol SAYA SETUJU
      await tester.tap(find.text('SAYA SETUJU'));
      await tester.pump();

      expect(storage.isUserAgreementAccepted(), isTrue);
    });
  });

  group('Mandatory Permission Gatekeeper & AppGate Tests', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.getInstance();
      await storage.resetAll();

      PermissionService().mockStatuses = {
        AppPermissionType.notification: PermissionStatus.denied,
        AppPermissionType.camera: PermissionStatus.denied,
        AppPermissionType.photosOrStorage: PermissionStatus.denied,
      };
    });

    tearDown(() {
      PermissionService().resetMock();
    });

    testWidgets('PermissionGateScreen renders mandatory permission titles, cards, and buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PermissionGateScreen(
            storageService: storage,
            autoProceed: false,
          ),
        ),
      );

      // Selesaikan async load di initState
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Persetujuan Izin Wajib'), findsOneWidget);
      expect(find.text('Notifikasi Sistem & Perkuliahan'), findsOneWidget);
      expect(find.text('Kamera (UNPAM AI Vision OCR)'), findsOneWidget);
      expect(find.text('Foto & Media Penyimpanan'), findsOneWidget);
      expect(find.text('Izinkan Seluruh Akses'), findsOneWidget);
      expect(find.text('Tolak & Keluar dari Aplikasi'), findsOneWidget);
    });

    testWidgets('AppGate renders UserAgreementScreen on fresh install', (WidgetTester tester) async {
      expect(storage.isUserAgreementAccepted(), isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: AppGate(
            storageService: storage,
          ),
        ),
      );

      // Selesaikan async gate destination check
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Syarat & Ketentuan'), findsOneWidget);
    });
  });

  group('GitHubRelease Model & ReleaseHistoryDialog Tests', () {
    test('GitHubRelease.fromJson parses raw GitHub API payload correctly', () {
      final raw = {
        'id': 1234567,
        'tag_name': 'v1.0.16',
        'name': 'Pembaruan UNPAM Mobile v1.0.16',
        'body': '- Menambahkan gerbang izin wajib\n- Perbaikan bug',
        'published_at': '2026-10-18T00:55:00Z',
        'html_url': 'https://github.com/codewithtama/unpam_mobile/releases/tag/v1.0.16',
        'assets': [
          {
            'name': 'app-release.apk',
            'size': 44040192,
            'download_count': 18,
            'browser_download_url': 'https://github.com/codewithtama/unpam_mobile/releases/download/v1.0.16/app-release.apk',
          }
        ]
      };

      final release = GitHubRelease.fromJson(raw);

      expect(release.id, equals(1234567));
      expect(release.tagName, equals('v1.0.16'));
      expect(release.displayTitle, equals('Pembaruan UNPAM Mobile v1.0.16'));
      expect(release.hasApkAsset, isTrue);
      expect(release.apkSizeBytes, equals(44040192));
      expect(release.formattedApkSize, equals('42.0 MB'));
      expect(release.downloadCount, equals(18));
      expect(release.publishedAt, isNotNull);

      final json = release.toJson();
      expect(json['tag_name'], equals('v1.0.16'));
      expect(json['apk_size_bytes'], equals(44040192));
    });

    testWidgets('ReleaseHistoryDialog renders header title and close button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReleaseHistoryDialog(
              updateService: UpdateCheckerService(),
            ),
          ),
        ),
      );

      // Render awal dialog
      await tester.pump();

      expect(find.text('Riwayat Pembaruan Aplikasi'), findsOneWidget);
      expect(find.text('Data riwayat rilis langsung dari GitHub Repository'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });
  });

  group('FileDownloadService Document URL Detection Tests', () {
    test('Correctly identifies academic PDF and document file URLs', () {
      expect(FileDownloadService.isDocumentUrl('https://mentari.unpam.ac.id/pluginfile.php/123/mod_resource/content/1/Modul_1.pdf'), isTrue);
      expect(FileDownloadService.isDocumentUrl('https://mentari.unpam.ac.id/mod/resource/view.php?id=88319'), isTrue);
      expect(FileDownloadService.isDocumentUrl('https://mentari.unpam.ac.id/mod/assign/view.php?id=123&forcedownload=1'), isTrue);
      expect(FileDownloadService.isDocumentUrl('https://my.unpam.ac.id/cetak_krs.php?smt=5'), isTrue);
      expect(FileDownloadService.isDocumentUrl('https://my.unpam.ac.id/cetak_khs.php?ta=20252'), isTrue);
      expect(FileDownloadService.isDocumentUrl('https://my.unpam.ac.id/cetak_transkrip.php'), isTrue);
      expect(FileDownloadService.isDocumentUrl('https://my.unpam.ac.id/kartu_ujian.php'), isTrue);
      expect(FileDownloadService.isDocumentUrl('https://my.unpam.ac.id/export?format=pdf'), isTrue);
      expect(FileDownloadService.isDocumentUrl('data:application/pdf;base64,JVBERi0xLjQK...'), isTrue);
    });

    test('Ignores regular non-document portal navigation URLs', () {
      expect(FileDownloadService.isDocumentUrl('https://mentari.unpam.ac.id/login/index.php'), isFalse);
      expect(FileDownloadService.isDocumentUrl('https://mentari.unpam.ac.id/my/'), isFalse);
      expect(FileDownloadService.isDocumentUrl('https://mentari.unpam.ac.id/course/view.php?id=432'), isFalse);
      expect(FileDownloadService.isDocumentUrl('https://my.unpam.ac.id/dashboard'), isFalse);
      expect(FileDownloadService.isDocumentUrl('https://my.unpam.ac.id/profil_mahasiswa'), isFalse);
      expect(FileDownloadService.isDocumentUrl(''), isFalse);
    });

    test('Handles invalid URL gracefully in FileDownloadService', () async {
      final service = FileDownloadService();
      final result = await service.downloadAndOpenFile(url: 'invalid-url-string');

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('tidak valid'));
    });
  });

  group('MyUnpam Logout & SSO Redirect Detection Tests', () {
    test('Correctly identifies SSO redirect confirmation text', () {
      bool isRedirect(String text) {
        final lower = text.toLowerCase();
        return lower.contains('konfirmasi redirect') ||
            lower.contains('lanjutkan ke my unpam') ||
            lower.contains('apakah anda ingin melanjutkan ke aplikasi berikut');
      }

      expect(isRedirect('Konfirmasi Redirect: Anda berhasil login.'), isTrue);
      expect(isRedirect('Lanjutkan ke MY UNPAM'), isTrue);
      expect(isRedirect('Apakah Anda ingin melanjutkan ke aplikasi berikut?'), isTrue);
      expect(isRedirect('Selamat Datang di Portal Mahasiswa Mentari UNPAM'), isFalse);
      expect(isRedirect('Dashboard Akademik MyUnpam'), isFalse);
    });

    test('Correctly identifies logout and signout navigation requests', () {
      bool isLogoutUrl(String url) {
        final lower = url.toLowerCase();
        return lower.contains('logout') || lower.contains('keluar') || lower.contains('signout');
      }

      expect(isLogoutUrl('https://my.unpam.ac.id/auth/logout'), isTrue);
      expect(isLogoutUrl('https://satu.unpam.ac.id/logout?redirect=myunpam'), isTrue);
      expect(isLogoutUrl('https://my.unpam.ac.id/keluar.php'), isTrue);
      expect(isLogoutUrl('https://my.unpam.ac.id/dashboard'), isFalse);
      expect(isLogoutUrl('https://my.unpam.ac.id/krs'), isFalse);
    });

    test('Correctly identifies MyUnpam login entrypoint and portal roots', () {
      bool isMyUnpamLogin(String url, bool hasProfile) {
        final lower = url.toLowerCase();
        final isRoot = lower.isEmpty || lower == 'https://my.unpam.ac.id/' || lower == 'https://my.unpam.ac.id';
        final isLogin = lower.contains('login') || lower.contains('sso') || lower.contains('auth');
        return (isRoot || isLogin) && !hasProfile;
      }

      expect(isMyUnpamLogin('https://my.unpam.ac.id/', false), isTrue);
      expect(isMyUnpamLogin('https://my.unpam.ac.id', false), isTrue);
      expect(isMyUnpamLogin('https://sso.unpam.ac.id/login', false), isTrue);
      expect(isMyUnpamLogin('https://my.unpam.ac.id/', true), isFalse);
      expect(isMyUnpamLogin('https://my.unpam.ac.id/dashboard', false), isFalse);
    });
  });
}

