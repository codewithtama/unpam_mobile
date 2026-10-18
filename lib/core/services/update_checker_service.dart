import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_update_info.dart';
import '../../models/github_release.dart';
import 'notification_service.dart';

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

      Map<String, dynamic>? data;

      // 1. Coba endpoint rilis terbaru utama
      try {
        const url = 'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';
        final response = await _dio.get<Map<String, dynamic>>(url);
        if (response.statusCode == 200 && response.data != null) {
          data = response.data;
        }
      } catch (e) {
        // 2. Fallback ke endpoint daftar rilis teratas jika endpoint /latest dibatasi atau gagal
        try {
          const fallbackUrl = 'https://api.github.com/repos/$_repoOwner/$_repoName/releases?per_page=1';
          final fallbackResp = await _dio.get<List<dynamic>>(fallbackUrl);
          if (fallbackResp.statusCode == 200 &&
              fallbackResp.data != null &&
              fallbackResp.data!.isNotEmpty) {
            data = fallbackResp.data!.first as Map<String, dynamic>;
          }
        } catch (_) {}
      }

      if (data != null) {
        final tagName = data['tag_name']?.toString() ?? '';
        final releaseTitle = data['name']?.toString() ?? 'Pembaruan Aplikasi';
        final changelog = data['body']?.toString() ?? 'Peningkatan performa dan perbaikan bug.';
        final publishedStr = data['published_at']?.toString();
        DateTime? publishedAt;
        if (publishedStr != null) {
          publishedAt = DateTime.tryParse(publishedStr);
        }

        // Cari file APK paling optimal sesuai arsitektur CPU perangkat (Split-per-ABI)
        String apkUrl = '';
        int apkSize = 0;
        final assets = data['assets'] as List<dynamic>? ?? [];
        final deviceAbis = await _getDeviceSupportedAbis();
        final bestAsset = GitHubRelease.selectBestApkAsset(assets, deviceAbis);
        if (bestAsset != null) {
          apkUrl = bestAsset['browser_download_url']?.toString() ?? '';
          apkSize = (bestAsset['size'] as num?)?.toInt() ?? 0;
        }

        // Jika rilis baru dibuat namun APK belum selesai di-attach pada assets, gunakan direct download URL release
        if (apkUrl.isEmpty && tagName.isNotEmpty) {
          apkUrl = 'https://github.com/$_repoOwner/$_repoName/releases/download/$tagName/app-arm64-v8a-release.apk';
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
      } else {
        // 3. Fallback ketiga: parsing feed publik releases.atom (tanpa batasan rate-limit GitHub API)
        try {
          const atomUrl = 'https://github.com/$_repoOwner/$_repoName/releases.atom';
          final atomResp = await _dio.get<String>(
            atomUrl,
            options: Options(
              responseType: ResponseType.plain,
              headers: {'Accept': 'application/atom+xml, text/xml, */*'},
            ),
          );
          if (atomResp.statusCode == 200 && atomResp.data != null) {
            final content = atomResp.data!;
            final tagMatch = RegExp(r'/releases/tag/([^"]+)').firstMatch(content);
            if (tagMatch != null) {
              final tagName = tagMatch.group(1)?.trim() ?? '';
              final titleMatch = RegExp(r'<entry>[\s\S]*?<title>(.*?)</title>').firstMatch(content);
              final releaseTitle = titleMatch?.group(1)?.trim() ?? 'Pembaruan The PAMs $tagName';
              final hasUpdate = AppUpdateInfo.isNewerVersion(tagName, currentVersion);
              final apkUrl = 'https://github.com/$_repoOwner/$_repoName/releases/download/$tagName/app-arm64-v8a-release.apk';

              return AppUpdateInfo(
                currentVersion: currentVersion,
                latestVersion: tagName,
                releaseTitle: releaseTitle,
                changelog: 'Versi terbaru $tagName telah dirilis di GitHub. Ketuk untuk mengunduh dan memperbarui aplikasi.',
                apkDownloadUrl: apkUrl,
                apkSizeBytes: 0,
                publishedAt: DateTime.now(),
                hasUpdate: hasUpdate,
              );
            }
          }
        } catch (_) {}
      }
    } catch (_) {
      // Offline atau repository belum memiliki rilis
      return null;
    }
    return null;
  }

  /// Mengunduh APK pembaruan dengan fitur resumable (Range request),
  /// toleransi screen-off (auto-retry & reconnect), dan background notification.
  Future<OpenResult> downloadAndInstallApk({
    required String downloadUrl,
    required void Function(int received, int total) onProgress,
    void Function(String statusMessage)? onStatusChanged,
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
    final tempPath = '$savePath.part';

    final finalFile = File(savePath);
    final tempFile = File(tempPath);

    // Hapus file final lama jika ada agar tidak konflik
    if (await finalFile.exists()) {
      try {
        await finalFile.delete();
      } catch (_) {}
    }

    final notifService = NotificationService();
    const int maxRetries = 10;
    int retryCount = 0;
    bool isCompleted = false;
    int totalBytes = 0;

    // Timeout khusus pengunduhan berkas biner agar tahan saat layar ponsel mati / sleep
    final downloadDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(seconds: 45),
        headers: {
          'Accept': '*/*',
          'User-Agent': 'UNPAM-Mobile-App',
        },
      ),
    );

    while (!isCompleted && retryCount < maxRetries) {
      if (cancelToken?.isCancelled ?? false) {
        await notifService.cancelDownloadNotification();
        throw DioException(
          requestOptions: RequestOptions(path: downloadUrl),
          type: DioExceptionType.cancel,
          error: 'Pengunduhan dibatalkan oleh pengguna.',
        );
      }

      int existingBytes = 0;
      if (await tempFile.exists()) {
        existingBytes = await tempFile.length();
      }

      // Jika kita sudah mengetahui totalBytes dan existingBytes sudah genap sesuai ukuran, selesai
      if (totalBytes > 0 && existingBytes >= totalBytes) {
        isCompleted = true;
        break;
      }

      IOSink? sink;
      try {
        final Map<String, dynamic> headers = {'Accept': '*/*'};
        if (existingBytes > 0) {
          headers['Range'] = 'bytes=$existingBytes-';
        }

        final response = await downloadDio.get<ResponseBody>(
          downloadUrl,
          options: Options(
            responseType: ResponseType.stream,
            headers: headers,
          ),
          cancelToken: cancelToken,
        );

        final statusCode = response.statusCode ?? 200;
        final responseBody = response.data;
        if (responseBody == null) {
          throw const SocketException('Stream respon server kosong');
        }

        // Baca Content-Range atau Content-Length untuk mengetahui ukuran berkas total
        final contentRange = response.headers.value('content-range');
        if (contentRange != null && contentRange.contains('/')) {
          final totalStr = contentRange.split('/').last.trim();
          final parsed = int.tryParse(totalStr);
          if (parsed != null && parsed > 0) {
            totalBytes = parsed;
          }
        }
        if (totalBytes <= 0) {
          final lenStr = response.headers.value('content-length');
          if (lenStr != null) {
            final len = int.tryParse(lenStr) ?? 0;
            totalBytes = (statusCode == 206) ? (existingBytes + len) : len;
          }
        }

        int currentReceived = existingBytes;
        final activeSink = (statusCode == 206 && existingBytes > 0)
            ? tempFile.openWrite(mode: FileMode.append)
            : tempFile.openWrite(mode: FileMode.write);
        sink = activeSink;

        if (statusCode != 206 || existingBytes <= 0) {
          existingBytes = 0;
          currentReceived = 0;
        }

        onProgress(currentReceived, totalBytes > 0 ? totalBytes : currentReceived);
        if (totalBytes > 0) {
          notifService.updateDownloadProgress(
            receivedBytes: currentReceived,
            totalBytes: totalBytes,
          );
        }

        await for (final chunk in responseBody.stream) {
          if (cancelToken?.isCancelled ?? false) {
            await activeSink.flush();
            await activeSink.close();
            sink = null;
            await notifService.cancelDownloadNotification();
            throw DioException(
              requestOptions: RequestOptions(path: downloadUrl),
              type: DioExceptionType.cancel,
              error: 'Pengunduhan dibatalkan oleh pengguna.',
            );
          }

          activeSink.add(chunk);
          currentReceived += chunk.length;

          onProgress(currentReceived, totalBytes > 0 ? totalBytes : currentReceived);
          if (totalBytes > 0) {
            notifService.updateDownloadProgress(
              receivedBytes: currentReceived,
              totalBytes: totalBytes,
            );
          }
        }

        await activeSink.flush();
        await activeSink.close();
        sink = null;

        // Verifikasi integritas ukuran berkas setelah stream selesai
        final downloadedSize = await tempFile.length();
        if (totalBytes > 0 && downloadedSize < totalBytes) {
          throw SocketException('Unduhan belum lengkap ($downloadedSize dari $totalBytes bytes)');
        }

        isCompleted = true;
      } catch (e) {
        if (sink != null) {
          try {
            await sink.flush();
            await sink.close();
          } catch (_) {}
          sink = null;
        }

        if (cancelToken?.isCancelled ?? false) {
          await notifService.cancelDownloadNotification();
          rethrow;
        }

        retryCount++;
        if (retryCount >= maxRetries) {
          await notifService.cancelDownloadNotification();
          rethrow;
        }

        // Informasikan ke dialog bahwa koneksi sedang dipulihkan secara otomatis
        final percent = totalBytes > 0 && await tempFile.exists()
            ? ' (${((await tempFile.length() / totalBytes) * 100).toInt()}%)'
            : '';
        onStatusChanged?.call('Menyambung kembali unduhan$percent...');

        // Backoff bergradasi (1s, 2s, 3s...) sebelum mencoba menyambung kembali
        await Future.delayed(Duration(milliseconds: 1000 * retryCount.clamp(1, 4)));
      }
    }

    await notifService.cancelDownloadNotification();

    if (!isCompleted || !await tempFile.exists() || await tempFile.length() == 0) {
      return OpenResult(
        type: ResultType.fileNotFound,
        message: 'Gagal menyelesaikan pengunduhan berkas APK.',
      );
    }

    // Pindahkan dari file sementara (.part) ke file target (.apk)
    await tempFile.rename(savePath);

    final finalDownloadedFile = File(savePath);
    if (!await finalDownloadedFile.exists() || await finalDownloadedFile.length() == 0) {
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

  Future<List<String>> _getDeviceSupportedAbis() async {
    if (Platform.isAndroid) {
      try {
        final info = await DeviceInfoPlugin().androidInfo;
        return info.supportedAbis;
      } catch (_) {}
    }
    return const [];
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
        final deviceAbis = await _getDeviceSupportedAbis();
        final List<GitHubRelease> releases = [];
        for (final item in response.data!) {
          if (item is Map<String, dynamic>) {
            final release = GitHubRelease.fromJson(item, supportedAbis: deviceAbis);
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
        final deviceAbis = await _getDeviceSupportedAbis();
        final List<dynamic> list = jsonDecode(cached) as List<dynamic>;
        return list.map((e) => GitHubRelease.fromJson(e as Map<String, dynamic>, supportedAbis: deviceAbis)).toList();
      } catch (_) {}
    }

    return [];
  }
}
