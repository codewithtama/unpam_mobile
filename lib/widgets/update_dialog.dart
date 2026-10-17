import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_update_info.dart';
import '../core/services/update_checker_service.dart';
import '../theme/app_theme.dart';

class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;
  final UpdateCheckerService updateService;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.updateService,
  });

  static Future<void> show({
    required BuildContext context,
    required AppUpdateInfo updateInfo,
    required UpdateCheckerService updateService,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => UpdateDialog(
        updateInfo: updateInfo,
        updateService: updateService,
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;
  bool _downloadFinished = false;
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel('Dialog dismissed');
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _progress = 0.0;
      _cancelToken = CancelToken();
    });

    try {
      final res = await widget.updateService.downloadAndInstallApk(
        downloadUrl: widget.updateInfo.apkDownloadUrl,
        cancelToken: _cancelToken,
        onProgress: (received, total) {
          if (mounted && total > 0) {
            setState(() {
              _receivedBytes = received;
              _totalBytes = total;
              _progress = (received / total).clamp(0.0, 1.0);
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadFinished = true;
        });

        if (res.type != ResultType.done) {
          // Jika sistem Android memblokir installer otomatis
          setState(() {
            _errorMessage =
                'Gagal membuka installer otomatis (${res.message}). Anda dapat mengunduh APK secara langsung melalui browser.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Pengunduhan gagal: $e';
        });
      }
    }
  }

  Future<void> _openDownloadInBrowser() async {
    final uri = Uri.parse(widget.updateInfo.apkDownloadUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching browser update URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.updateInfo;
    String? dateStr;
    if (info.publishedAt != null) {
      try {
        dateStr = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(info.publishedAt!);
      } catch (_) {
        dateStr = DateFormat('dd MMM yyyy, HH:mm').format(info.publishedAt!);
      }
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.06),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(bottom: BorderSide(color: AppTheme.cardBorder.withOpacity(0.5))),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.system_update_rounded, color: AppTheme.accentGold, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pembaruan Tersedia!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'v${info.currentVersion}  ➔  ${info.latestVersion}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    info.releaseTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                if (info.formattedApkSize.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Text(
                      info.formattedApkSize,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    ),
                  ),
              ],
            ),
            if (dateStr != null) ...[
              const SizedBox(height: 2),
              Text(
                'Dirilis pada $dateStr WIB',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Apa yang baru di versi ini:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: SingleChildScrollView(
                child: Text(
                  info.changelog.trim().isNotEmpty
                      ? info.changelog.trim()
                      : 'Peningkatan stabilitas dan perbaikan bug.',
                  style: const TextStyle(fontSize: 12, height: 1.45, color: AppTheme.textDark),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textMuted.withOpacity(0.85)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tips: Jika muncul pesan "paket tidak valid", hapus (uninstall) versi lama di HP terlebih dahulu.',
                    style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted.withOpacity(0.85)),
                  ),
                ),
              ],
            ),

            if (_isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                backgroundColor: Colors.grey.shade200,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(_progress * 100).toInt()}% Mengunduh...',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                  ),
                  if (_totalBytes > 0)
                    Text(
                      '${(_receivedBytes / (1024 * 1024)).toStringAsFixed(1)} / ${(_totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                ],
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.dangerRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 16, color: AppTheme.dangerRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.dangerRed),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        if (!_isDownloading) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti Saja', style: TextStyle(color: AppTheme.textMuted)),
          ),
          if (_errorMessage != null)
            TextButton.icon(
              onPressed: _openDownloadInBrowser,
              icon: const Icon(Icons.open_in_browser_rounded, size: 16),
              label: const Text('Buka Browser'),
            ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: _downloadFinished ? _startDownload : _startDownload,
            icon: Icon(
              _downloadFinished ? Icons.install_mobile_rounded : Icons.download_rounded,
              size: 16,
            ),
            label: Text(
              _downloadFinished ? 'Pasang Ulang' : 'Perbarui Sekarang',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ] else ...[
          TextButton(
            onPressed: () {
              _cancelToken?.cancel('Dibatalkan pengguna');
              setState(() => _isDownloading = false);
            },
            child: const Text('Batalkan', style: TextStyle(color: AppTheme.dangerRed)),
          ),
        ],
      ],
    );
  }
}
