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
}
