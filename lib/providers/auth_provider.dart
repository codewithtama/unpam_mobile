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
  String get studentName {
    final name = _storage.getStudentName();
    return name.isNotEmpty ? name : _storage.getNim();
  }

  Future<bool> loginWithToken(String token, {String? cookies}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.loginWithToken(token, cookies: cookies);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _storage.clearSession();
    notifyListeners();
  }
}
