import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermissionType {
  notification,
  camera,
  photosOrStorage,
}

class AppPermissionItem {
  final AppPermissionType type;
  final String title;
  final String description;
  final PermissionStatus status;

  const AppPermissionItem({
    required this.type,
    required this.title,
    required this.description,
    required this.status,
  });

  bool get isGranted => status.isGranted || status.isLimited;
  bool get isPermanentlyDenied => status.isPermanentlyDenied;

  AppPermissionItem copyWith({
    PermissionStatus? status,
  }) {
    return AppPermissionItem(
      type: type,
      title: title,
      description: description,
      status: status ?? this.status,
    );
  }
}

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  int? _cachedAndroidSdkInt;
  Map<AppPermissionType, PermissionStatus>? mockStatuses;

  void resetMock() {
    mockStatuses = null;
    _cachedAndroidSdkInt = null;
  }

  /// Mendapatkan versi Android SDK (API level)
  Future<int> getAndroidSdkInt() async {
    if (_cachedAndroidSdkInt != null) {
      return _cachedAndroidSdkInt!;
    }

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        _cachedAndroidSdkInt = androidInfo.version.sdkInt;
        return _cachedAndroidSdkInt!;
      } catch (_) {
        // Fallback jika gagal membaca versi SDK
        _cachedAndroidSdkInt = 33;
        return 33;
      }
    }

    _cachedAndroidSdkInt = 0;
    return 0;
  }

  /// Menentukan apakah permission penyimpanan menggunakan Photos (Android 13+ / iOS)
  /// atau Storage (Android 12-)
  Future<Permission> getMediaPermissionTarget() async {
    if (!kIsWeb && Platform.isAndroid) {
      final sdkInt = await getAndroidSdkInt();
      if (sdkInt >= 33) {
        return Permission.photos;
      } else {
        return Permission.storage;
      }
    }
    return Permission.photos;
  }

  /// Memeriksa status izin notifikasi
  Future<PermissionStatus> checkNotificationStatus() async {
    if (mockStatuses != null && mockStatuses!.containsKey(AppPermissionType.notification)) {
      return mockStatuses![AppPermissionType.notification]!;
    }
    if (kIsWeb) return PermissionStatus.granted;
    return await Permission.notification.status;
  }

  /// Memeriksa status izin kamera
  Future<PermissionStatus> checkCameraStatus() async {
    if (mockStatuses != null && mockStatuses!.containsKey(AppPermissionType.camera)) {
      return mockStatuses![AppPermissionType.camera]!;
    }
    if (kIsWeb) return PermissionStatus.granted;
    return await Permission.camera.status;
  }

  /// Memeriksa status izin galeri / media / penyimpanan
  Future<PermissionStatus> checkMediaStorageStatus() async {
    if (mockStatuses != null && mockStatuses!.containsKey(AppPermissionType.photosOrStorage)) {
      return mockStatuses![AppPermissionType.photosOrStorage]!;
    }
    if (kIsWeb) return PermissionStatus.granted;
    final target = await getMediaPermissionTarget();
    return await target.status;
  }

  /// Memeriksa apakah SEMUA izin wajib sudah disetujui
  Future<bool> areAllPermissionsGranted() async {
    if (kIsWeb) return true;

    final notifStatus = await checkNotificationStatus();
    final notifGranted = notifStatus.isGranted || notifStatus.isLimited;
    if (!notifGranted) return false;

    final cameraStatus = await checkCameraStatus();
    final cameraGranted = cameraStatus.isGranted || cameraStatus.isLimited;
    if (!cameraGranted) return false;

    final mediaStatus = await checkMediaStorageStatus();
    final mediaGranted = mediaStatus.isGranted || mediaStatus.isLimited;
    if (!mediaGranted) return false;

    return true;
  }

  /// Meminta seluruh izin yang belum disetujui
  Future<Map<AppPermissionType, PermissionStatus>> requestAllPermissions() async {
    if (mockStatuses != null) {
      return Map.from(mockStatuses!);
    }

    if (kIsWeb) {
      return {
        AppPermissionType.notification: PermissionStatus.granted,
        AppPermissionType.camera: PermissionStatus.granted,
        AppPermissionType.photosOrStorage: PermissionStatus.granted,
      };
    }

    final mediaTarget = await getMediaPermissionTarget();

    final statuses = await [
      Permission.notification,
      Permission.camera,
      mediaTarget,
    ].request();

    return {
      AppPermissionType.notification: statuses[Permission.notification] ?? PermissionStatus.denied,
      AppPermissionType.camera: statuses[Permission.camera] ?? PermissionStatus.denied,
      AppPermissionType.photosOrStorage: statuses[mediaTarget] ?? PermissionStatus.denied,
    };
  }

  /// Meminta izin tunggal
  Future<PermissionStatus> requestSinglePermission(AppPermissionType type) async {
    if (mockStatuses != null && mockStatuses!.containsKey(type)) {
      return mockStatuses![type]!;
    }

    if (kIsWeb) return PermissionStatus.granted;

    switch (type) {
      case AppPermissionType.notification:
        return await Permission.notification.request();
      case AppPermissionType.camera:
        return await Permission.camera.request();
      case AppPermissionType.photosOrStorage:
        final target = await getMediaPermissionTarget();
        return await target.request();
    }
  }

  /// Membuka halaman Pengaturan Aplikasi di HP
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
