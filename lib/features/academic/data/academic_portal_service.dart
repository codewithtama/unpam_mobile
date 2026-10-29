import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../domain/models/academic_document_model.dart';
import '../domain/models/academic_grades_model.dart';
import '../domain/models/absence_permit_model.dart';
import '../domain/models/attendance_model.dart';
import '../domain/models/course_project_model.dart';
import '../domain/models/khs_model.dart';
import '../domain/models/krs_model.dart';
import '../domain/models/lecture_schedule_model.dart';
import '../domain/models/seminar_certificate_model.dart';
import '../domain/models/student_biodata_model.dart';
import '../domain/models/thesis_model.dart';
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

  static KrsResponse _parseKrs(dynamic json) =>
      KrsResponse.fromJson(json as Map<String, dynamic>);

  static KhsResponse _parseKhs(dynamic json) =>
      KhsResponse.fromJson(json as Map<String, dynamic>);

  static List<AcademicDocumentItem> _parseDocuments(dynamic json) => (json as List)
      .map((e) => AcademicDocumentItem.fromJson(e as Map<String, dynamic>))
      .toList();

  static List<AcademicDocumentCategory> _parseDocumentCategories(dynamic json) => (json as List)
      .map((e) => AcademicDocumentCategory.fromJson(e as Map<String, dynamic>))
      .toList();

  static ThesisResponse _parseThesis(dynamic json) {
    if (json is Map<String, dynamic>) {
      List<ThesisGuidanceItem> guidance = const [];
      ThesisSupervisors? supervisors;
      if (json['bimbingan_riwayat'] is List) {
        guidance = (json['bimbingan_riwayat'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => ThesisGuidanceItem.fromJson(e))
            .toList();
      }
      if (json['supervisors'] is Map<String, dynamic>) {
        supervisors = ThesisSupervisors.fromJson(json['supervisors'] as Map<String, dynamic>);
      }
      return ThesisResponse.fromJson(json, guidance: guidance, supervisors: supervisors);
    }
    return const ThesisResponse();
  }

  static CourseProjectResponse _parseCourseProjects(dynamic json) =>
      CourseProjectResponse.fromJson(json as Map<String, dynamic>);

  static AbsencePermitResponse _parseAbsencePermits(dynamic json) =>
      AbsencePermitResponse.fromJson(json as Map<String, dynamic>);

  // Cache Readers
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

  KrsResponse? getCachedKrs() =>
      _readCache(ApiConstants.myUnpamCachedKrsKey, _parseKrs);

  KhsResponse? getCachedKhs() =>
      _readCache(ApiConstants.myUnpamCachedKhsKey, _parseKhs);

  List<AcademicDocumentItem>? getCachedDocuments() =>
      _readCache(ApiConstants.myUnpamCachedDokumenKey, _parseDocuments);

  List<AcademicDocumentCategory>? getCachedDocumentCategories() =>
      _readCache(ApiConstants.myUnpamCachedDokumenKategoriKey, _parseDocumentCategories);

  ThesisResponse? getCachedThesis() =>
      _readCache(ApiConstants.myUnpamCachedThesisKey, _parseThesis);

  CourseProjectResponse? getCachedCourseProjects() =>
      _readCache(ApiConstants.myUnpamCachedCourseProjectsKey, _parseCourseProjects);

  AbsencePermitResponse? getCachedAbsencePermits() =>
      _readCache(ApiConstants.myUnpamCachedAbsencePermitsKey, _parseAbsencePermits);

  // Network Fetchers
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

  Future<KrsResponse> fetchKrs({bool forceRefresh = false}) => _fetch(
        path: '/api/krs',
        cacheKey: ApiConstants.myUnpamCachedKrsKey,
        parse: _parseKrs,
        forceRefresh: forceRefresh,
      );

  Future<KhsResponse> fetchKhs({bool forceRefresh = false}) => _fetch(
        path: '/api/khs',
        cacheKey: ApiConstants.myUnpamCachedKhsKey,
        parse: _parseKhs,
        forceRefresh: forceRefresh,
      );

  Future<List<AcademicDocumentItem>> fetchDocuments({bool forceRefresh = false}) => _fetch(
        path: '/api/dokumen',
        cacheKey: ApiConstants.myUnpamCachedDokumenKey,
        parse: _parseDocuments,
        forceRefresh: forceRefresh,
      );

  Future<List<AcademicDocumentCategory>> fetchDocumentCategories({bool forceRefresh = false}) =>
      _fetch(
        path: '/api/dokumen/kategori',
        cacheKey: ApiConstants.myUnpamCachedDokumenKategoriKey,
        parse: _parseDocumentCategories,
        forceRefresh: forceRefresh,
      );

  Future<ThesisResponse> fetchThesis({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _readCache(ApiConstants.myUnpamCachedThesisKey, _parseThesis);
      if (cached != null) return cached;
    }

    final rawThesis = await _session.get('/api/tugas-akhir/mahasiswa');
    final thesisMap = rawThesis is Map<String, dynamic> ? rawThesis : <String, dynamic>{};

    List<ThesisGuidanceItem> guidance = const [];
    ThesisSupervisors? supervisors;

    try {
      final rawGuidance = await _session.get('/api/tugas-akhir/bimbingan-riwayat');
      if (rawGuidance is List) {
        guidance = rawGuidance
            .whereType<Map<String, dynamic>>()
            .map((e) => ThesisGuidanceItem.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('[AcademicPortalService] guidance history skipped: $e');
    }

    try {
      final rawSupervisors = await _session.get('/api/tugas-akhir/mahasiswa/pembimbing');
      if (rawSupervisors is Map<String, dynamic> && rawSupervisors['data_pembimbing'] is Map) {
        supervisors = ThesisSupervisors.fromJson(
            rawSupervisors['data_pembimbing'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[AcademicPortalService] supervisors skipped: $e');
    }

    final response = ThesisResponse.fromJson(
      thesisMap,
      guidance: guidance,
      supervisors: supervisors,
    );
    await _storage.saveCachedJson(ApiConstants.myUnpamCachedThesisKey, jsonEncode(response.toJson()));
    return response;
  }

  Future<CourseProjectResponse> fetchCourseProjects({
    bool forceRefresh = false,
    int page = 1,
  }) =>
      _fetch(
        path: '/api/penugasan-proyek?page=$page',
        cacheKey: '${ApiConstants.myUnpamCachedCourseProjectsKey}_$page',
        parse: _parseCourseProjects,
        forceRefresh: forceRefresh,
      );

  Future<AbsencePermitResponse> fetchAbsencePermits({
    bool forceRefresh = false,
    int page = 1,
  }) =>
      _fetch(
        path: '/api/absen-jalan/pengajuan-izin?page=$page',
        cacheKey: '${ApiConstants.myUnpamCachedAbsencePermitsKey}_$page',
        parse: _parseAbsencePermits,
        forceRefresh: forceRefresh,
      );
}
