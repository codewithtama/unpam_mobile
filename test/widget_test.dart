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
import 'package:unpam_mobile/widgets/update_dialog.dart';
import 'package:unpam_mobile/core/services/file_download_service.dart';
import 'package:unpam_mobile/core/services/webview_download_bridge.dart';
import 'package:unpam_mobile/models/app_update_info.dart';
import 'package:unpam_mobile/features/schedule/domain/models/schedule_model.dart';

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
      expect(find.text('Kamera (The PAMs AI Vision OCR)'), findsOneWidget);
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

    test('GitHubRelease.selectBestApkAsset intelligently selects optimal split APK for device ABI', () {
      final assets = [
        {'name': 'app-armeabi-v7a-release.apk', 'browser_download_url': 'https://download/armeabi-v7a.apk', 'size': 17112000},
        {'name': 'app-arm64-v8a-release.apk', 'browser_download_url': 'https://download/arm64-v8a.apk', 'size': 19725000},
        {'name': 'app-x86_64-release.apk', 'browser_download_url': 'https://download/x86_64.apk', 'size': 21000000},
        {'name': 'app-release.apk', 'browser_download_url': 'https://download/universal.apk', 'size': 57600000},
      ];

      // 1. Perangkat 64-bit modern (arm64-v8a) memilih app-arm64-v8a-release.apk (~19MB)
      final arm64Choice = GitHubRelease.selectBestApkAsset(assets, ['arm64-v8a', 'armeabi-v7a']);
      expect(arm64Choice?['name'], equals('app-arm64-v8a-release.apk'));
      expect(arm64Choice?['size'], equals(19725000));

      // 2. Perangkat 32-bit (armeabi-v7a) memilih app-armeabi-v7a-release.apk (~17MB)
      final armV7Choice = GitHubRelease.selectBestApkAsset(assets, ['armeabi-v7a', 'armeabi']);
      expect(armV7Choice?['name'], equals('app-armeabi-v7a-release.apk'));

      // 3. Emulator x86_64 memilih app-x86_64-release.apk (~21MB)
      final x86Choice = GitHubRelease.selectBestApkAsset(assets, ['x86_64']);
      expect(x86Choice?['name'], equals('app-x86_64-release.apk'));

      // 4. Default tanpa parameter ABI memilih arm64-v8a
      final defaultChoice = GitHubRelease.selectBestApkAsset(assets);
      expect(defaultChoice?['name'], equals('app-arm64-v8a-release.apk'));
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
      expect(FileDownloadService.isDocumentUrl('https://my.unpam.ac.id/cetak_uts'), isTrue);
      expect(FileDownloadService.isDocumentUrl('https://my.unpam.ac.id/cetak_uas'), isTrue);
      expect(FileDownloadService.isDocumentUrl('https://my.unpam.ac.id/kartu_uts'), isTrue);
      expect(FileDownloadService.isDocumentUrl('https://my.unpam.ac.id/jadwal_ujian/cetak'), isTrue);
      expect(FileDownloadService.isDocumentUrl('https://my.unpam.ac.id/uts/cetak'), isTrue);
      expect(FileDownloadService.isDocumentUrl('https://my.unpam.ac.id/dokumen.pdf?token=123'), isTrue);
      expect(FileDownloadService.isDocumentUrl('https://my.unpam.ac.id/export?format=pdf'), isTrue);
      expect(FileDownloadService.isDocumentUrl('data:application/pdf;base64,JVBERi0xLjQK...'), isTrue);
      expect(FileDownloadService.isDocumentUrl('blob:https://my.unpam.ac.id/a1f49c6f-f06b-47c0-8e40-71450a1b2e46'), isTrue);
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

      final blobResult = await service.downloadAndOpenFile(url: 'blob:https://my.unpam.ac.id/1234');
      expect(blobResult.isSuccess, isFalse);
      expect(blobResult.errorMessage, contains('tidak dapat diakses'));
    });

    test('resolveFileName correctly decodes UTF-8 and standard Content-Disposition', () {
      final service = FileDownloadService();

      final utf8Name = service.resolveFileName(
        url: 'https://mentari.unpam.ac.id/mod/resource/view.php?id=123',
        contentDisposition: "attachment; filename*=UTF-8''Modul_Pertemuan_01_AI.pdf",
        isPdf: true,
      );
      expect(utf8Name, equals('Modul_Pertemuan_01_AI.pdf'));

      final standardName = service.resolveFileName(
        url: 'https://my.unpam.ac.id/cetak_krs.php',
        contentDisposition: 'attachment; filename="Cetak_KRS_Semester_5.pdf"',
        isPdf: true,
      );
      expect(standardName, equals('Cetak_KRS_Semester_5.pdf'));

      final contextualKrs = service.resolveFileName(
        url: 'https://my.unpam.ac.id/krs/cetak',
        isPdf: true,
      );
      expect(contextualKrs, startsWith('Cetak_KRS_ThePAMs_'));
      expect(contextualKrs, endsWith('.pdf'));

      final contextualUts = service.resolveFileName(
        url: 'https://my.unpam.ac.id/cetak_uts',
        isPdf: true,
      );
      expect(contextualUts, startsWith('Kartu_UTS_ThePAMs_'));
      expect(contextualUts, endsWith('.pdf'));
    });

    test('WebViewDownloadBridge validates payload channel name and handles malformed messages safely', () async {
      expect(WebViewDownloadBridge.channelName, equals('CampusDownloadPayloadChannel'));

      final bridge = WebViewDownloadBridge();
      // Verifikasi penanganan payload rusak tanpa melempar exception
      await bridge.handlePayloadMessage('invalid json {');
      await bridge.handlePayloadMessage('{}');
      await bridge.handlePayloadMessage('{"id":"non-existent","type":"chunk"}');
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

  group('AppUpdateInfo & OTA Notification Serialization Tests', () {
    test('AppUpdateInfo correctly serializes to and from JSON', () {
      final original = AppUpdateInfo(
        currentVersion: '1.0.18',
        latestVersion: 'v1.0.19',
        releaseTitle: 'Pembaruan UNPAM Mobile v1.0.19',
        changelog: 'Perbaikan notifikasi popup otomatis dan OTA dialog',
        apkDownloadUrl: 'https://github.com/codewithtama/unpam_mobile/releases/download/v1.0.19/app-release.apk',
        apkSizeBytes: 44040192,
        publishedAt: DateTime(2026, 10, 18, 2, 0),
        hasUpdate: true,
      );

      final json = original.toJson();
      expect(json['currentVersion'], equals('1.0.18'));
      expect(json['latestVersion'], equals('v1.0.19'));
      expect(json['hasUpdate'], isTrue);

      final restored = AppUpdateInfo.fromJson(json);
      expect(restored.currentVersion, equals(original.currentVersion));
      expect(restored.latestVersion, equals(original.latestVersion));
      expect(restored.releaseTitle, equals(original.releaseTitle));
      expect(restored.changelog, equals(original.changelog));
      expect(restored.apkDownloadUrl, equals(original.apkDownloadUrl));
      expect(restored.apkSizeBytes, equals(original.apkSizeBytes));
      expect(restored.formattedApkSize, equals('42.0 MB'));
      expect(restored.hasUpdate, isTrue);
    });

    test('AppUpdateInfo.isNewerVersion handles semver formats and prefixes accurately', () {
      // Versi baru lebih tinggi
      expect(AppUpdateInfo.isNewerVersion('v1.0.19', '1.0.18'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('1.0.19', '1.0.18+19'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('v1.1.0', '1.0.18'), isTrue);
      expect(AppUpdateInfo.isNewerVersion('2.0.0', '1.9.9'), isTrue);

      // Versi sama
      expect(AppUpdateInfo.isNewerVersion('v1.0.18', '1.0.18'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('1.0.18+19', '1.0.18'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('1.0.18', '1.0.18'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('v1.0.37', '1.0.37+37'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('v1.0.37-release', '1.0.37'), isFalse);

      // Versi lama lebih rendah
      expect(AppUpdateInfo.isNewerVersion('v1.0.9', '1.0.10'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('v1.0.17', '1.0.18'), isFalse);
      expect(AppUpdateInfo.isNewerVersion('v1.0.36', '1.0.37'), isFalse);
    });

    testWidgets('UpdateDialog.show does not launch when hasUpdate is false', (WidgetTester tester) async {
      const info = AppUpdateInfo(
        currentVersion: '1.0.37',
        latestVersion: 'v1.0.37',
        releaseTitle: 'Release v1.0.37',
        changelog: 'None',
        apkDownloadUrl: '',
        apkSizeBytes: 0,
        hasUpdate: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  final result = UpdateDialog.show(
                    context: context,
                    updateInfo: info,
                    updateService: UpdateCheckerService(),
                  );
                  expect(result, isNull);
                },
                child: const Text('Check'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(find.text('Pembaruan Tersedia!'), findsNothing);
    });
  });

  group('MyUnpam Schedule API Parser Tests', () {
    test('Parses raw MyUnpam /api/jadwal-kuliah payload correctly', () {
      const rawApiJson = '''
      {
        "mahasiswa": {
          "nama_mahasiswa": "DIMAS ALFA PRATAMA",
          "nim": "241011750041"
        },
        "jadwal": [
          {
            "id_semester_registrasi": "20261",
            "id_dosen": "02985",
            "id_ruang": "V.906",
            "id_kelas": "04SIFE001",
            "id_periode": "1",
            "id_waktu_kuliah": "E616",
            "id_mata_kuliah": "22SIF0173",
            "ruang": "V-V.906",
            "nama_mata_kuliah": "JARINGAN KOMPUTER",
            "waktu_kuliah": {
              "ket_jam": "07.40 - 09.20",
              "hari": {
                "id_hari_waktu_kuliah": "6",
                "nama_hari": "Sabtu"
              }
            },
            "dosen": {
              "nama_gelar_dosen": "GUSMAYENI, S.Kom., M.Kom."
            }
          },
          {
            "id_mata_kuliah": "22SIF0242",
            "ruang": "V-V.906",
            "nama_mata_kuliah": "MOBILE PROGRAMMING",
            "waktu_kuliah": {
              "ket_jam": "13.50 - 15.30",
              "hari": {
                "id_hari_waktu_kuliah": "6",
                "nama_hari": "Sabtu"
              }
            },
            "dosen": {
              "nama_gelar_dosen": "SAMSO SUPRIYATNA, S.Kom., M.Kom."
            }
          }
        ]
      }
      ''';

      final schedules = CourseSchedule.listFromJson(rawApiJson);
      expect(schedules.length, equals(2));

      final first = schedules[0];
      expect(first.namaMataKuliah, equals('JARINGAN KOMPUTER'));
      expect(first.kode, equals('22SIF0173'));
      expect(first.hari, equals('Sabtu'));
      expect(first.hariIndex, equals(6));
      expect(first.jamMulai, equals('07:40'));
      expect(first.jamSelesai, equals('09:20'));
      expect(first.ruang, equals('V-V.906'));
      expect(first.dosen, equals('GUSMAYENI, S.Kom., M.Kom.'));

      final second = schedules[1];
      expect(second.namaMataKuliah, equals('MOBILE PROGRAMMING'));
      expect(second.jamMulai, equals('13:50'));
      expect(second.jamSelesai, equals('15:30'));
    });
  });
}

