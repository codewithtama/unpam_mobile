import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_update_info.dart';
import '../../models/github_release.dart';

class UpdateCheckerService {
  final Dio _dio = Dio();
  static const String _repoOwner = 'codewithtama';
  static const String _repoName = 'unpam_mobile';

  UpdateCheckerService() {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'UNPAM-Mobile-App',
      },
    );
  }

  /// Memeriksa ketersediaan pembaruan dari GitHub Releases
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      const url = 'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';
      final response = await _dio.get<Map<String, dynamic>>(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final tagName = data['tag_name']?.toString() ?? '';
        final releaseTitle = data['name']?.toString() ?? 'Pembaruan Aplikasi';
        final changelog = data['body']?.toString() ?? 'Peningkatan performa dan perbaikan bug.';
        final publishedStr = data['published_at']?.toString();
        DateTime? publishedAt;
        if (publishedStr != null) {
          publishedAt = DateTime.tryParse(publishedStr);
        }

        // Cari file APK pada daftar assets rilis GitHub
        String apkUrl = '';
        int apkSize = 0;
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final assetMap = asset as Map<String, dynamic>;
          final name = assetMap['name']?.toString().toLowerCase() ?? '';
          if (name.endsWith('.apk')) {
            apkUrl = assetMap['browser_download_url']?.toString() ?? '';
            apkSize = (assetMap['size'] as num?)?.toInt() ?? 0;
            break;
          }
        }

        // Jika tidak ada aset APK khusus, fallback ke link halaman rilis GitHub
        if (apkUrl.isEmpty) {
          apkUrl = data['html_url']?.toString() ?? 'https://github.com/$_repoOwner/$_repoName/releases';
        }

        final hasUpdate = AppUpdateInfo.isNewerVersion(tagName, currentVersion);

        return AppUpdateInfo(
          currentVersion: currentVersion,
          latestVersion: tagName,
          releaseTitle: releaseTitle,
          changelog: changelog,
          apkDownloadUrl: apkUrl,
          apkSizeBytes: apkSize,
          publishedAt: publishedAt,
          hasUpdate: hasUpdate,
        );
      }
    } catch (_) {
      // Offline atau repository belum memiliki rilis
      return null;
    }
    return null;
  }

  /// Mengunduh APK pembaruan dan meluncurkan installer Android
  Future<OpenResult> downloadAndInstallApk({
    required String downloadUrl,
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    Directory? targetDir;
    if (Platform.isAndroid) {
      try {
        // Gunakan getExternalStorageDirectory() (context.getExternalFilesDir(null))
        // agar canonical path dikenali oleh open_filex sebagai app-specific dir
        // dan tidak memicu penolakan izin MANAGE_EXTERNAL_STORAGE pada Android 11+ (API 30+)
        targetDir = await getExternalStorageDirectory();
      } catch (_) {}
    }
    targetDir ??= await getApplicationSupportDirectory();

    final savePath = '${targetDir.path}/unpam_update.apk';

    final file = File(savePath);
    if (await file.exists()) {
      await file.delete();
    }

    // Mengunduh APK dengan streaming progress & header biner netral
    await _dio.download(
      downloadUrl,
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: onProgress,
      options: Options(
        headers: {'Accept': '*/*'},
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    if (!await file.exists() || await file.length() == 0) {
      return OpenResult(
        type: ResultType.fileNotFound,
        message: 'File APK tidak ditemukan atau kosong setelah diunduh',
      );
    }

    // Membuka installer Android APK menggunakan Package Archive MIME type
    final result = await OpenFilex.open(
      savePath,
      type: 'application/vnd.android.package-archive',
    );

    return result;
  }

  /// Mengambil seluruh riwayat pembaruan langsung dari GitHub Releases API
  Future<List<GitHubRelease>> fetchReleaseHistory({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    const cacheKey = 'cached_github_releases_list';

    // 1. Coba ambil data live dari GitHub REST API jika bukan mode offline murni
    try {
      const url = 'https://api.github.com/repos/$_repoOwner/$_repoName/releases?per_page=100';
      final response = await _dio.get<List<dynamic>>(url);

      if (response.statusCode == 200 && response.data != null) {
        final List<GitHubRelease> releases = [];
        for (final item in response.data!) {
          if (item is Map<String, dynamic>) {
            final release = GitHubRelease.fromJson(item);
            if (!release.isDraft) {
              releases.add(release);
            }
          }
        }

        // Urutkan rilis berdasarkan tanggal terbaru
        releases.sort((a, b) {
          final timeA = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final timeB = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return timeB.compareTo(timeA);
        });

        // Simpan hasil ke cache lokal untuk akses offline
        try {
          final jsonString = jsonEncode(releases.map((e) => e.toJson()).toList());
          await prefs.setString(cacheKey, jsonString);
        } catch (_) {}

        return releases;
      }
    } catch (_) {
      // Jaringan bermasalah atau rate limit GitHub, lanjut ke fallback cache
    }

    // 2. Fallback: Baca dari cache lokal
    final cached = prefs.getString(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(cached) as List<dynamic>;
        return list.map((e) => GitHubRelease.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    return [];
  }
}
