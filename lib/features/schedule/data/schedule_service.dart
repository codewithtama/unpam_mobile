import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/schedule_model.dart';
import '../../../../core/constants/api_constants.dart';

/// Layanan penyimpanan dan pembacaan data jadwal kuliah & deadline dari
/// SharedPreferences. Tidak membutuhkan dependency Drift/SQLite.
class ScheduleService {
  final SharedPreferences _prefs;

  /// Callback global navigasi deadline ke tab Mentari LMS in-app.
  static void Function(String url)? globalDeadlineNavigator;

  ScheduleService(this._prefs);

  // ──────────────────────────────────────────────────────────────
  // Jadwal Kuliah
  // ──────────────────────────────────────────────────────────────

  /// Simpan jadwal baru (menggantikan seluruh cache).
  Future<void> saveSchedule(List<CourseSchedule> schedules) async {
    await _prefs.setString(
        ApiConstants.scheduleCacheKey, CourseSchedule.listToJson(schedules));
    await _prefs.setString(
        ApiConstants.scheduleLastSyncKey, DateTime.now().toIso8601String());
  }

  /// Baca jadwal dari cache lokal.
  List<CourseSchedule> loadSchedule() {
    final raw = _prefs.getString(ApiConstants.scheduleCacheKey);
    if (raw == null || raw.isEmpty) return [];
    return CourseSchedule.listFromJson(raw);
  }

  /// Waktu terakhir kali jadwal di-sync dari portal.
  DateTime? get lastScheduleSync {
    final raw = _prefs.getString(ApiConstants.scheduleLastSyncKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  bool get hasScheduleCache {
    final raw = _prefs.getString(ApiConstants.scheduleCacheKey);
    return raw != null && raw.isNotEmpty && raw != '[]';
  }

  // ──────────────────────────────────────────────────────────────
  // Deadline / Tenggat Waktu
  // ──────────────────────────────────────────────────────────────

  /// Simpan daftar deadline baru (menggantikan seluruh cache).
  Future<void> saveDeadlines(List<CourseDeadline> deadlines) async {
    // Hanya simpan deadline yang belum lewat
    final upcoming = deadlines
        .where((d) => !d.isOverdue || d.daysUntilDue >= -1)
        .toList();
    await _prefs.setString(
        ApiConstants.deadlineCacheKey, CourseDeadline.listToJson(upcoming));
    await _prefs.setString(
        ApiConstants.deadlineLastSyncKey, DateTime.now().toIso8601String());
  }

  /// Baca deadline dari cache lokal, diurutkan dari yang paling dekat.
  List<CourseDeadline> loadDeadlines() {
    final raw = _prefs.getString(ApiConstants.deadlineCacheKey);
    if (raw == null || raw.isEmpty) return [];
    return CourseDeadline.listFromJson(raw);
  }

  /// Waktu terakhir kali deadline di-sync dari portal.
  DateTime? get lastDeadlineSync {
    final raw = _prefs.getString(ApiConstants.deadlineLastSyncKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  bool get hasDeadlineCache {
    final raw = _prefs.getString(ApiConstants.deadlineCacheKey);
    return raw != null && raw.isNotEmpty && raw != '[]';
  }

  // ──────────────────────────────────────────────────────────────
  // Helper: Jadwal hari ini
  // ──────────────────────────────────────────────────────────────

  /// Kembalikan jadwal untuk hari ini (berdasarkan `DateTime.now().weekday`).
  List<CourseSchedule> getTodaySchedule() {
    final today = DateTime.now().weekday; // 1=Senin, 7=Minggu
    final all = loadSchedule();
    return all
        .where((s) => s.hariIndex == today)
        .toList()
      ..sort((a, b) => a.jamMulai.compareTo(b.jamMulai));
  }

  /// Kembalikan jadwal yang dikelompokkan per hari (1–7).
  Map<int, List<CourseSchedule>> getWeeklySchedule() {
    final all = loadSchedule();
    final Map<int, List<CourseSchedule>> result = {};
    for (final s in all) {
      if (s.hariIndex < 1 || s.hariIndex > 7) continue;
      result.putIfAbsent(s.hariIndex, () => []).add(s);
    }
    for (final list in result.values) {
      list.sort((a, b) => a.jamMulai.compareTo(b.jamMulai));
    }
    return result;
  }
}
