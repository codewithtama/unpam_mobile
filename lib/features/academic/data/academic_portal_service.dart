import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../domain/models/academic_grades_model.dart';
import '../domain/models/attendance_model.dart';
import '../domain/models/lecture_schedule_model.dart';
import '../domain/models/seminar_certificate_model.dart';
import '../domain/models/student_biodata_model.dart';
import 'my_unpam_session.dart';
import '../../../../core/services/storage_service.dart';

class AcademicPortalService {
  final MyUnpamSession _session;
  final StorageService _storage;

  AcademicPortalService(this._session, this._storage);

  T? _readCache<T>(String key, T Function(dynamic json) parse) {
    final cached = _storage.getCachedJson(key);
    if (cached == null) return null;
    try {
      return parse(jsonDecode(cached));
    } catch (e) {
      debugPrint('[AcademicPortalService] invalid cache $key: $e');
      return null;
    }
  }

  Future<T> _fetch<T>({
    required String path,
    required String cacheKey,
    required T Function(dynamic json) parse,
    required bool forceRefresh,
  }) async {
    if (!forceRefresh) {
      final cached = _readCache(cacheKey, parse);
      if (cached != null) return cached;
    }

    final json = await _session.get(path);
    final result = parse(json);
    await _storage.saveCachedJson(cacheKey, jsonEncode(json));
    return result;
  }

  static StudentBiodata _parseBiodata(dynamic json) =>
      StudentBiodata.fromJson(json as Map<String, dynamic>);

  static AcademicGradesResponse _parseGrades(dynamic json) =>
      AcademicGradesResponse.fromJson(json as Map<String, dynamic>);

  static LectureScheduleResponse _parseSchedule(dynamic json) =>
      LectureScheduleResponse.fromJson(json as Map<String, dynamic>);

  static List<SeminarCertificateItem> _parseCertificates(dynamic json) => (json as List)
      .map((e) => SeminarCertificateItem.fromJson(e as Map<String, dynamic>))
      .toList();

  static List<AttendanceCourseItem> _parseAttendanceCourses(dynamic json) =>
      (json as List).map((e) => AttendanceCourseItem.fromJson(e as Map<String, dynamic>)).toList();

  static List<AttendanceMeetingItem> _parseAttendanceMeetings(dynamic json) =>
      (json as List).map((e) => AttendanceMeetingItem.fromJson(e as Map<String, dynamic>)).toList();

  StudentBiodata? getCachedBiodata() =>
      _readCache(ApiConstants.myUnpamCachedBiodataKey, _parseBiodata);

  AcademicGradesResponse? getCachedGrades() =>
      _readCache(ApiConstants.myUnpamCachedGradesKey, _parseGrades);

  LectureScheduleResponse? getCachedSchedule() =>
      _readCache(ApiConstants.myUnpamCachedScheduleKey, _parseSchedule);

  List<SeminarCertificateItem>? getCachedCertificates() =>
      _readCache(ApiConstants.myUnpamCachedCertificatesKey, _parseCertificates);

  List<AttendanceCourseItem>? getCachedAttendanceCourses() =>
      _readCache(ApiConstants.myUnpamCachedAttendanceCoursesKey, _parseAttendanceCourses);

  Future<StudentBiodata> fetchStudentBiodata({bool forceRefresh = false}) => _fetch(
        path: '/api/biodata/mahasiswa',
        cacheKey: ApiConstants.myUnpamCachedBiodataKey,
        parse: _parseBiodata,
        forceRefresh: forceRefresh,
      );

  Future<AcademicGradesResponse> fetchAcademicGrades({bool forceRefresh = false}) => _fetch(
        path: '/api/rangkuman-nilai',
        cacheKey: ApiConstants.myUnpamCachedGradesKey,
        parse: _parseGrades,
        forceRefresh: forceRefresh,
      );

  Future<LectureScheduleResponse> fetchLectureSchedule({bool forceRefresh = false}) => _fetch(
        path: '/api/jadwal-kuliah',
        cacheKey: ApiConstants.myUnpamCachedScheduleKey,
        parse: _parseSchedule,
        forceRefresh: forceRefresh,
      );

  Future<List<SeminarCertificateItem>> fetchSeminarCertificates({bool forceRefresh = false}) =>
      _fetch(
        path: '/api/event/sertifikat',
        cacheKey: ApiConstants.myUnpamCachedCertificatesKey,
        parse: _parseCertificates,
        forceRefresh: forceRefresh,
      );

  Future<List<AttendanceCourseItem>> fetchAttendanceCourses({bool forceRefresh = false}) => _fetch(
        path: '/api/presensi/mahasiswa/jadwal-kuliah',
        cacheKey: ApiConstants.myUnpamCachedAttendanceCoursesKey,
        parse: _parseAttendanceCourses,
        forceRefresh: forceRefresh,
      );

  Future<List<AttendanceMeetingItem>> fetchAttendanceMeetings({
    required String idKelas,
    required String idMatakuliah,
  }) async {
    final json =
        await _session.get('/api/presensi/mahasiswa/jadwal-pertemuan/$idKelas/$idMatakuliah');
    return _parseAttendanceMeetings(json);
  }
}
