import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../models/app_update_info.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  void Function(AppUpdateInfo info)? onUpdateNotificationTap;
  AppUpdateInfo? _pendingUpdateInfo;

  static const String _channelId = 'the_pams_update_channel_v1';
  static const String _channelName = 'Pembaruan Aplikasi The PAMs';
  static const String _channelDesc = 'Pemberitahuan ketika versi baru aplikasi The PAMs tersedia.';

  static const String _downloadChannelId = 'the_pams_download_progress_channel';
  static const String _downloadChannelName = 'Status Pengunduhan Pembaruan';
  static const String _downloadChannelDesc = 'Menampilkan kemajuan pengunduhan pembaruan APK The PAMs';
  static const int _downloadNotificationId = 1002;

  DateTime _lastNotifUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _lastReportedProgress = -1;

  Future<void> initialize({void Function(AppUpdateInfo info)? onUpdateTap}) async {
    if (onUpdateTap != null) {
      onUpdateNotificationTap = onUpdateTap;
      if (_pendingUpdateInfo != null) {
        final pending = _pendingUpdateInfo!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onUpdateNotificationTap?.call(pending);
        });
      }
    }
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        AppUpdateInfo? target = _pendingUpdateInfo;
        if (target == null && response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!);
            target = AppUpdateInfo.fromJson(data as Map<String, dynamic>);
          } catch (_) {}
        }
        if (target != null) {
          _pendingUpdateInfo = target;
          onUpdateNotificationTap?.call(target);
        }
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );
      await androidPlugin?.createNotificationChannel(channel);

      const downloadChannel = AndroidNotificationChannel(
        _downloadChannelId,
        _downloadChannelName,
        description: _downloadChannelDesc,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      );
      await androidPlugin?.createNotificationChannel(downloadChannel);
    }

    // Periksa apakah aplikasi dibuka langsung dari ketukan notifikasi saat status terminated
    try {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails != null &&
          launchDetails.didNotificationLaunchApp &&
          launchDetails.notificationResponse?.payload != null) {
        final data = jsonDecode(launchDetails.notificationResponse!.payload!);
        _pendingUpdateInfo = AppUpdateInfo.fromJson(data as Map<String, dynamic>);
        if (onUpdateNotificationTap != null && _pendingUpdateInfo != null) {
          final pending = _pendingUpdateInfo!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onUpdateNotificationTap?.call(pending);
          });
        }
      }
    } catch (_) {}

    _isInitialized = true;
  }

  /// Meminta izin notifikasi (wajib di Android 13+)
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS || Platform.isMacOS) {
      final darwinPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final granted = await darwinPlugin?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    return true;
  }

  /// Menampilkan notifikasi banner melayang (heads-up) di status bar HP
  Future<void> showUpdateNotification(AppUpdateInfo updateInfo) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      await requestPermission();

      _pendingUpdateInfo = updateInfo;

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        enableLights: true,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        ticker: 'Pembaruan Tersedia',
        styleInformation: BigTextStyleInformation(
          '${updateInfo.releaseTitle}\n\nKetuk untuk mengunduh dan memasang versi terbaru.',
          contentTitle: 'Pembaruan The PAMs ${updateInfo.latestVersion} Tersedia! 🚀',
          summaryText: 'Pembaruan Tersedia (${updateInfo.latestVersion})',
        ),
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final title = 'Pembaruan The PAMs ${updateInfo.latestVersion} Tersedia! 🚀';
      final body = '${updateInfo.releaseTitle} telah dirilis. Ketuk untuk mengunduh dan memasang versi terbaru.';

      await _plugin.show(
        id: 1001,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: jsonEncode(updateInfo.toJson()),
      );
    } catch (e) {
      debugPrint('Failed to show update notification: $e');
    }
  }

  /// Menampilkan / memperbarui progress notifikasi download APK di status bar Android
  Future<void> updateDownloadProgress({
    required int receivedBytes,
    required int totalBytes,
    String? title,
  }) async {
    try {
      if (kIsWeb || !Platform.isAndroid) return;
      if (!_isInitialized) await initialize();

      final now = DateTime.now();
      final progressPercent = totalBytes > 0
          ? ((receivedBytes / totalBytes) * 100).toInt().clamp(0, 100)
          : 0;

      // Throttle notification updates: minimal 400ms sekali atau jika persentase berubah
      if (now.difference(_lastNotifUpdateTime).inMilliseconds < 400 &&
          progressPercent == _lastReportedProgress &&
          progressPercent < 100) {
        return;
      }

      _lastNotifUpdateTime = now;
      _lastReportedProgress = progressPercent;

      final receivedMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
      final totalMb = totalBytes > 0
          ? '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
          : '...';

      final androidDetails = AndroidNotificationDetails(
        _downloadChannelId,
        _downloadChannelName,
        channelDescription: _downloadChannelDesc,
        importance: Importance.low,
        priority: Priority.low,
        showWhen: false,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        showProgress: totalBytes > 0,
        maxProgress: 100,
        progress: progressPercent,
        icon: '@mipmap/ic_launcher',
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await _plugin.show(
        id: _downloadNotificationId,
        title: title ?? 'Mengunduh Pembaruan The PAMs ($progressPercent%)',
        body: '$receivedMb MB / $totalMb',
        notificationDetails: notificationDetails,
      );
    } catch (_) {}
  }

  /// Menghapus notifikasi progress pengunduhan setelah selesai / dibatalkan
  Future<void> cancelDownloadNotification() async {
    try {
      _lastReportedProgress = -1;
      await _plugin.cancel(id: _downloadNotificationId);
    } catch (_) {}
  }
}
