import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FileDownloadResult {
  final bool isSuccess;
  final String? filePath;
  final String? fileName;
  final String? errorMessage;

  const FileDownloadResult({
    required this.isSuccess,
    this.filePath,
    this.fileName,
    this.errorMessage,
  });

  factory FileDownloadResult.success({
    required String filePath,
    required String fileName,
  }) {
    return FileDownloadResult(
      isSuccess: true,
      filePath: filePath,
      fileName: fileName,
    );
  }

  factory FileDownloadResult.failure(String message) {
    return FileDownloadResult(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class FileDownloadService {
  static final FileDownloadService _instance = FileDownloadService._internal();
  factory FileDownloadService() => _instance;
  FileDownloadService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      followRedirects: true,
      maxRedirects: 10,
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  /// Memeriksa apakah URL kemungkinan besar merupakan berkas dokumen/cetak akademik
  static bool isDocumentUrl(String rawUrl) {
    if (rawUrl.isEmpty) return false;
    final lower = rawUrl.toLowerCase().trim();

    // Data URI berkas PDF
    if (lower.startsWith('data:application/pdf') || lower.startsWith('data:application/octet-stream')) {
      return true;
    }

    // Ekstensi berkas umum perkuliahan
    if (lower.endsWith('.pdf') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.doc') ||
        lower.endsWith('.xlsx') ||
        lower.endsWith('.xls') ||
        lower.endsWith('.pptx') ||
        lower.endsWith('.ppt') ||
        lower.endsWith('.zip') ||
        lower.endsWith('.rar')) {
      return true;
    }

    // Pola unduhan sistem Mentari LMS (Moodle) & MyUnpam
    if (lower.contains('pluginfile.php') ||
        lower.contains('/mod/resource/view.php') ||
        lower.contains('forcedownload=1') ||
        lower.contains('export=pdf') ||
        lower.contains('format=pdf') ||
        lower.contains('type=pdf') ||
        lower.contains('download=pdf') ||
        lower.contains('cetak=pdf')) {
      return true;
    }

    // Pola cetak SIAKAD MyUnpam
    if (lower.contains('cetak_krs') ||
        lower.contains('cetak_khs') ||
        lower.contains('cetak_transkrip') ||
        lower.contains('cetak_kartu') ||
        lower.contains('cetak_tagihan') ||
        lower.contains('cetak_kwitansi') ||
        lower.contains('krs_cetak') ||
        lower.contains('khs_cetak') ||
        lower.contains('kartu_ujian') ||
        lower.contains('/krs/cetak') ||
        lower.contains('/khs/cetak') ||
        lower.contains('/transkrip/cetak') ||
        lower.contains('/download/')) {
      return true;
    }

    return false;
  }

  /// Mengambil semua cookies yang valid untuk domain URL dari WebViewCookieManager
  Future<String> getSessionCookiesForUrl(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) return '';

      final cookieManager = WebViewCookieManager();
      final cookies = await cookieManager.getCookies(domain: uri);
      if (cookies.isEmpty) return '';

      return cookies.map((c) => '${c.name}=${c.value}').join('; ');
    } catch (e) {
      debugPrint('Error reading session cookies for URL: $e');
      return '';
    }
  }

  /// Mengunduh dan langsung membuka berkas dokumen (PDF, Cetak KRS/KHS, dsb.)
  Future<FileDownloadResult> downloadAndOpenFile({
    required String url,
    String? customFileName,
    String? explicitCookies,
    String? userAgent,
    String? referer,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // 1. Penanganan Data URI (Base64)
      if (url.startsWith('data:')) {
        return await _saveAndOpenBase64DataUri(url, customFileName);
      }

      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) {
        return FileDownloadResult.failure('URL unduhan tidak valid.');
      }

      // 2. Kumpulkan cookies sesi aktif agar portal kampus tidak redirect ke login
      String cookies = explicitCookies ?? '';
      if (cookies.isEmpty) {
        cookies = await getSessionCookiesForUrl(url);
      }

      final headers = <String, dynamic>{
        'Accept': 'application/pdf,application/octet-stream,text/html,*/*',
      };

      if (cookies.isNotEmpty) {
        headers['Cookie'] = cookies;
      }
      if (userAgent != null && userAgent.isNotEmpty) {
        headers['User-Agent'] = userAgent;
      }
      if (referer != null && referer.isNotEmpty) {
        headers['Referer'] = referer;
      }

      // 3. Unduh berkas melalui Dio dengan buffer bytes
      final response = await _dio.get<List<int>>(
        url,
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes,
        ),
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            final progress = (received / total).clamp(0.0, 1.0);
            onProgress(progress);
          }
        },
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        return FileDownloadResult.failure('Gagal mengunduh: Berkas yang diterima kosong.');
      }

      // 4. Verifikasi apakah respon dialihkan ke laman login HTML
      final contentType = response.headers.value('content-type') ?? '';
      final isPdfMagic = bytes.length >= 4 &&
          bytes[0] == 0x25 && // %
          bytes[1] == 0x50 && // P
          bytes[2] == 0x44 && // D
          bytes[3] == 0x46;   // F

      if (contentType.contains('text/html') && !isPdfMagic) {
        final htmlSample = utf8.decode(bytes.take(1024).toList(), allowMalformed: true).toLowerCase();
        if (htmlSample.contains('login') || htmlSample.contains('masuk')) {
          return FileDownloadResult.failure(
            'Sesi masuk telah berakhir. Silakan login ulang ke portal sebelum mengunduh berkas.',
          );
        }
      }

      // 5. Tentukan nama berkas yang bersih dan bermakna
      final fileName = _resolveFileName(
        url: url,
        contentDisposition: response.headers.value('content-disposition'),
        contentType: contentType,
        isPdf: isPdfMagic,
        customName: customFileName,
      );

      // 6. Simpan berkas ke direktori penyimpanan lokal aplikasi
      final savedFile = await _persistBytesToFile(bytes, fileName);

      // 7. Buka berkas dengan penampil dokumen bawaan sistem HP (PDF Viewer / WPS / Drive)
      final openResult = await OpenFilex.open(savedFile.path);

      if (openResult.type == ResultType.noAppToOpen) {
        return FileDownloadResult.success(
          filePath: savedFile.path,
          fileName: fileName,
        );
      }

      return FileDownloadResult.success(
        filePath: savedFile.path,
        fileName: fileName,
      );
    } catch (e) {
      debugPrint('File download error: $e');
      return FileDownloadResult.failure('Terjadi kesalahan saat mengunduh berkas: $e');
    }
  }

  /// Menangani berkas base64 (data:application/pdf;base64,...)
  Future<FileDownloadResult> _saveAndOpenBase64DataUri(String dataUri, String? customName) async {
    try {
      final commaIndex = dataUri.indexOf(',');
      if (commaIndex == -1) {
        return FileDownloadResult.failure('Format Data URI tidak valid.');
      }

      final meta = dataUri.substring(0, commaIndex);
      final rawBase64 = dataUri.substring(commaIndex + 1);
      final bytes = base64Decode(rawBase64.replaceAll(RegExp(r'\s+'), ''));

      final isPdf = meta.contains('pdf') ||
          (bytes.length >= 4 &&
              bytes[0] == 0x25 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x44 &&
              bytes[3] == 0x46);

      final ext = isPdf ? '.pdf' : '.bin';
      final base = customName?.trim().isNotEmpty == true
          ? customName!.trim()
          : 'Dokumen_UNPAM_${DateTime.now().millisecondsSinceEpoch}';
      final fileName = base.endsWith(ext) ? base : '$base$ext';

      final savedFile = await _persistBytesToFile(bytes, fileName);
      await OpenFilex.open(savedFile.path);

      return FileDownloadResult.success(
        filePath: savedFile.path,
        fileName: fileName,
      );
    } catch (e) {
      return FileDownloadResult.failure('Gagal memproses data berkas: $e');
    }
  }

  /// Mengekstrak atau menyusun nama berkas dokumen yang ramah pengguna
  String _resolveFileName({
    required String url,
    String? contentDisposition,
    String? contentType,
    required bool isPdf,
    String? customName,
  }) {
    if (customName != null && customName.trim().isNotEmpty) {
      final clean = _sanitizeFileName(customName.trim());
      if (clean.isNotEmpty) {
        return isPdf && !clean.toLowerCase().endsWith('.pdf') ? '$clean.pdf' : clean;
      }
    }

    // 1. Ekstrak dari Content-Disposition header
    if (contentDisposition != null && contentDisposition.isNotEmpty) {
      final utf8Match = RegExp(r"filename\*=UTF-8''([^;\r\n]+)", caseSensitive: false)
          .firstMatch(contentDisposition);
      if (utf8Match != null) {
        final decoded = Uri.decodeComponent(utf8Match.group(1) ?? '');
        final clean = _sanitizeFileName(decoded);
        if (clean.isNotEmpty) return clean;
      }

      final normalMatch = RegExp(r'filename="?([^";\r\n]+)"?', caseSensitive: false)
          .firstMatch(contentDisposition);
      if (normalMatch != null) {
        final clean = _sanitizeFileName(normalMatch.group(1) ?? '');
        if (clean.isNotEmpty) return clean;
      }
    }

    // 2. Ekstrak dari path URL
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final last = pathSegments.last;
        if (last.contains('.') && !last.endsWith('.php') && !last.endsWith('.html')) {
          final clean = _sanitizeFileName(last);
          if (clean.isNotEmpty) return clean;
        }
      }
    } catch (_) {}

    // 3. Nama kontekstual berdasarkan kata kunci pada URL
    final lower = url.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    String prefix = 'Dokumen_UNPAM';

    if (lower.contains('krs')) {
      prefix = 'Cetak_KRS_UNPAM';
    } else if (lower.contains('khs')) {
      prefix = 'Cetak_KHS_UNPAM';
    } else if (lower.contains('transkrip')) {
      prefix = 'Transkrip_Nilai_UNPAM';
    } else if (lower.contains('kartu')) {
      prefix = 'Kartu_Ujian_UNPAM';
    } else if (lower.contains('kwitansi') || lower.contains('tagihan')) {
      prefix = 'Kwitansi_Pembayaran_UNPAM';
    } else if (lower.contains('modul') || lower.contains('resource')) {
      prefix = 'Modul_Kuliah_UNPAM';
    }

    final ext = isPdf || contentType?.contains('pdf') == true ? '.pdf' : '.bin';
    return '${prefix}_$timestamp$ext';
  }

  /// Membersihkan karakter berbahaya pada nama berkas
  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  /// Menyimpan byte ke direktori dokumen lokal perangkat
  Future<File> _persistBytesToFile(List<int> bytes, String fileName) async {
    Directory targetDir;
    try {
      // Prioritaskan direktori Download eksternal jika tersedia di Android
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final downloadSubDir = Directory(p.join(extDir.path, 'Downloads'));
        if (!await downloadSubDir.exists()) {
          await downloadSubDir.create(recursive: true);
        }
        targetDir = downloadSubDir;
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }
    } catch (_) {
      targetDir = await getApplicationDocumentsDirectory();
    }

    final filePath = p.join(targetDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
