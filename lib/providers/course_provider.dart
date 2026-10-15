import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/services/storage_service.dart';
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
  final StorageService _storage;

  List<CourseItem> _courses = [];
  CourseItem? _selectedCourse;
  CourseDetailResponse? _courseDetail;
  bool _isLoading = false;
  bool _unauthorized = false;
  String _semester = '';
  String? _errorMessage;

  CourseProvider(this._apiClient, this._storage) {
    _loadFromCache();
  }

  void _loadFromCache() {
    final raw = _storage.getCachedCoursesRaw();
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final res = UserCourseResponse.fromJson(decoded);
          if (res.data.isNotEmpty) {
            _courses = res.data;
            _semester = res.semester;
          }
        }
      } catch (_) {}
    }
  }

  void setInitialCourses(UserCourseResponse response) {
    _courses = response.data;
    _semester = response.semester;
    _errorMessage = null;
    _unauthorized = false;
    notifyListeners();
  }

  List<CourseItem> get courses => _courses;
  CourseItem? get selectedCourse => _selectedCourse;
  CourseDetailResponse? get courseDetail => _courseDetail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUnauthorized => _unauthorized;
  String get semester => _semester;

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
  Future<void> loadUserCourses() async {
    // Jika memori masih kosong, coba muat dari cache storage
    if (_courses.isEmpty) {
      _loadFromCache();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.getUserCourses();
      _courses = response.data;
      _semester = response.semester;
      _unauthorized = false;
      _errorMessage = null;
    } on ApiException catch (e) {
      // Jika sudah ada data matkul dari sesi WebView/cache, jangan sembunyikan!
      if (_courses.isEmpty) {
        _errorMessage = e.message;
        _unauthorized = e.isUnauthorized;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cek apakah detail kelas sudah tersimpan di cache lokal
  bool hasCachedDetail(String kodeCourse) {
    final raw = _storage.getCachedCourseDetailRaw(kodeCourse);
    return raw != null && raw.isNotEmpty;
  }

  /// Ambil Detail Pertemuan 1 - 21 (Sakura/Mentari) dengan dukungan Offline-Cache
  Future<void> loadCourseDetail(CourseItem course, {bool forceRefresh = false}) async {
    _selectedCourse = course;

    // 1. Jika ada cache lokal dan tidak dipaksa refresh, tampilkan segera
    if (!forceRefresh) {
      final cachedRaw = _storage.getCachedCourseDetailRaw(course.kodeCourse);
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedRaw);
          if (decoded is Map<String, dynamic>) {
            _courseDetail = CourseDetailResponse.fromJson(decoded);
            _errorMessage = null;
            notifyListeners();
            return;
          }
        } catch (_) {}
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final detail = await _apiClient.getCourseDetail(course.kodeCourse);
      _courseDetail = detail;
      _errorMessage = null;
      await _storage.saveCachedCourseDetail(
        course.kodeCourse,
        jsonEncode(detail.toJson()),
      );
    } on ApiException catch (e) {
      // Jika sudah ada data di layar dari cache, pertahankan data dan jangan buat layar kosong
      if (_courseDetail == null) {
        _errorMessage = e.message;
        _unauthorized = e.isUnauthorized;
      }
    } catch (e) {
      if (_courseDetail == null) {
        _errorMessage = 'Terjadi kendala saat memuat kelas: $e';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tetapkan detail kelas langsung dari hasil sync Chromium WebView
  void setCourseDetailDirectly(CourseItem course, CourseDetailResponse detail) {
    _selectedCourse = course;
    _courseDetail = detail;
    _errorMessage = null;
    _unauthorized = false;
    _storage.saveCachedCourseDetail(
      course.kodeCourse,
      jsonEncode(detail.toJson()),
    );
    notifyListeners();
  }

  /// Toggle status penyelesaian tugas (Interaktif untuk demo langsung ke dosen)
  void toggleTaskCompletion(SubSection subSection) {
    subSection.completion = !subSection.completion;
    // Simpan progres ke cache jika kelas aktif sedang dibuka
    if (_selectedCourse != null && _courseDetail != null) {
      _storage.saveCachedCourseDetail(
        _selectedCourse!.kodeCourse,
        jsonEncode(_courseDetail!.toJson()),
      );
    }
    notifyListeners();
  }
}
