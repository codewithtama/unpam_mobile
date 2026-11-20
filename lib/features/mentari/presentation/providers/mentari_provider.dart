import 'package:flutter/foundation.dart';
import '../../../../core/network/cloudflare_clearance_modal.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/mentari_service.dart';
import '../../domain/models/mentari_course_model.dart';
import '../../domain/models/mentari_interactive_models.dart';
import '../../domain/models/mentari_module_model.dart';
import '../../domain/models/mentari_section_model.dart';

class MentariProvider extends ChangeNotifier {
  final MentariService _service;
  final StorageService _storage;

  List<MentariCourseModel> _courses = [];
  final Map<int, List<MentariSectionModel>> _courseSections = {};
  final Map<int, List<MentariParticipantModel>> _courseParticipants = {};
  final Set<int> _completedModuleIds = {};
  bool _isLoadingCourses = false;
  bool _isLoadingSections = false;
  bool _needsCloudflareVerify = false;
  String? _error;

  MentariProvider(this._service, this._storage) {
    _hydrateFromCache();
  }

  MentariService get service => _service;
  List<MentariCourseModel> get courses => _courses;
  bool get hasCourses => _courses.isNotEmpty;
  bool get isLoading => _isLoadingCourses || _isLoadingSections;
  bool get isLoadingCourses => _isLoadingCourses;
  bool get isLoadingSections => _isLoadingSections;
  bool get needsCloudflareVerify => _needsCloudflareVerify;
  String? get error => _error;
  bool get hasActiveSession => _service.hasActiveSession || _courses.isNotEmpty;

  List<MentariSectionModel> getSectionsForCourse(int courseId) =>
      _courseSections[courseId] ?? const [];

  List<MentariParticipantModel> getParticipantsForCourse(int courseId) =>
      _courseParticipants[courseId] ?? const [];

  bool isModuleCompleted(MentariModuleModel module) =>
      module.isCompleted || _completedModuleIds.contains(module.id);

  void markModuleCompleted(int moduleId) {
    _completedModuleIds.add(moduleId);
    notifyListeners();
  }

  void clearCloudflareFlag() {
    if (_needsCloudflareVerify) {
      _needsCloudflareVerify = false;
      notifyListeners();
    }
  }

  void _hydrateFromCache() {
    try {
      final raw = _storage.getMentariCachedCourses();
      if (raw != null && raw.isNotEmpty) {
        _service.fetchEnrolledCourses(forceRefresh: false).then((cached) {
          if (cached.isNotEmpty) {
            _courses = cached;
            notifyListeners();
          }
        }).catchError((_) {});
      }
    } catch (_) {}
  }

  Future<void> fetchCourses({bool forceRefresh = false}) async {
    _isLoadingCourses = true;
    _error = null;
    _needsCloudflareVerify = false;
    notifyListeners();

    try {
      final result = await _service.fetchEnrolledCourses(forceRefresh: forceRefresh);
      _courses = result;
    } on CloudflareChallengeException catch (e) {
      _needsCloudflareVerify = true;
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingCourses = false;
      notifyListeners();
    }
  }

  Future<void> fetchCourseSections(
    int courseId, {
    String? courseCode,
    bool forceRefresh = false,
  }) async {
    _isLoadingSections = true;
    _error = null;
    _needsCloudflareVerify = false;
    notifyListeners();

    try {
      final bundle = await _service.fetchCourseDetailBundle(
        courseId,
        courseCode: courseCode,
        forceRefresh: forceRefresh,
      );
      _courseSections[courseId] = bundle.$1;
      if (bundle.$2.isNotEmpty) {
        _courseParticipants[courseId] = bundle.$2;
      }
    } on CloudflareChallengeException catch (e) {
      _needsCloudflareVerify = true;
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingSections = false;
      notifyListeners();
    }
  }

  Future<void> disconnectSession() async {
    await _storage.clearMentariSession();
    _courses = [];
    _courseSections.clear();
    _courseParticipants.clear();
    notifyListeners();
  }
}
