import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/mentari_service.dart';
import '../../domain/models/mentari_course_model.dart';
import '../../domain/models/mentari_section_model.dart';

class MentariProvider extends ChangeNotifier {
  final MentariService _service;
  final StorageService _storage;

  List<MentariCourseModel> _courses = [];
  final Map<int, List<MentariSectionModel>> _courseSections = {};
  bool _isLoading = false;
  bool _isLoadingSections = false;
  String? _errorMessage;
  int? _selectedCourseId;

  MentariProvider(this._service, this._storage) {
    _loadCachedData();
  }

  List<MentariCourseModel> get courses => _courses;
  bool get isLoading => _isLoading;
  bool get isLoadingSections => _isLoadingSections;
  String? get errorMessage => _errorMessage;
  bool get hasCourses => _courses.isNotEmpty;
  bool get hasActiveSession => _service.hasActiveSession;
  int? get selectedCourseId => _selectedCourseId;

  MentariCourseModel? get selectedCourse {
    if (_selectedCourseId == null) return null;
    for (final c in _courses) {
      if (c.id == _selectedCourseId) return c;
    }
    return null;
  }

  List<MentariSectionModel> getSectionsForCourse(int courseId) {
    return _courseSections[courseId] ?? const [];
  }

  void _loadCachedData() {
    final cachedJson = _storage.getMentariCachedCourses();
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final list = jsonDecode(cachedJson) as List<dynamic>;
        _courses = list
            .whereType<Map<String, dynamic>>()
            .map((e) => MentariCourseModel.fromJson(e))
            .toList();
      } catch (e) {
        debugPrint('[MentariProvider] Cache read error: $e');
      }
    }
  }

  Future<void> fetchCourses({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _service.fetchEnrolledCourses(forceRefresh: forceRefresh);
      _courses = list;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint('[MentariProvider] fetchCourses error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCourseSections(int courseId, {bool forceRefresh = false}) async {
    if (_isLoadingSections) return;
    _isLoadingSections = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final sections = await _service.fetchCourseSections(courseId, forceRefresh: forceRefresh);
      _courseSections[courseId] = sections;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint('[MentariProvider] fetchCourseSections error: $e');
    } finally {
      _isLoadingSections = false;
      notifyListeners();
    }
  }

  void selectCourse(int courseId) {
    _selectedCourseId = courseId;
    notifyListeners();
    if (!_courseSections.containsKey(courseId)) {
      fetchCourseSections(courseId);
    }
  }

  Future<void> refreshAll() async {
    await fetchCourses(forceRefresh: true);
    if (_selectedCourseId != null) {
      await fetchCourseSections(_selectedCourseId!, forceRefresh: true);
    }
  }

  void clear() {
    _courses = [];
    _courseSections.clear();
    _selectedCourseId = null;
    _errorMessage = null;
    notifyListeners();
  }
}

