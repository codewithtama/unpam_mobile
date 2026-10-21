import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unpam_mobile/core/services/biometric_auth_service.dart';
import 'package:unpam_mobile/core/services/my_unpam_session.dart';
import 'package:unpam_mobile/core/services/storage_service.dart';
import 'package:unpam_mobile/providers/biometric_provider.dart';
import 'package:unpam_mobile/screens/account_onboarding_screen.dart';

class _FakeBiometricService extends BiometricAuthService {
  _FakeBiometricService(SharedPreferences prefs) : super(prefs: prefs);

  @override
  Future<bool> canAuthenticateWithBiometrics() async => false;

  @override
  Future<bool> hasSavedCredentials() async => false;

  @override
  Future<String?> getSavedNim() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.getInstance();
    await storage.resetAll();
  });

  group('AccountOnboardingScreen.shouldShow', () {
    test('shows for a fresh install', () async {
      expect(await AccountOnboardingScreen.shouldShow(storage), isTrue);
    });

    test('is skipped once onboarding is done', () async {
      await storage.setAccountOnboardingDone(true);
      expect(await AccountOnboardingScreen.shouldShow(storage), isFalse);
    });

    test('existing users with a My UNPAM session are not forced through it', () async {
      await storage.saveMyUnpamToken('existing-token-abcdefghijklmnop');
      expect(await AccountOnboardingScreen.shouldShow(storage), isFalse);
      expect(storage.isAccountOnboardingDone(), isTrue);
    });
  });

  Future<MyUnpamSession> pumpOnboarding(WidgetTester tester, {VoidCallback? onFinished}) async {
    final session = MyUnpamSession(storage);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: session),
          ChangeNotifierProvider(
            create: (_) => BiometricProvider(_FakeBiometricService(storage.rawPreferences)),
          ),
        ],
        child: MaterialApp(
          home: AccountOnboardingScreen(storageService: storage, onFinished: onFinished),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return session;
  }

  testWidgets('validates empty NIM and password', (tester) async {
    await pumpOnboarding(tester);

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    expect(find.text('NIM wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
  });

  testWidgets('keeps credentials in memory only and moves to the My UNPAM step', (tester) async {
    final session = await pumpOnboarding(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'NIM'), '241011000001');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'rahasia123');
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    expect(session.rememberedCredentials, ('241011000001', 'rahasia123'));
    expect(
      storage.rawPreferences.getKeys().any((k) => storage.rawPreferences.get(k) == 'rahasia123'),
      isFalse,
    );
    expect(find.text('Hubungkan Sekarang'), findsOneWidget);
  });

  testWidgets('"Nanti saja" marks onboarding done', (tester) async {
    var finished = false;
    await pumpOnboarding(tester, onFinished: () => finished = true);

    await tester.tap(find.text('Nanti saja'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    expect(storage.isAccountOnboardingDone(), isTrue);
  });
}
