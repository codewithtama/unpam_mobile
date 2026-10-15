import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../../models/student_profile_model.dart';

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

  Future<void> saveStudentProfile(StudentProfile profile) async {
    await _preferences?.setString(ApiConstants.studentNameKey, profile.name);
    await _preferences?.setString(ApiConstants.nimKey, profile.nim);
    await _preferences?.setString(ApiConstants.prodiKey, profile.prodi);
    await _preferences?.setString(ApiConstants.fakultasKey, profile.fakultas);
    await _preferences?.setString(ApiConstants.kelasKey, profile.kelas);
    await _preferences?.setString(ApiConstants.shiftKey, profile.shift);
    await _preferences?.setString(ApiConstants.semesterKey, profile.semester);
    await _preferences?.setString(ApiConstants.emailKey, profile.email);
    await _preferences?.setString(ApiConstants.phoneKey, profile.phone);
    await _preferences?.setString(ApiConstants.statusKey, profile.status);
    await _preferences?.setString(ApiConstants.bioKey, profile.bio);
    await _preferences?.setString(
      ApiConstants.profileJsonKey,
      jsonEncode(profile.toJson()),
    );
  }

  StudentProfile getStudentProfile() {
    final rawJson = _preferences?.getString(ApiConstants.profileJsonKey);
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
        return StudentProfile.fromJson(decoded);
      } catch (_) {}
    }

    final name = _preferences?.getString(ApiConstants.studentNameKey);
    final nim = _preferences?.getString(ApiConstants.nimKey);
    if (name != null || nim != null) {
      return StudentProfile(
        name: (name != null && name.isNotEmpty) ? name : 'Tama Vernaldi',
        nim: (nim != null && nim.isNotEmpty) ? nim : '221011400123',
        prodi: _preferences?.getString(ApiConstants.prodiKey) ?? 'Teknik Informatika (S1)',
        fakultas: _preferences?.getString(ApiConstants.fakultasKey) ?? 'Fakultas Ilmu Komputer',
        kelas: _preferences?.getString(ApiConstants.kelasKey) ?? '04TPLP001',
        shift: _preferences?.getString(ApiConstants.shiftKey) ?? 'Reguler C (Malam)',
        semester: _preferences?.getString(ApiConstants.semesterKey) ?? 'Semester 4',
        email: _preferences?.getString(ApiConstants.emailKey) ?? 'tama@mahasiswa.unpam.ac.id',
        phone: _preferences?.getString(ApiConstants.phoneKey) ?? '081234567890',
        status: _preferences?.getString(ApiConstants.statusKey) ?? 'Mahasiswa Aktif',
        bio: _preferences?.getString(ApiConstants.bioKey) ??
            'Fokus Peminatan Mobile Application & Artificial Intelligence',
      );
    }
    return const StudentProfile();
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
    return _preferences?.getString(ApiConstants.nimKey) ??
        getStudentProfile().nim;
  }

  String getStudentName() {
    return _preferences?.getString(ApiConstants.studentNameKey) ??
        getStudentProfile().name;
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

  Future<void> clearSession() async {
    await _preferences?.remove(ApiConstants.tokenKey);
    await _preferences?.remove('unpam_cookies');
  }

  Future<void> resetAll() async {
    await _preferences?.clear();
  }
}
