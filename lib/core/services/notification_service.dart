import 'dart:io';
import 'package:flutter/foundation.dart';
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

  static const String _channelId = 'unpam_update_channel';
  static const String _channelName = 'Pembaruan Aplikasi UNPAM';
  static const String _channelDesc = 'Pemberitahuan ketika versi baru aplikasi UNPAM Mobile tersedia.';

  Future<void> initialize({void Function(AppUpdateInfo info)? onUpdateTap}) async {
    if (_isInitialized) return;

    onUpdateNotificationTap = onUpdateTap;

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
        if (_pendingUpdateInfo != null) {
          onUpdateNotificationTap?.call(_pendingUpdateInfo!);
        }
      },
    );

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

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        enableLights: true,
        enableVibration: true,
        ticker: 'Pembaruan Tersedia',
        styleInformation: BigTextStyleInformation(''),
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final title = 'Pembaruan UNPAM Mobile ${updateInfo.latestVersion} Tersedia! 🚀';
      final body = '${updateInfo.releaseTitle} telah dirilis. Ketuk untuk mengunduh dan memasang versi terbaru.';

      await _plugin.show(
        id: 1001,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('Failed to show update notification: $e');
    }
  }
}
