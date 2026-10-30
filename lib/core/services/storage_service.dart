import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../../models/ai_model_config.dart';

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

  String? _readString(String key) {
    final value = _preferences?.getString(key);
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> _writeString(String key, String? value) async {
    if (value == null || value.isEmpty) {
      await _preferences?.remove(key);
    } else {
      await _preferences?.setString(key, value);
    }
  }

  Future<void> saveSatuUnpamToken(String token) =>
      _writeString(ApiConstants.satuUnpamTokenKey, token.trim());

  String? getSatuUnpamToken() => _readString(ApiConstants.satuUnpamTokenKey);

  Future<void> saveSatuUnpamCookies(String cookies) =>
      _writeString(ApiConstants.satuUnpamCookiesKey, cookies);

  String? getSatuUnpamCookies() => _readString(ApiConstants.satuUnpamCookiesKey);

  Future<void> saveMyUnpamToken(String token) =>
      _writeString(ApiConstants.myUnpamTokenKey, token.trim());

  String? getMyUnpamToken() => _readString(ApiConstants.myUnpamTokenKey);

  bool get hasMyUnpamToken => getMyUnpamToken() != null;

  Future<void> saveMyUnpamCookies(String cookies) =>
      _writeString(ApiConstants.myUnpamCookiesKey, cookies);

  String? getMyUnpamCookies() => _readString(ApiConstants.myUnpamCookiesKey);

  Future<void> clearPortalSessions() async {
    for (final key in const [
      ApiConstants.satuUnpamTokenKey,
      ApiConstants.satuUnpamCookiesKey,
      ApiConstants.myUnpamTokenKey,
      ApiConstants.myUnpamCookiesKey,
    ]) {
      await _preferences?.remove(key);
    }
  }

  Future<void> clearPortalCache() async {
    for (final key in ApiConstants.myUnpamCacheKeys) {
      await _preferences?.remove(key);
    }
  }

  String? getCachedJson(String key) => _readString(key);

  Future<void> saveCachedJson(String key, String json) => _writeString(key, json);

  Future<void> saveCachedFinanceData(String json) =>
      _writeString(ApiConstants.myUnpamCachedKeuanganKey, json);

  String? getCachedFinanceData() => _readString(ApiConstants.myUnpamCachedKeuanganKey);

  Future<void> saveCachedSemesters(String json) =>
      _writeString(ApiConstants.myUnpamCachedSemestersListKey, json);

  String? getCachedSemesters() => _readString(ApiConstants.myUnpamCachedSemestersListKey);

  Future<void> saveSelectedSemester(String semester) =>
      _writeString(ApiConstants.myUnpamCachedSemesterKey, semester);

  String? getSelectedSemester() => _readString(ApiConstants.myUnpamCachedSemesterKey);

  // Mentari LMS Session & Cache
  Future<void> saveMentariSesskey(String sesskey) =>
      _writeString(ApiConstants.mentariSesskeyKey, sesskey.trim());

  String? getMentariSesskey() => _readString(ApiConstants.mentariSesskeyKey);

  Future<void> saveMentariCachedCourses(String json) =>
      _writeString(ApiConstants.mentariCachedCoursesKey, json);

  String? getMentariCachedCourses() => _readString(ApiConstants.mentariCachedCoursesKey);

  Future<void> saveMentariCachedCourseDetail(int courseId, String json) =>
      _writeString('${ApiConstants.mentariCachedCourseDetailPrefix}$courseId', json);

  String? getMentariCachedCourseDetail(int courseId) =>
      _readString('${ApiConstants.mentariCachedCourseDetailPrefix}$courseId');

  // Active AI Model Selection
  Future<void> saveActiveAiModelId(String modelId) async {
    await _preferences?.setString(ApiConstants.activeAiModelKey, modelId);
  }

  String getActiveAiModelId() {
    final stored = _preferences?.getString(ApiConstants.activeAiModelKey);
    if (stored != null && stored.isNotEmpty) return stored;

    // Fallback default: jika ada key Gemini, gunakan Gemini; selain itu gunakan free_cloud
    if (getGeminiApiKey() != null) return 'gemini';
    return 'free_cloud';
  }

  // Multi-Provider AI API Keys
  Future<void> saveProviderApiKey(AiProviderType provider, String key) async {
    final cleanKey = key.trim();
    final prefKey = _getPrefKeyForProvider(provider);
    if (prefKey == null) return;

    if (cleanKey.isEmpty) {
      await _preferences?.remove(prefKey);
    } else {
      await _preferences?.setString(prefKey, cleanKey);
    }
  }

  String? getProviderApiKey(AiProviderType provider) {
    final prefKey = _getPrefKeyForProvider(provider);
    if (prefKey == null) return null;
    final key = _preferences?.getString(prefKey);
    return (key != null && key.isNotEmpty) ? key : null;
  }

  bool hasProviderApiKey(AiProviderType provider) {
    if (provider == AiProviderType.freeCloud) return true;
    return getProviderApiKey(provider) != null;
  }

  Future<void> clearProviderApiKey(AiProviderType provider) async {
    final prefKey = _getPrefKeyForProvider(provider);
    if (prefKey != null) {
      await _preferences?.remove(prefKey);
    }
  }

  String? _getPrefKeyForProvider(AiProviderType provider) {
    switch (provider) {
      case AiProviderType.gemini:
        return ApiConstants.geminiApiKey;
      case AiProviderType.deepseek:
        return ApiConstants.deepseekApiKey;
      case AiProviderType.claude:
        return ApiConstants.claudeApiKey;
      case AiProviderType.qwen:
        return ApiConstants.qwenApiKey;
      case AiProviderType.openai:
        return ApiConstants.openaiApiKey;
      case AiProviderType.openrouter:
        return ApiConstants.openrouterApiKey;
      case AiProviderType.freeCloud:
        return null;
    }
  }

  // Backward compatibility methods for Gemini
  Future<void> saveGeminiApiKey(String apiKey) async {
    await saveProviderApiKey(AiProviderType.gemini, apiKey);
  }

  String? getGeminiApiKey() {
    return getProviderApiKey(AiProviderType.gemini);
  }

  Future<void> clearSession() async {
    await _preferences?.remove(ApiConstants.tokenKey);
    await _preferences?.remove(ApiConstants.cookiesKey);
    await clearPortalSessions();
    await clearPortalCache();
  }

  Future<void> setUserAgreementAccepted(bool accepted) async {
    await _preferences?.setBool(ApiConstants.userAgreementKey, accepted);
  }

  bool isUserAgreementAccepted() {
    return _preferences?.getBool(ApiConstants.userAgreementKey) ?? false;
  }

  Future<void> setAccountOnboardingDone(bool done) async {
    await _preferences?.setBool(ApiConstants.accountOnboardingDoneKey, done);
  }

  bool isAccountOnboardingDone() {
    return _preferences?.getBool(ApiConstants.accountOnboardingDoneKey) ?? false;
  }

  Future<void> resetAll() async {
    await _preferences?.clear();
  }
}
