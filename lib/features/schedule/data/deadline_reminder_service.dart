import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../domain/models/schedule_model.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/notification_service.dart';

/// Layanan penjadwalan notifikasi reminder deadline akademik.
///
/// Terintegrasi dengan [NotificationService] menggunakan kanal notifikasi
/// tersendiri dan penjadwalan alarm presisi melalui [zonedSchedule] dan [timezone].
class DeadlineReminderService {
  static final DeadlineReminderService _instance =
      DeadlineReminderService._internal();
  factory DeadlineReminderService() => _instance;
  DeadlineReminderService._internal();

  FlutterLocalNotificationsPlugin get _plugin => NotificationService().plugin;

  bool _isTimezoneInitialized = false;

  Future<void> initialize() async {
    if (_isTimezoneInitialized) return;

    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    _isTimezoneInitialized = true;
  }

  /// Tampilkan notifikasi reminder langsung (Heads-up).
  Future<void> showImmediateReminder({
    required int notifId,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();
    if (kIsWeb) return;

    await _plugin.show(
      id: notifId,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationService.deadlineChannelId,
          NotificationService.deadlineChannelName,
          channelDescription: NotificationService.deadlineChannelDesc,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
          channelShowBadge: true,
          category: AndroidNotificationCategory.reminder,
        ),
      ),
    );
  }

  /// Menjadwalkan alarm notifikasi ke OS via [zonedSchedule].
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    try {
      final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
      if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

      const androidDetails = AndroidNotificationDetails(
        NotificationService.deadlineChannelId,
        NotificationService.deadlineChannelName,
        channelDescription: NotificationService.deadlineChannelDesc,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        category: AndroidNotificationCategory.reminder,
      );

      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzDate,
          notificationDetails: const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
      } catch (_) {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzDate,
          notificationDetails: const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
      }
    } catch (_) {
      // Lewati dengan aman di lingkungan test atau saat platform plugin belum terpasang
    }
  }

  /// Jadwalkan semua notifikasi reminder untuk daftar deadline yang diberikan.
  Future<void> scheduleRemindersForDeadlines(
    List<CourseDeadline> deadlines,
    SharedPreferences prefs,
  ) async {
    await initialize();
    if (kIsWeb) return;

    await _cancelAllSavedReminders(prefs);

    final List<int> scheduledIds = [];
    final now = DateTime.now();
    var baseId = 3000;

    for (final deadline in deadlines) {
      if (deadline.isOverdue) continue;

      final due = deadline.dueDate;
      final payload = jsonEncode({
        'type': 'deadline',
        'id': deadline.id,
        'namaTugas': deadline.namaTugas,
        'namaMataKuliah': deadline.namaMataKuliah,
        'dueDate': due.toIso8601String(),
        'url': deadline.url,
      });

      // 1. Reminder H-3 (3 Hari Sebelum, jam 08:00 pagi WIB)
      final h3Date = DateTime(due.year, due.month, due.day)
          .subtract(const Duration(days: 3))
          .add(const Duration(hours: 8));
      if (h3Date.isAfter(now)) {
        final id = baseId++;
        await _scheduleNotification(
          id: id,
          title: '${deadline.tipe.emoji} Deadline 3 Hari Lagi',
          body:
              '${deadline.namaTugas} — ${deadline.namaMataKuliah} jatuh tempo pada ${_formatDate(due)}.',
          scheduledDate: h3Date,
          payload: payload,
        );
        scheduledIds.add(id);
      }

      // 2. Reminder H-1 (Besok, jam 08:00 pagi WIB)
      final h1Date = DateTime(due.year, due.month, due.day)
          .subtract(const Duration(days: 1))
          .add(const Duration(hours: 8));
      if (h1Date.isAfter(now)) {
        final id = baseId++;
        await _scheduleNotification(
          id: id,
          title: '⚠️ Deadline Besok!',
          body:
              '${deadline.namaTugas} — ${deadline.namaMataKuliah} jatuh tempo BESOK, ${_formatDate(due)}!',
          scheduledDate: h1Date,
          payload: payload,
        );
        scheduledIds.add(id);
      }

      // 3. Reminder H-0 (Hari Ini, jam 07:00 pagi WIB)
      final h0Date = DateTime(due.year, due.month, due.day)
          .add(const Duration(hours: 7));
      if (h0Date.isAfter(now) && h0Date.isBefore(due)) {
        final id = baseId++;
        await _scheduleNotification(
          id: id,
          title: '🔴 Deadline Hari Ini!',
          body:
              '${deadline.namaTugas} — ${deadline.namaMataKuliah} jatuh tempo HARI INI pukul ${_formatTime(due)}!',
          scheduledDate: h0Date,
          payload: payload,
        );
        scheduledIds.add(id);
      }

      // 4. Reminder H-2 Jam (2 Jam sebelum batas akhir pengumpulan)
      final h2HoursDate = due.subtract(const Duration(hours: 2));
      if (h2HoursDate.isAfter(now)) {
        final id = baseId++;
        await _scheduleNotification(
          id: id,
          title: '⏰ 2 Jam Lagi: ${deadline.namaTugas}',
          body:
              'Tenggat ${deadline.namaMataKuliah} berakhir dalam 2 jam (pukul ${_formatTime(due)})!',
          scheduledDate: h2HoursDate,
          payload: payload,
        );
        scheduledIds.add(id);
      }

      // 5. Notifikasi Langsung jika Jatuh Tempo Hari Ini (< 24 Jam) dan belum pernah ditampilkan hari ini
      final remainingHours = due.difference(now).inHours;
      if (remainingHours >= 0 && remainingHours < 24) {
        final todayKey = 'immediate_notif_${deadline.id}_${now.day}_${now.month}';
        final alreadyNotifiedToday = prefs.getBool(todayKey) ?? false;
        if (!alreadyNotifiedToday) {
          final id = baseId++;
          await showImmediateReminder(
            notifId: id,
            title: remainingHours <= 2
                ? '⏰ MENDESAK: ${deadline.namaTugas}'
                : '🔴 Deadline Hari Ini: ${deadline.namaTugas}',
            body:
                '${deadline.namaMataKuliah} jatuh tempo ${_formatDate(due)} pukul ${_formatTime(due)}. Segera kumpulkan!',
            payload: payload,
          );
          scheduledIds.add(id);
          await prefs.setBool(todayKey, true);
        }
      }
    }

    await prefs.setString(
      ApiConstants.scheduledReminderIdsKey,
      jsonEncode(scheduledIds),
    );
  }

  Future<void> _cancelAllSavedReminders(SharedPreferences prefs) async {
    try {
      final raw = prefs.getString(ApiConstants.scheduledReminderIdsKey);
      if (raw == null || raw.isEmpty) return;
      final ids = (jsonDecode(raw) as List).cast<int>();
      for (final id in ids) {
        await _plugin.cancel(id: id);
      }
      await prefs.remove(ApiConstants.scheduledReminderIdsKey);
    } catch (_) {}
  }

  String _formatDate(DateTime dt) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
