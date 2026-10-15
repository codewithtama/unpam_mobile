import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _preferences;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _preferences = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // Token Management
  Future<void> saveToken(String token) async {
    await _preferences?.setString(ApiConstants.tokenKey, token);
  }

  String? getToken() {
    return _preferences?.getString(ApiConstants.tokenKey);
  }

  bool get hasToken {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }

  // Student Info Management
  Future<void> saveStudentInfo({
    required String nim,
    required String name,
  }) async {
    await _preferences?.setString(ApiConstants.nimKey, nim);
    await _preferences?.setString(ApiConstants.studentNameKey, name);
  }

  String getNim() {
    return _preferences?.getString(ApiConstants.nimKey) ?? ApiConstants.defaultNim;
  }

  String getStudentName() {
    return _preferences?.getString(ApiConstants.studentNameKey) ?? ApiConstants.defaultNama;
  }

  // Mock / Demo Mode Switcher
  Future<void> setUseMock(bool useMock) async {
    await _preferences?.setBool(ApiConstants.useMockKey, useMock);
  }

  bool isUseMock() {
    return _preferences?.getBool(ApiConstants.useMockKey) ?? true;
  }

  // Clear Session (Logout)
  Future<void> clearSession() async {
    await _preferences?.remove(ApiConstants.tokenKey);
    await _preferences?.remove(ApiConstants.nimKey);
    await _preferences?.remove(ApiConstants.studentNameKey);
  }
}
