import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/user_course_model.dart';
import '../models/course_detail_model.dart';

class PendingTaskItem {
  final String sectionTitle;
  final String? meetingTitle;
  final SubSection subSection;

  PendingTaskItem({
    required this.sectionTitle,
    this.meetingTitle,
    required this.subSection,
  });
}

class CourseProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  List<CourseItem> _courses = [];
  CourseItem? _selectedCourse;
  CourseDetailResponse? _courseDetail;
  bool _isLoading = false;
  String? _errorMessage;

  CourseProvider(this._apiClient);

  List<CourseItem> get courses => _courses;
  CourseItem? get selectedCourse => _selectedCourse;
  CourseDetailResponse? get courseDetail => _courseDetail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalSks => _courses.fold(0, (sum, item) => sum + item.sks);

  /// Mengambil semua tugas & kuis yang belum diselesaikan (completion: false)
  List<PendingTaskItem> get pendingTasks {
    if (_courseDetail == null) return [];
    final List<PendingTaskItem> list = [];

    for (final section in _courseDetail!.data) {
      for (final sub in section.subSection) {
        // Ambil aktivitas penugasan, kuis, kuesioner, forum yang belum selesai
        if (sub.isTask && !sub.completion) {
          list.add(
            PendingTaskItem(
              sectionTitle: section.namaSection,
              meetingTitle: section.namaPertemuan,
              subSection: sub,
            ),
          );
        }
      }
    }
    return list;
  }

  /// Mengambil semua tugas & kuis yang sudah selesai (completion: true)
  List<PendingTaskItem> get completedTasks {
    if (_courseDetail == null) return [];
    final List<PendingTaskItem> list = [];

    for (final section in _courseDetail!.data) {
      for (final sub in section.subSection) {
        if (sub.isTask && sub.completion) {
          list.add(
            PendingTaskItem(
              sectionTitle: section.namaSection,
              meetingTitle: section.namaPertemuan,
              subSection: sub,
            ),
          );
        }
      }
    }
    return list;
  }

  double get progressPercentage {
    final total = pendingTasks.length + completedTasks.length;
    if (total == 0) return 0.0;
    return completedTasks.length / total;
  }

  /// Ambil Daftar 8 Mata Kuliah Mahasiswa (Mentari)
  Future<void> loadUserCourses({bool forceLive = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.getUserCourses(forceLive: forceLive);
      _courses = response.data;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal memuat mata kuliah: $e';
      notifyListeners();
    }
  }

  /// Ambil Detail Pertemuan 1 - 21 (Sakura)
  Future<void> loadCourseDetail(CourseItem course, {bool forceLive = false}) async {
    _selectedCourse = course;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final detail = await _apiClient.getCourseDetail(course.kodeCourse, forceLive: forceLive);
      _courseDetail = detail;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal memuat detail pertemuan: $e';
      notifyListeners();
    }
  }

  /// Toggle status penyelesaian tugas (Interaktif untuk demo langsung ke dosen)
  void toggleTaskCompletion(SubSection subSection) {
    subSection.completion = !subSection.completion;
    notifyListeners();
  }
}
