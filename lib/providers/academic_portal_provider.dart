import 'package:flutter/foundation.dart';
import '../core/services/academic_portal_service.dart';
import '../models/academic_grades_model.dart';
import '../models/attendance_model.dart';
import '../models/lecture_schedule_model.dart';
import '../models/seminar_certificate_model.dart';
import '../models/student_biodata_model.dart';

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

  AcademicPortalProvider(this._service)
      : biodata = PortalResource(_service.getCachedBiodata()),
        grades = PortalResource(_service.getCachedGrades()),
        schedule = PortalResource(_service.getCachedSchedule()),
        certificates = PortalResource(_service.getCachedCertificates()),
        attendance = PortalResource(_service.getCachedAttendanceCourses());

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

  Future<void> refreshAll() => Future.wait([
        fetchBiodata(forceRefresh: true),
        fetchGrades(forceRefresh: true),
        fetchSchedule(forceRefresh: true),
        fetchCertificates(forceRefresh: true),
        fetchAttendanceCourses(forceRefresh: true),
      ]);

  void clear() {
    for (final resource in [biodata, grades, schedule, certificates, attendance]) {
      resource.reset();
    }
    _meetings.clear();
    notifyListeners();
  }
}
