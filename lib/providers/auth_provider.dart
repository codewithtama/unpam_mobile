import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';
import '../core/network/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final StorageService _storage;
  final ApiClient _apiClient;

  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._storage, this._apiClient);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _storage.hasToken;
  String get studentNim => _storage.getNim();
  String get studentName => _storage.getStudentName();
  bool get isMockMode => _storage.isUseMock();
  String? get currentToken => _storage.getToken();

  Future<bool> login({
    required String nim,
    required String password,
    String? manualBearerToken,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiClient.login(
        nim: nim,
        password: password,
        manualBearerToken: manualBearerToken,
      );
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal masuk: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clearSession();
    notifyListeners();
  }

  Future<void> toggleMockMode(bool val) async {
    await _storage.setUseMock(val);
    notifyListeners();
  }
}
