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

  Future<void> saveStudentInfo({
    required String nim,
    required String name,
  }) async {
    await _preferences?.setString(ApiConstants.nimKey, nim);
    await _preferences?.setString(ApiConstants.studentNameKey, name);
  }

  String getNim() {
    return _preferences?.getString(ApiConstants.nimKey) ?? '';
  }

  String getStudentName() {
    return _preferences?.getString(ApiConstants.studentNameKey) ?? '';
  }

  Future<void> clearSession() async {
    await _preferences?.remove(ApiConstants.tokenKey);
    await _preferences?.remove(ApiConstants.nimKey);
    await _preferences?.remove(ApiConstants.studentNameKey);
  }
}
