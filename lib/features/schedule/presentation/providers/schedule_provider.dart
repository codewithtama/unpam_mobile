import 'dart:async';
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
  Timer? _scheduleAlarmDebounceTimer;

  @override
  void dispose() {
    _scheduleAlarmDebounceTimer?.cancel();
    super.dispose();
  }

  bool _areDeadlinesEqual(List<CourseDeadline> a, List<CourseDeadline> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].dueDate != b[i].dueDate ||
          a[i].namaTugas != b[i].namaTugas ||
          a[i].namaMataKuliah != b[i].namaMataKuliah) {
        return false;
      }
    }
    return true;
  }
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
    if (_deadlines.isNotEmpty) {
      _deadlineState = ScheduleLoadState.loaded;
      DeadlineReminderService().scheduleRemindersForDeadlines(_deadlines, _prefs);
    }
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
      final courseName = _resolveCourseName(d.namaMataKuliah, d.url);
      final item = CourseDeadline(
        id: d.id,
        namaTugas: d.namaTugas,
        namaMataKuliah: courseName,
        dueDate: d.dueDate,
        tipe: d.tipe,
        url: d.url,
      );
      final key = item.id.isNotEmpty ? item.id : '${item.namaMataKuliah}_${item.namaTugas}';
      map[key] = item;
    }

    final merged = map.values.toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // Cek apakah data benar-benar berubah sebelum menulis ke disk dan menyentuh platform channel
    if (_areDeadlinesEqual(_deadlines, merged)) {
      return;
    }

    _deadlines = merged;
    _deadlineState = ScheduleLoadState.loaded;
    _deadlineError = '';
    await _service.saveDeadlines(merged);
    notifyListeners();

    // Debounce penjadwalan alarm native AlarmManager agar tidak membanjiri IPC platform channel
    _scheduleAlarmDebounceTimer?.cancel();
    _scheduleAlarmDebounceTimer = Timer(const Duration(milliseconds: 2000), () async {
      await DeadlineReminderService()
          .scheduleRemindersForDeadlines(_deadlines, _prefs);
    });
  }

  String _resolveCourseName(String rawCourse, String url) {
    var clean = rawCourse.trim();
    // Bersihkan format Mentari LMS: "[3] JARINGAN KOMPUTER # 04SIFE001 (Sabtu) [E-1]" -> "JARINGAN KOMPUTER"
    final bracketMatch =
        RegExp(r'^\[\d+\]\s*(.*?)(?:\s*#.*)?$').firstMatch(clean);
    if (bracketMatch != null) {
      final extracted = bracketMatch.group(1)?.trim();
      if (extracted != null && extracted.isNotEmpty) {
        clean = extracted;
      }
    }

    if (clean.isNotEmpty &&
        clean != 'Mata Kuliah' &&
        clean != 'Mata Kuliah Mentari' &&
        !clean.startsWith('http')) {
      return clean;
    }
    for (final s in _schedules) {
      if (s.kode.isNotEmpty && url.contains(s.kode)) return s.namaMataKuliah;
      if (s.kelas.isNotEmpty && url.contains(s.kelas)) return s.namaMataKuliah;
      if (s.ruang.isNotEmpty && url.contains(s.ruang)) return s.namaMataKuliah;
    }
    return clean.isNotEmpty ? clean : 'Mata Kuliah';
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

