import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/schedule_model.dart';
import '../../../../core/constants/api_constants.dart';

/// Layanan penjadwalan notifikasi reminder deadline akademik.
///
/// Menggunakan kanal notifikasi tersendiri agar tidak bertabrakan dengan
/// kanal update OTA yang sudah ada di [NotificationService].
class DeadlineReminderService {
  static final DeadlineReminderService _instance =
      DeadlineReminderService._internal();
  factory DeadlineReminderService() => _instance;
  DeadlineReminderService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'the_pams_deadline_reminder_v1';
  static const String _channelName = 'Reminder Deadline Akademik';
  static const String _channelDesc =
      'Pengingat tenggat waktu tugas, kuis, dan ujian perkuliahan.';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized || kIsWeb || !Platform.isAndroid) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: initSettings,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await androidPlugin?.createNotificationChannel(channel);
    _isInitialized = true;
  }

  /// Tampilkan notifikasi reminder langsung.
  Future<void> showImmediateReminder({
    required int notifId,
    required String title,
    required String body,
  }) async {
    await initialize();
    if (!_isInitialized) return;

    await _plugin.show(
      id: notifId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
          channelShowBadge: true,
        ),
      ),
    );
  }

  /// Jadwalkan semua notifikasi reminder untuk daftar deadline yang diberikan.
  Future<void> scheduleRemindersForDeadlines(
    List<CourseDeadline> deadlines,
    SharedPreferences prefs,
  ) async {
    await initialize();
    if (!_isInitialized) return;

    await _cancelAllSavedReminders(prefs);

    final List<int> scheduledIds = [];
    var baseId = 3000; // Mulai dari 3000 agar tidak bentrok dengan OTA (1001, 1002)

    for (final deadline in deadlines) {
      if (deadline.isOverdue) continue;

      final daysLeft = deadline.daysUntilDue;

      if (daysLeft == 3) {
        final id = baseId++;
        await showImmediateReminder(
          notifId: id,
          title: '${deadline.tipe.emoji} Deadline 3 Hari Lagi',
          body:
              '${deadline.namaTugas} — ${deadline.namaMataKuliah} jatuh tempo pada ${_formatDate(deadline.dueDate)}.',
        );
        scheduledIds.add(id);
      }

      if (daysLeft == 1) {
        final id = baseId++;
        await showImmediateReminder(
          notifId: id,
          title: '⚠️ Deadline Besok!',
          body:
              '${deadline.namaTugas} — ${deadline.namaMataKuliah} jatuh tempo BESOK, ${_formatDate(deadline.dueDate)}!',
        );
        scheduledIds.add(id);
      }

      if (daysLeft == 0) {
        final id = baseId++;
        await showImmediateReminder(
          notifId: id,
          title: '🔴 Deadline Hari Ini!',
          body:
              '${deadline.namaTugas} — ${deadline.namaMataKuliah} jatuh tempo HARI INI!',
        );
        scheduledIds.add(id);
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
}
