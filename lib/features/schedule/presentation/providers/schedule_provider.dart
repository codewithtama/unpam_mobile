import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/schedule_model.dart';
import '../../data/schedule_service.dart';
import '../../data/deadline_reminder_service.dart';

enum ScheduleLoadState { idle, loading, loaded, error }

/// Provider state management untuk fitur Jadwal & Deadline Tracker.
class ScheduleProvider extends ChangeNotifier {
  final ScheduleService _service;
  final SharedPreferences _prefs;

  List<CourseSchedule> _schedules = [];
  List<CourseDeadline> _deadlines = [];
  ScheduleLoadState _scheduleState = ScheduleLoadState.idle;
  ScheduleLoadState _deadlineState = ScheduleLoadState.idle;
  String _scheduleError = '';
  String _deadlineError = '';

  ScheduleProvider(this._service, this._prefs) {
    _loadFromCache();
  }

  // ─── Getters ──────────────────────────────────────────────────

  List<CourseSchedule> get schedules => _schedules;
  List<CourseDeadline> get deadlines => _deadlines;
  ScheduleLoadState get scheduleState => _scheduleState;
  ScheduleLoadState get deadlineState => _deadlineState;
  String get scheduleError => _scheduleError;
  String get deadlineError => _deadlineError;

  bool get hasSchedules => _schedules.isNotEmpty;
  bool get hasDeadlines => _deadlines.isNotEmpty;

  bool get isScheduleLoading => _scheduleState == ScheduleLoadState.loading;
  bool get isDeadlineLoading => _deadlineState == ScheduleLoadState.loading;

  List<CourseSchedule> get todaySchedule => _service.getTodaySchedule();

  Map<int, List<CourseSchedule>> get weeklySchedule =>
      _service.getWeeklySchedule();

  List<CourseDeadline> get upcomingDeadlines =>
      _deadlines.where((d) => !d.isOverdue).toList();

  List<CourseDeadline> get overdueDeadlines =>
      _deadlines.where((d) => d.isOverdue).toList();

  DateTime? get lastScheduleSync => _service.lastScheduleSync;
  DateTime? get lastDeadlineSync => _service.lastDeadlineSync;

  // ─── Load dari cache (dijalankan saat init) ───────────────────

  void _loadFromCache() {
    _schedules = _service.loadSchedule();
    _deadlines = _service.loadDeadlines();
    if (_schedules.isNotEmpty) _scheduleState = ScheduleLoadState.loaded;
    if (_deadlines.isNotEmpty) _deadlineState = ScheduleLoadState.loaded;
  }

  // ─── Dipanggil dari PortalWebViewScreen saat JS scraper mengirim data ──

  /// Terima dan simpan jadwal yang di-scrape dari MyUnpam WebView.
  Future<void> onScheduleExtracted(List<CourseSchedule> extracted) async {
    if (extracted.isEmpty) return;
    _schedules = extracted;
    _scheduleState = ScheduleLoadState.loaded;
    _scheduleError = '';
    await _service.saveSchedule(extracted);
    notifyListeners();
  }

  /// Terima dan simpan deadline yang di-scrape dari Mentari WebView (dengan merge akumulatif).
  Future<void> onDeadlinesExtracted(List<CourseDeadline> extracted) async {
    if (extracted.isEmpty) return;

    final map = <String, CourseDeadline>{};
    for (final d in _deadlines) {
      final key = d.id.isNotEmpty ? d.id : '${d.namaMataKuliah}_${d.namaTugas}';
      map[key] = d;
    }
    for (final d in extracted) {
      final key = d.id.isNotEmpty ? d.id : '${d.namaMataKuliah}_${d.namaTugas}';
      map[key] = d;
    }

    final merged = map.values.toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    _deadlines = merged;
    _deadlineState = ScheduleLoadState.loaded;
    _deadlineError = '';
    await _service.saveDeadlines(merged);

    // Jadwalkan notifikasi reminder untuk daftar terbaru
    await DeadlineReminderService()
        .scheduleRemindersForDeadlines(merged, _prefs);
    notifyListeners();
  }

  /// Tandai bahwa scraping sedang berjalan.
  void setScheduleLoading() {
    _scheduleState = ScheduleLoadState.loading;
    notifyListeners();
  }

  void setDeadlineLoading() {
    _deadlineState = ScheduleLoadState.loading;
    notifyListeners();
  }

  /// Tandai error scraping jadwal.
  void setScheduleError(String msg) {
    _scheduleState = ScheduleLoadState.error;
    _scheduleError = msg;
    notifyListeners();
  }

  void setDeadlineError(String msg) {
    _deadlineState = ScheduleLoadState.error;
    _deadlineError = msg;
    notifyListeners();
  }
}

