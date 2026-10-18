import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  BiometricAuthService({
    required SharedPreferences prefs,
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  })  : _prefs = prefs,
        _localAuth = localAuth ?? LocalAuthentication(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Memeriksa ketersediaan sensor biometrik (Fingerprint/Face) pada perangkat
  Future<bool> canAuthenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Mendapatkan daftar biometrik yang didukung pada perangkat
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return const <BiometricType>[];
    }
  }

  /// Melakukan otentikasi biometrik dengan dialog bawaan sistem operasi
  Future<bool> authenticate({
    String localizedReason =
        'Pindai sidik jari Anda untuk memverifikasi akun.',
  }) async {
    try {
      final available = await canAuthenticateWithBiometrics();
      if (!available) return false;

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Menyimpan kredensial NIM dan Password ke Secure Storage terenkripsi Keystore
  Future<void> saveCredentials({
    required String nim,
    required String password,
  }) async {
    final cleanNim = nim.trim();
    final cleanPass = password.trim();

    await _secureStorage.write(
      key: ApiConstants.secureNimKey,
      value: cleanNim,
    );
    await _secureStorage.write(
      key: ApiConstants.securePasswordKey,
      value: cleanPass,
    );

    // Aktifkan auto-login secara default saat menyimpan kredensial
    await setAutoLoginEnabled(true);
    await setBiometricPromptDismissed(false);
  }

  /// Memeriksa apakah kredensial telah tersimpan di Secure Storage
  Future<bool> hasSavedCredentials() async {
    try {
      final nim = await _secureStorage.read(key: ApiConstants.secureNimKey);
      final pass = await _secureStorage.read(key: ApiConstants.securePasswordKey);
      return nim != null && nim.isNotEmpty && pass != null && pass.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Membaca NIM tersimpan tanpa membuka password (aman untuk tampilan UI)
  Future<String?> getSavedNim() async {
    try {
      return await _secureStorage.read(key: ApiConstants.secureNimKey);
    } catch (_) {
      return null;
    }
  }

  /// Mengambil kredensial setelah lolos otentikasi biometrik
  Future<Map<String, String>?> getCredentialsWithBiometric({
    String reason = 'Otentikasi sidik jari untuk login otomatis ke portal Mentari.',
  }) async {
    final hasCreds = await hasSavedCredentials();
    if (!hasCreds) return null;

    final authenticated = await authenticate(localizedReason: reason);
    if (!authenticated) return null;

    final nim = await _secureStorage.read(key: ApiConstants.secureNimKey);
    final pass = await _secureStorage.read(key: ApiConstants.securePasswordKey);

    if (nim == null || pass == null || nim.isEmpty || pass.isEmpty) {
      return null;
    }

    return {
      'nim': nim,
      'password': pass,
    };
  }

  /// Menghapus kredensial tersimpan dari Secure Storage
  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: ApiConstants.secureNimKey);
    await _secureStorage.delete(key: ApiConstants.securePasswordKey);
    await setAutoLoginEnabled(false);
    await setBiometricPromptDismissed(false);
  }

  /// Pengaturan status auto-login
  bool isAutoLoginEnabled() {
    return _prefs.getBool(ApiConstants.biometricAutoLoginEnabledKey) ?? true;
  }

  Future<void> setAutoLoginEnabled(bool enabled) async {
    await _prefs.setBool(ApiConstants.biometricAutoLoginEnabledKey, enabled);
  }

  /// Memeriksa apakah user telah menolak pengingat aktivasi biometrik
  bool isBiometricPromptDismissed() {
    return _prefs.getBool(ApiConstants.biometricPromptDismissedKey) ?? false;
  }

  /// Mengatur preferensi penolakan prompt aktivasi biometrik
  Future<void> setBiometricPromptDismissed(bool dismissed) async {
    await _prefs.setBool(ApiConstants.biometricPromptDismissedKey, dismissed);
  }
}
