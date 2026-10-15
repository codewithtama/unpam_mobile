import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../constants/api_constants.dart';
import '../services/storage_service.dart';
import '../../models/user_course_model.dart';
import '../../models/course_detail_model.dart';

class ApiClient {
  final Dio _dio = Dio();
  final StorageService _storage;

  ApiClient(this._storage) {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      },
    );

    // Auth Interceptor: Menambahkan Bearer Token dan Header Wajib Mentari & Sakura
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // Header Timestamp 't' & Referer yang dibutuhkan oleh API Mentari UNPAM
          final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          options.headers['t'] = timestamp;
          options.headers['Referer'] = 'https://mentari.unpam.ac.id/';
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Tangani 401 Unauthorized (Token Kadaluarsa)
          if (error.response?.statusCode == 401) {
            // Token expired -> Auto session invalidation
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Ambil Daftar Seluruh Mata Kuliah Mahasiswa (Mentari)
  Future<UserCourseResponse> getUserCourses({bool forceLive = false}) async {
    final useMock = _storage.isUseMock() && !forceLive;

    if (!useMock && _storage.hasToken) {
      try {
        final url = '${ApiConstants.mentariBaseUrl}${ApiConstants.userCourses}?page=1&limit=12&t=${DateTime.now().millisecondsSinceEpoch}';
        final response = await _dio.get(url);
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data is String ? jsonDecode(response.data) : response.data;
          return UserCourseResponse.fromJson(data as Map<String, dynamic>);
        }
      } catch (e) {
        // Fallback otomatis ke mock data jika koneksi gagal atau terhalang Cloudflare
      }
    }

    // Load dari Mock Asset JSON (Offline-first / Reliable Demo)
    final jsonString = await rootBundle.loadString(ApiConstants.mockUserCoursesPath);
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    return UserCourseResponse.fromJson(data);
  }

  /// Ambil Detail Pertemuan, Kuis, Materi & Peserta Kelas (Sakura)
  Future<CourseDetailResponse> getCourseDetail(String kodeCourse, {bool forceLive = false}) async {
    final useMock = _storage.isUseMock() && !forceLive;

    if (!useMock && _storage.hasToken) {
      try {
        final url = '${ApiConstants.sakuraBaseUrl}${ApiConstants.courseDetail(kodeCourse)}';
        final response = await _dio.get(url);
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data is String ? jsonDecode(response.data) : response.data;
          return CourseDetailResponse.fromJson(data as Map<String, dynamic>);
        }
      } catch (e) {
        // Fallback otomatis ke mock data jika live request bermasalah
      }
    }

    // Load dari Mock Asset JSON
    final jsonString = await rootBundle.loadString(ApiConstants.mockCourseDetailPath);
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    return CourseDetailResponse.fromJson(data);
  }

  /// Simulasi / Live Login
  Future<bool> login({
    required String nim,
    required String password,
    String? manualBearerToken,
  }) async {
    if (manualBearerToken != null && manualBearerToken.trim().isNotEmpty) {
      await _storage.saveToken(manualBearerToken.trim());
      await _storage.saveStudentInfo(nim: nim, name: ApiConstants.defaultNama);
      await _storage.setUseMock(false);
      return true;
    }

    // Mode Demo Offline atau jika token tidak dimasukkan manual
    await _storage.saveToken('mock_demo_bearer_token_${DateTime.now().millisecondsSinceEpoch}');
    await _storage.saveStudentInfo(
      nim: nim.isNotEmpty ? nim : ApiConstants.defaultNim,
      name: ApiConstants.defaultNama,
    );
    await _storage.setUseMock(true);
    return true;
  }
}
