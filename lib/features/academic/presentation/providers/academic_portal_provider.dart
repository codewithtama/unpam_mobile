import 'package:flutter/foundation.dart';
import '../../data/academic_portal_service.dart';
import '../../domain/models/academic_document_model.dart';
import '../../domain/models/academic_grades_model.dart';
import '../../domain/models/absence_permit_model.dart';
import '../../domain/models/attendance_model.dart';
import '../../domain/models/course_project_model.dart';
import '../../domain/models/khs_model.dart';
import '../../domain/models/krs_model.dart';
import '../../domain/models/lecture_schedule_model.dart';
import '../../domain/models/seminar_certificate_model.dart';
import '../../domain/models/student_biodata_model.dart';
import '../../domain/models/thesis_model.dart';

class PortalResource<T> {
  T? data;
  bool isLoading = false;
  String? error;

  PortalResource([this.data]);

  bool get hasData => data != null;

  void reset() {
    data = null;
    isLoading = false;
    error = null;
  }
}

class AcademicPortalProvider extends ChangeNotifier {
  final AcademicPortalService _service;

  final PortalResource<StudentBiodata> biodata;
  final PortalResource<AcademicGradesResponse> grades;
  final PortalResource<LectureScheduleResponse> schedule;
  final PortalResource<List<SeminarCertificateItem>> certificates;
  final PortalResource<List<AttendanceCourseItem>> attendance;
  final Map<String, PortalResource<List<AttendanceMeetingItem>>> _meetings = {};

  final PortalResource<KrsResponse> krs;
  final PortalResource<KhsResponse> khs;
  final PortalResource<List<AcademicDocumentItem>> documents;
  final PortalResource<List<AcademicDocumentCategory>> documentCategories;
  final PortalResource<ThesisResponse> thesis;
  final PortalResource<CourseProjectResponse> courseProjects;
  final PortalResource<AbsencePermitResponse> absencePermits;

  AcademicPortalProvider(this._service)
      : biodata = PortalResource(_service.getCachedBiodata()),
        grades = PortalResource(_service.getCachedGrades()),
        schedule = PortalResource(_service.getCachedSchedule()),
        certificates = PortalResource(_service.getCachedCertificates()),
        attendance = PortalResource(_service.getCachedAttendanceCourses()),
        krs = PortalResource(_service.getCachedKrs()),
        khs = PortalResource(_service.getCachedKhs()),
        documents = PortalResource(_service.getCachedDocuments()),
        documentCategories = PortalResource(_service.getCachedDocumentCategories()),
        thesis = PortalResource(_service.getCachedThesis()),
        courseProjects = PortalResource(_service.getCachedCourseProjects()),
        absencePermits = PortalResource(_service.getCachedAbsencePermits());

  Future<void> _load<T>(PortalResource<T> resource, Future<T> Function() fetch) async {
    if (resource.isLoading) return;
    resource.isLoading = true;
    resource.error = null;
    notifyListeners();

    try {
      resource.data = await fetch();
    } catch (e) {
      resource.error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      resource.isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBiodata({bool forceRefresh = false}) =>
      _load(biodata, () => _service.fetchStudentBiodata(forceRefresh: forceRefresh));

  Future<void> fetchGrades({bool forceRefresh = false}) =>
      _load(grades, () => _service.fetchAcademicGrades(forceRefresh: forceRefresh));

  Future<void> fetchSchedule({bool forceRefresh = false}) =>
      _load(schedule, () => _service.fetchLectureSchedule(forceRefresh: forceRefresh));

  Future<void> fetchCertificates({bool forceRefresh = false}) =>
      _load(certificates, () => _service.fetchSeminarCertificates(forceRefresh: forceRefresh));

  Future<void> fetchAttendanceCourses({bool forceRefresh = false}) {
    if (forceRefresh) _meetings.clear();
    return _load(attendance, () => _service.fetchAttendanceCourses(forceRefresh: forceRefresh));
  }

  PortalResource<List<AttendanceMeetingItem>> meetings(String idKelas, String idMatakuliah) =>
      _meetings.putIfAbsent('${idKelas}_$idMatakuliah', () => PortalResource());

  Future<void> fetchAttendanceMeetings({
    required String idKelas,
    required String idMatakuliah,
    bool forceRefresh = false,
  }) {
    final resource = meetings(idKelas, idMatakuliah);
    if (!forceRefresh && resource.hasData) return Future.value();
    return _load(
      resource,
      () => _service.fetchAttendanceMeetings(idKelas: idKelas, idMatakuliah: idMatakuliah),
    );
  }

  Future<void> fetchKrs({bool forceRefresh = false}) =>
      _load(krs, () => _service.fetchKrs(forceRefresh: forceRefresh));

  Future<void> fetchKhs({bool forceRefresh = false}) =>
      _load(khs, () => _service.fetchKhs(forceRefresh: forceRefresh));

  Future<void> fetchDocuments({bool forceRefresh = false}) =>
      _load(documents, () => _service.fetchDocuments(forceRefresh: forceRefresh));

  Future<void> fetchDocumentCategories({bool forceRefresh = false}) =>
      _load(documentCategories, () => _service.fetchDocumentCategories(forceRefresh: forceRefresh));

  Future<void> fetchThesis({bool forceRefresh = false}) =>
      _load(thesis, () => _service.fetchThesis(forceRefresh: forceRefresh));

  Future<void> fetchCourseProjects({bool forceRefresh = false, int page = 1}) =>
      _load(courseProjects, () => _service.fetchCourseProjects(forceRefresh: forceRefresh, page: page));

  Future<void> fetchAbsencePermits({bool forceRefresh = false, int page = 1}) =>
      _load(absencePermits, () => _service.fetchAbsencePermits(forceRefresh: forceRefresh, page: page));

  Future<void> refreshAll() => Future.wait([
        fetchBiodata(forceRefresh: true),
        fetchGrades(forceRefresh: true),
        fetchSchedule(forceRefresh: true),
        fetchCertificates(forceRefresh: true),
        fetchAttendanceCourses(forceRefresh: true),
        fetchKrs(forceRefresh: true),
        fetchKhs(forceRefresh: true),
        fetchDocuments(forceRefresh: true),
        fetchDocumentCategories(forceRefresh: true),
        fetchThesis(forceRefresh: true),
        fetchCourseProjects(forceRefresh: true),
        fetchAbsencePermits(forceRefresh: true),
      ]);

  void clear() {
    for (final resource in [
      biodata,
      grades,
      schedule,
      certificates,
      attendance,
      krs,
      khs,
      documents,
      documentCategories,
      thesis,
      courseProjects,
      absencePermits,
    ]) {
      resource.reset();
    }
    _meetings.clear();
    notifyListeners();
  }
}
