import 'dart:convert';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../services/storage_service.dart';
import '../../models/user_course_model.dart';
import '../../models/course_detail_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

class ApiClient {
  final Dio _dio = Dio();
  final StorageService _storage;

  ApiClient(this._storage) {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['t'] = DateTime.now().millisecondsSinceEpoch.toString();
          options.headers['Referer'] = 'https://mentari.unpam.ac.id/';
          return handler.next(options);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _getJson(String url) async {
    try {
      final response = await _dio.get<dynamic>(url);
      final raw = response.data;
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('Format respons server tidak dikenali.');
      }
      return decoded;
    } on DioException catch (e) {
      throw _toApiException(e);
    } on FormatException {
      throw const ApiException(
        'Server mengembalikan respons non-JSON (kemungkinan diblokir Cloudflare).',
      );
    }
  }

  ApiException _toApiException(DioException e) {
    final code = e.response?.statusCode;
    if (code == 401) {
      return const ApiException('Sesi berakhir atau token tidak valid. Silakan login ulang.', statusCode: 401);
    }
    if (code == 403) {
      return const ApiException('Akses ditolak server (403). Token salah atau permintaan diblokir.', statusCode: 403);
    }
    if (code != null) {
      return ApiException('Server mengembalikan error $code.', statusCode: code);
    }
    return const ApiException('Tidak dapat terhubung ke server. Periksa koneksi internet.');
  }

  Future<UserCourseResponse> getUserCourses() async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final url =
        '${ApiConstants.mentariBaseUrl}${ApiConstants.userCourses}?page=1&limit=50&t=$ts';
    return UserCourseResponse.fromJson(await _getJson(url));
  }

  Future<CourseDetailResponse> getCourseDetail(String kodeCourse) async {
    final url = '${ApiConstants.sakuraBaseUrl}${ApiConstants.courseDetail(kodeCourse)}';
    return CourseDetailResponse.fromJson(await _getJson(url));
  }

  /// Token divalidasi ke server sebelum sesi disimpan; token invalid tidak pernah tersimpan.
  Future<void> loginWithToken(String token) async {
    final clean = token.trim();
    await _storage.saveToken(clean);
    try {
      await getUserCourses();
      await _storage.saveStudentInfo(
        nim: nimFromToken(clean) ?? '',
        name: nameFromToken(clean) ?? '',
      );
    } on ApiException {
      await _storage.clearSession();
      rethrow;
    }
  }

  static Map<String, dynamic>? _jwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final json = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final decoded = jsonDecode(json);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static String? nimFromToken(String token) {
    final payload = _jwtPayload(token);
    if (payload == null) return null;
    for (final key in const ['username', 'nim', 'user_name', 'sub']) {
      final v = payload[key]?.toString();
      if (v != null && RegExp(r'^\d{6,}$').hasMatch(v)) return v;
    }
    return null;
  }

  static String? nameFromToken(String token) {
    final name = _jwtPayload(token)?['fullname']?.toString().trim();
    return (name == null || name.isEmpty) ? null : name;
  }

  /// True bila token JWT belum kedaluwarsa (atau tidak punya klaim exp).
  static bool isTokenFresh(String token) {
    final payload = _jwtPayload(token);
    if (payload == null) return false;
    final exp = payload['exp'];
    if (exp is! num) return true;
    return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000).isAfter(DateTime.now());
  }
}
