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

  static const String coursesCacheKey = 'unpam_courses_cache';

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

  Future<void> saveCookies(String cookies) async {
    await _preferences?.setString('unpam_cookies', cookies);
  }

  String? getCookies() {
    return _preferences?.getString('unpam_cookies');
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

  Future<void> saveCachedCourses(String jsonString) async {
    await _preferences?.setString(coursesCacheKey, jsonString);
  }

  String? getCachedCoursesRaw() {
    return _preferences?.getString(coursesCacheKey);
  }

  static String courseDetailKey(String kodeCourse) => 'unpam_course_detail_$kodeCourse';

  Future<void> saveCachedCourseDetail(String kodeCourse, String jsonString) async {
    await _preferences?.setString(courseDetailKey(kodeCourse), jsonString);
  }

  String? getCachedCourseDetailRaw(String kodeCourse) {
    return _preferences?.getString(courseDetailKey(kodeCourse));
  }

  Future<void> clearSession() async {
    final keys = _preferences?.getKeys() ?? {};
    for (final k in keys) {
      if (k.startsWith('unpam_course_detail_')) {
        await _preferences?.remove(k);
      }
    }
    await _preferences?.remove(ApiConstants.tokenKey);
    await _preferences?.remove(ApiConstants.nimKey);
    await _preferences?.remove(ApiConstants.studentNameKey);
    await _preferences?.remove('unpam_cookies');
    await _preferences?.remove(coursesCacheKey);
  }
}
