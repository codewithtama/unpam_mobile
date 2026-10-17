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

    final stored = _preferences?.getString(prefKey);
    if (stored != null && stored.isNotEmpty) return stored;

    // Optional environment variables fallback
    switch (provider) {
      case AiProviderType.gemini:
        const envKey = String.fromEnvironment('GEMINI_API_KEY');
        return envKey.isNotEmpty ? envKey : null;
      case AiProviderType.deepseek:
        const envKey = String.fromEnvironment('DEEPSEEK_API_KEY');
        return envKey.isNotEmpty ? envKey : null;
      case AiProviderType.claude:
        const envKey = String.fromEnvironment('CLAUDE_API_KEY');
        return envKey.isNotEmpty ? envKey : null;
      case AiProviderType.qwen:
        const envKey = String.fromEnvironment('QWEN_API_KEY');
        return envKey.isNotEmpty ? envKey : null;
      case AiProviderType.openai:
        const envKey = String.fromEnvironment('OPENAI_API_KEY');
        return envKey.isNotEmpty ? envKey : null;
      case AiProviderType.openrouter:
        const envKey = String.fromEnvironment('OPENROUTER_API_KEY');
        return envKey.isNotEmpty ? envKey : null;
      case AiProviderType.freeCloud:
        return null;
    }
  }

  bool hasProviderApiKey(AiProviderType provider) {
    if (provider == AiProviderType.freeCloud) return true;
    final key = getProviderApiKey(provider);
    return key != null && key.isNotEmpty;
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
