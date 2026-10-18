import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'file_download_service.dart';

/// Representasi transaksi aktif pengunduhan berkas via browser Chromium
class _ActiveDownload {
  final String id;
  final String targetUrl;
  final String? customName;
  final File tempFile;
  final IOSink sink;
  final Completer<FileDownloadResult> completer;
  final void Function(double progress)? onProgress;
  String? detectedContentDisposition;
  String? detectedContentType;
  int receivedBytes = 0;
  Timer? timeoutTimer;

  _ActiveDownload({
    required this.id,
    required this.targetUrl,
    required this.tempFile,
    required this.sink,
    required this.completer,
    this.customName,
    this.onProgress,
  });
}

/// Jembatan pengunduhan berkas akademik (KRS, KHS, Modul LMS, Kartu Ujian)
/// yang berjalan langsung di dalam Chromium WebView.
///
/// Hal ini memotong blokir Cloudflare Turnstile & TLS fingerprinting karena
/// request dieksekusi dengan TLS engine, IP, dan cookies sesi asli WebView.
class WebViewDownloadBridge {
  static final WebViewDownloadBridge _instance = WebViewDownloadBridge._internal();
  factory WebViewDownloadBridge() => _instance;
  WebViewDownloadBridge._internal();

  /// Nama channel JavaScript untuk menerima pecahan biner (chunk) dari halaman web
  static const String channelName = 'CampusDownloadPayloadChannel';

  final Map<String, _ActiveDownload> _activeDownloads = <String, _ActiveDownload>{};

  /// Mengunduh berkas melalui konteks peramban WebView yang aktif
  Future<FileDownloadResult> downloadFile({
    required WebViewController controller,
    required String url,
    String? customName,
    void Function(double progress)? onProgress,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      return FileDownloadResult.failure('URL unduhan kosong.');
    }

    // Tangani Data URI langsung tanpa injeksi peramban
    if (trimmedUrl.startsWith('data:')) {
      return FileDownloadService().saveAndOpenBase64DataUri(trimmedUrl, customName);
    }

    final downloadId = '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';
    File? tempFile;
    IOSink? sink;

    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = p.join(tempDir.path, 'thepams_dl_$downloadId.tmp');
      tempFile = File(tempPath);
      sink = tempFile.openWrite();

      final completer = Completer<FileDownloadResult>();
      final activeDownload = _ActiveDownload(
        id: downloadId,
        targetUrl: trimmedUrl,
        tempFile: tempFile,
        sink: sink,
        completer: completer,
        customName: customName,
        onProgress: onProgress,
      );

      activeDownload.timeoutTimer = Timer(timeout, () {
        _abortDownload(
          downloadId,
          'Waktu unduh peramban habis (timeout). Silakan periksa koneksi atau coba opsi unduh lain.',
        );
      });

      _activeDownloads[downloadId] = activeDownload;

      // Injeksi skrip fetch in-browser dengan credentials include
      final safeId = jsonEncode(downloadId);
      final safeUrl = jsonEncode(trimmedUrl);

      final jsScript = '''
(async function() {
  var dId = $safeId;
  var targetUrl = $safeUrl;
  try {
    var blob = null;
    var disp = '';
    var ctype = '';

    if (targetUrl.indexOf('blob:') === 0) {
      // 1. Penanganan khusus skema blob:
      // Sesuai W3C Fetch spec, URL blob: DILARANG menggunakan credentials: 'include' atau headers kustom.
      try {
        var blobResp = await fetch(targetUrl);
        if (blobResp.ok) {
          blob = await blobResp.blob();
        }
      } catch (fErr) {}

      if (!blob) {
        blob = await new Promise(function(resolve, reject) {
          var xhr = new XMLHttpRequest();
          xhr.open('GET', targetUrl, true);
          xhr.responseType = 'blob';
          xhr.onload = function() {
            if (xhr.status === 200 || xhr.status === 0) {
              resolve(xhr.response);
            } else {
              reject(new Error('Gagal mengambil blob: HTTP ' + xhr.status));
            }
          };
          xhr.onerror = function() {
            reject(new Error('Gagal membaca data memori blob peramban.'));
          };
          xhr.send();
        });
      }

      ctype = (blob && blob.type) ? blob.type : 'application/pdf';
    } else {
      // 2. Penanganan URL jaringan http/https (Bypass Cloudflare via in-WebView fetch)
      var resp = await fetch(targetUrl, {
        method: 'GET',
        credentials: 'include',
        headers: {
          'Accept': 'application/pdf,application/octet-stream,text/html,*/*'
        }
      });

      if (!resp.ok) {
        if (window.$channelName) {
          window.$channelName.postMessage(JSON.stringify({
            id: dId,
            type: 'error',
            message: 'HTTP ' + resp.status + ' ' + (resp.statusText || '')
          }));
        }
        return;
      }

      disp = resp.headers.get('content-disposition') || '';
      ctype = resp.headers.get('content-type') || '';
      blob = await resp.blob();
    }

    var totalSize = blob ? blob.size : 0;

    if (!blob || totalSize === 0) {
      if (window.$channelName) {
        window.$channelName.postMessage(JSON.stringify({
          id: dId,
          type: 'error',
          message: 'Berkas unduhan kosong (0 bytes).'
        }));
      }
      return;
    }

    var chunkSize = 256 * 1024; // Potongan 256 KB per payload untuk efisiensi IPC
    var totalChunks = Math.ceil(totalSize / chunkSize);

    for (var i = 0; i < totalChunks; i++) {
      var start = i * chunkSize;
      var end = Math.min(start + chunkSize, totalSize);
      var slice = blob.slice(start, end);

      var base64Chunk = await new Promise(function(resolve, reject) {
        var reader = new FileReader();
        reader.onloadend = function() {
          var res = reader.result || '';
          var commaIdx = res.indexOf(',');
          resolve(commaIdx !== -1 ? res.substring(commaIdx + 1) : res);
        };
        reader.onerror = reject;
        reader.readAsDataURL(slice);
      });

      if (window.$channelName) {
        window.$channelName.postMessage(JSON.stringify({
          id: dId,
          type: 'chunk',
          index: i,
          total: totalChunks,
          chunk: base64Chunk,
          disp: disp,
          ctype: ctype,
          size: totalSize
        }));
      }
    }

    if (window.$channelName) {
      window.$channelName.postMessage(JSON.stringify({
        id: dId,
        type: 'done',
        disp: disp,
        ctype: ctype,
        size: totalSize
      }));
    }
  } catch (err) {
    if (window.$channelName) {
      window.$channelName.postMessage(JSON.stringify({
        id: dId,
        type: 'error',
        message: '' + err
      }));
    }
  }
})();
''';

      await controller.runJavaScript(jsScript);
      return await completer.future;
    } catch (e) {
      await _cleanupTransfer(downloadId);
      return FileDownloadResult.failure('Gagal memulai unduhan via peramban: $e');
    }
  }

  /// Menangani pesan payload pecahan biner dari JavaScript channel
  Future<void> handlePayloadMessage(String rawMessage) async {
    try {
      final dynamic decoded = jsonDecode(rawMessage);
      if (decoded is! Map<String, dynamic>) return;

      final id = decoded['id'] as String?;
      final type = decoded['type'] as String?;
      if (id == null || type == null) return;

      final download = _activeDownloads[id];
      if (download == null) return;

      if (type == 'chunk') {
        final chunk = decoded['chunk'] as String? ?? '';
        if (chunk.isNotEmpty) {
          final bytes = base64Decode(chunk);
          download.sink.add(bytes);
          download.receivedBytes += bytes.length;
        }

        final disp = decoded['disp'] as String?;
        if (disp != null && disp.isNotEmpty) {
          download.detectedContentDisposition = disp;
        }
        final ctype = decoded['ctype'] as String?;
        if (ctype != null && ctype.isNotEmpty) {
          download.detectedContentType = ctype;
        }

        final total = decoded['total'] as int? ?? 1;
        final index = decoded['index'] as int? ?? 0;
        final progress = ((index + 1) / total).clamp(0.0, 1.0);
        download.onProgress?.call(progress);
      } else if (type == 'done') {
        download.timeoutTimer?.cancel();
        _activeDownloads.remove(id);

        await download.sink.flush();
        await download.sink.close();

        final tempFile = download.tempFile;
        if (!await tempFile.exists() || await tempFile.length() == 0) {
          download.completer.complete(
            FileDownloadResult.failure('Berkas hasil unduhan kosong.'),
          );
          await _safeDeleteFile(tempFile);
          return;
        }

        // Cek apakah konten merupakan halaman login HTML atau sesi kedaluwarsa
        final bytesSample = await _readFirstBytes(tempFile, 1024);
        final isPdfMagic = bytesSample.length >= 4 &&
            bytesSample[0] == 0x25 && // %
            bytesSample[1] == 0x50 && // P
            bytesSample[2] == 0x44 && // D
            bytesSample[3] == 0x46;   // F

        final ctype = download.detectedContentType ?? '';
        if (ctype.contains('text/html') && !isPdfMagic) {
          final htmlSample = utf8.decode(bytesSample, allowMalformed: true).toLowerCase();
          if (htmlSample.contains('login') || htmlSample.contains('masuk')) {
            download.completer.complete(
              FileDownloadResult.failure(
                'Sesi masuk telah berakhir. Silakan login ulang ke portal sebelum mengunduh berkas.',
              ),
            );
            await _safeDeleteFile(tempFile);
            return;
          }
        }

        final fileName = FileDownloadService().resolveFileName(
          url: download.targetUrl,
          contentDisposition: download.detectedContentDisposition ?? (decoded['disp'] as String?),
          contentType: ctype.isNotEmpty ? ctype : (decoded['ctype'] as String?),
          isPdf: isPdfMagic,
          customName: download.customName,
        );

        final savedFile = await FileDownloadService().persistFileToStorage(
          tempFile,
          fileName,
        );

        await _safeDeleteFile(tempFile);
        await OpenFilex.open(savedFile.path);

        download.completer.complete(
          FileDownloadResult.success(
            filePath: savedFile.path,
            fileName: fileName,
          ),
        );
      } else if (type == 'error') {
        final message = decoded['message'] as String? ?? 'Kesalahan tidak diketahui pada peramban.';
        _abortDownload(id, message);
      }
    } catch (e) {
      debugPrint('Error handling download payload: $e');
    }
  }

  void _abortDownload(String id, String message) {
    final download = _activeDownloads.remove(id);
    if (download != null) {
      download.timeoutTimer?.cancel();
      download.sink.close().catchError((dynamic _) {});
      _safeDeleteFile(download.tempFile);
      if (!download.completer.isCompleted) {
        download.completer.complete(FileDownloadResult.failure(message));
      }
    }
  }

  Future<void> _cleanupTransfer(String id) async {
    final download = _activeDownloads.remove(id);
    if (download != null) {
      download.timeoutTimer?.cancel();
      try {
        await download.sink.close();
      } catch (_) {}
      await _safeDeleteFile(download.tempFile);
    }
  }

  Future<List<int>> _readFirstBytes(File file, int maxBytes) async {
    try {
      final stream = file.openRead(0, maxBytes);
      final List<int> bytes = <int>[];
      await for (final chunk in stream) {
        bytes.addAll(chunk);
        if (bytes.length >= maxBytes) break;
      }
      return bytes;
    } catch (_) {
      return <int>[];
    }
  }

  Future<void> _safeDeleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
