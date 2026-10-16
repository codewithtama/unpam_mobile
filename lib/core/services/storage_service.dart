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

  SharedPreferences get rawPreferences => _preferences!;

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

  Future<void> saveCookies(String cookies) async {
    await _preferences?.setString(ApiConstants.cookiesKey, cookies);
  }

  String? getCookies() {
    return _preferences?.getString(ApiConstants.cookiesKey);
  }

  Future<void> saveGeminiApiKey(String apiKey) async {
    await _preferences?.setString(ApiConstants.geminiApiKey, apiKey.trim());
  }

  String? getGeminiApiKey() {
    final stored = _preferences?.getString(ApiConstants.geminiApiKey);
    if (stored != null && stored.isNotEmpty) return stored;
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    return envKey.isNotEmpty ? envKey : null;
  }

  Future<void> clearSession() async {
    await _preferences?.remove(ApiConstants.tokenKey);
    await _preferences?.remove(ApiConstants.cookiesKey);
  }

  Future<void> setUserAgreementAccepted(bool accepted) async {
    await _preferences?.setBool(ApiConstants.userAgreementKey, accepted);
  }

  bool isUserAgreementAccepted() {
    return _preferences?.getBool(ApiConstants.userAgreementKey) ?? false;
  }

  Future<void> resetAll() async {
    await _preferences?.clear();
  }
}
