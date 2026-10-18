import 'package:flutter/material.dart';
import '../core/services/biometric_auth_service.dart';

class BiometricProvider extends ChangeNotifier {
  final BiometricAuthService _service;

  bool _isAvailable = false;
  bool _hasSavedCredentials = false;
  String? _savedNim;
  bool _isAutoLoginEnabled = true;
  bool _isPromptDismissed = false;
  bool _isLoading = false;

  BiometricProvider(this._service) {
    _init();
  }

  bool get isAvailable => _isAvailable;
  bool get hasSavedCredentials => _hasSavedCredentials;
  String? get savedNim => _savedNim;
  bool get isAutoLoginEnabled => _isAutoLoginEnabled;
  bool get isPromptDismissed => _isPromptDismissed;
  bool get isLoading => _isLoading;

  Future<void> _init() async {
    _isAvailable = await _service.canAuthenticateWithBiometrics();
    _hasSavedCredentials = await _service.hasSavedCredentials();
    _savedNim = await _service.getSavedNim();
    _isAutoLoginEnabled = _service.isAutoLoginEnabled();
    _isPromptDismissed = _service.isBiometricPromptDismissed();
    notifyListeners();
  }

  Future<void> refreshState() async {
    await _init();
  }

  Future<bool> saveCredentials({
    required String nim,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final authenticated = await _service.authenticate(
        localizedReason: 'Konfirmasi sidik jari untuk menyimpan kredensial akun.',
      );
      if (!authenticated) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _service.saveCredentials(nim: nim, password: password);
      await _init();
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, String>?> getCredentialsForLogin() async {
    return await _service.getCredentialsWithBiometric();
  }

  Future<void> clearCredentials() async {
    _isLoading = true;
    notifyListeners();
    await _service.clearCredentials();
    await _init();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setAutoLoginEnabled(bool enabled) async {
    _isAutoLoginEnabled = enabled;
    await _service.setAutoLoginEnabled(enabled);
    notifyListeners();
  }

  Future<void> setPromptDismissed(bool dismissed) async {
    _isPromptDismissed = dismissed;
    await _service.setBiometricPromptDismissed(dismissed);
    notifyListeners();
  }
}
